//
//  SPRawGeometricsFinder.swift
//  Sharpener
//
//  Created by Inti Guo on 1/14/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import CoreGraphics
import MetalKit

@objc protocol SPRawGeometricsFinderDelegate {
    
    /// Called at the end of process()
    func succefullyExtractedGeometrics()
}

/// SPRawGeometricsFinder is used to descriminate shapes and lines from given UIImage.
/// >  It will firstly apply abunch of filter to filter out shape and lines, then seperate them into different groups, refine them (extracting lines from shape, ignoring small shapes in lines, etc.), and create a final seperation for texture, so user can choose to hide or show individual shape or line group in Refine View.
class SPRawGeometricsFinder {
    
    // MARK: Properties
    private let context: MXNContext = MXNContext()
    private var geometricsFilteringFilter: GeometricsFilteringFilter!
    weak var delegate: SPRawGeometricsFinderDelegate?
    var texture: MTLTexture { return geometricsFilteringFilter.texture }
    
    /// Used to store rawGeometric extracted from texture, for shape seperation use.
    var rawGeometrics = [SPRawGeometric]()
    /// Used to store rawGeometric extracted from previous extracted rawGeometrics.
    var extractedRawGeometrics = [SPRawGeometric]()
    var textureData: MXNTextureData!
    
    // MARK: Initializing
    
    init(medianFilterRadius: Int,
        thresholdingFilterThreshold: Float,
        lineShapeFilteringFilterAttributes: (threshold: Float, radius: Int),
        extractorSize: CGSize) {
            
        geometricsFilteringFilter = GeometricsFilteringFilter(context: context,
            medianFilterRadius: medianFilterRadius,
            thresholdingFilterThreshold: thresholdingFilterThreshold,
            lineShapeFilteringFilterAttributes: (lineShapeFilteringFilterAttributes.threshold, lineShapeFilteringFilterAttributes.radius))
    }
    
    // MARK: Progress
    
    /// Process and given UIImage, when done, it will tell delegate.
    /// - todo: Use NSOperation to make it cancelable.
    func process(image: UIImage) {
        geometricsFilteringFilter.provider = MXNImageProvider(image: image, context: context)
        dispatch_async(GCD.newSerialQueue("rawgeometrics_finding")) {
            
            self.extractTexture()
            self.extractSeperatedTexture()
            self.extractGeometrics()
            self.simpleVectorization()
            
            dispatch_async(GCD.mainQueue) {
                self.delegate?.succefullyExtractedGeometrics()
            }
        }
    }
    
    /// Used to extract texture from UIImage, runs in Queue_rawgeometrics_finding.
    private func extractTexture() {
        self.geometricsFilteringFilter.applyFilter()
        textureData = MXNTextureData(texture: texture)
    }
    
    /// Used to create a first version of rawGeometrics to seperate them into different parts. Called in extractTextureFrom(). Runs in Queue_rawgeometrics_finding.
    private func extractSeperatedTexture() {
        var tempTextureData: MXNTextureData = textureData
        for i in 0..<tempTextureData.width {
            for j in 0..<tempTextureData.height {
                guard tempTextureData[(i,j)]!.isNotWhiteAndBlack else { continue }
                var points = [CGPoint]()
                flood(i, j, from: &tempTextureData, into: &points) { point in point.isNotWhiteAndBlack }
                let rawG = SPRawGeometric(raw: points)
                rawGeometrics.append(rawG)
            }
        }
    }
    
    /// Used to refine seperations. Called in extractSeperatedTexture(). Runs in Queue_rawgeometrics_finding.
    private func extractGeometrics() {
        var tempTextureData: MXNTextureData = textureData
        defer { textureData = tempTextureData }
        
        for var g in rawGeometrics {
            
            // calculate size
            for point in g.raw {
                guard let c = textureData[point] else { continue }
                switch c {
                case let c where c.isInLine: // red for lines
                    g.lineSize += 1
                case let c where c.isInShape || c.isInShapeBorder: // for shape
                    g.shapeSize += 1
                default: break
                }
            }
            
            if Double(g.shapeWeight) >= 0.05 { // probably, it's a shape, but may have some lines in it
                g.type = .Shape
                
                // clean tiny red parts
                // extract big red parts to another rawGeometics
                // turn blue parts into green
                var lines = [CGPoint]()
                for point in g.raw {
                    if let c = tempTextureData[point] where c.isInLine && !c.isTransparent {
                        var linePoints = [CGPoint]()
                        flood(point, from: &tempTextureData, into: &linePoints) { $0.isNotWhiteAndBlack && $0.isInLine }
                        if Double(linePoints.count) / Double(g.shapeSize) <= 0.05 {
                            for p in linePoints {
                                tempTextureData.toShapeAt(p)
                            }
                        } else {
                            lines += linePoints
                            for p in linePoints {
                                if let index = g.raw.indexOf(p) {
                                    g.raw.removeAtIndex(index)
                                }
                            }
                        }
                    } else if let c = tempTextureData[point] where c.isInShapeBorder {
                        tempTextureData.toShapeAt(point)
                    }
                }
                
                if lines.count > 0 { extractedRawGeometrics.append(SPRawGeometric(raw: lines)) }
                
            } else {
                g.type = .Line
                
                // clean all green and blue parts
                for point in g.raw {
                    if let c = tempTextureData[point] where c.isInShape || c.isInShapeBorder {
                        tempTextureData.toLineAt(point)
                    }
                }
            }
        }
    }
    
    /// Used to create simple vector borders for each SPRawGeometrics to display.
    private func simpleVectorization() {
        rawGeometrics += extractedRawGeometrics // put them together
        var newGeometrics = [SPRawGeometric]()
        defer { rawGeometrics = newGeometrics }
        
        for raw in rawGeometrics {
            fetchContoursOfRawGeometric(raw)
        }
    }
    
    // MARK: Utility Methods
    
    /// Used to find a shape based on a seed point, line-scanning version. 
    /// > It calls a generic version of flood().
    private func flood(point: CGPoint, inout from textureData: MXNTextureData, inout into points: [CGPoint], which checkIfShouldFlood: (MXNTextureData.RGBAPixel) -> Bool) {
        flood(Int(point.x), Int(point.y), from: &textureData, into: &points, match: checkIfShouldFlood)
    }
    
    /// Used to find a shape based on a seed point, line-scanning version.
    /// 1. Starts from a seed point, it scans all points on left/right sides until reaches borders. 
    /// 2. Then checks for upper/lower lines if there exists some points that need to be fill.
    /// 3. Mark the left most point of each areas found above, and do the same things on them(go to 1).
    /// 4. End when no more such points found.
    /// - Parameter x: x-position of seed point
    /// - Parameter y: y-position of seed point
    /// - Parameter from: the textureData that needs process
    /// - Parameter into:
    /// - Parameter match: points' pattern that should be flooded
    private func flood(x: Int, _ y: Int, inout from textureData: MXNTextureData, inout into points: [CGPoint], match checkIfShouldFlood: (MXNTextureData.RGBAPixel) -> Bool) {
        guard let c = textureData[(x,y)] else { return }
        guard checkIfShouldFlood(c) && !c.isTransparent else { return }
        
        var stack = Stack(storage: [CGPoint]())
        let seed = CGPoint(x: x, y: y)
        stack.push(seed)
        
        while !stack.isEmpty {
            guard let currentSeed = stack.pop() else { continue }
            let pos = currentSeed
            points.append(pos)
            textureData.cleanAt(pos)
            
            // fill right
            var rightPos = pos
            while let c = textureData[rightPos.right] where checkIfShouldFlood(c) {
                if !c.isTransparent { // if it's not yet added to points
                    points.append(rightPos.right)
                    textureData.cleanAt(rightPos.right)
                }
                rightPos.move(.Right)
            }
            
            // fill left
            var leftPos = pos
            while let c = textureData[leftPos.left] where checkIfShouldFlood(c) {
                if !c.isTransparent { // if it's not yet added to points
                    points.append(leftPos.left)
                    textureData.cleanAt(leftPos.left)
                }
                leftPos.move(.Left)
            }
            
            // check upper and lower line for not captured lines.
            var topFound = false, bottomFound = false
            for x in CGPoint.horizontalRangeFrom(leftPos, to: rightPos) {
                guard !topFound || !bottomFound else { break }
                let thisPos = CGPoint(x: x, y: Int(rightPos.y))
                
                // check upper line, push leftmost point of each area found into stack
                if let c = textureData[thisPos.up] where checkIfShouldFlood(c) && !c.isTransparent && !topFound {
                    stack.push(thisPos.up)
                    topFound = true
                } else if let c = textureData[thisPos.up] where !checkIfShouldFlood(c) && topFound {
                    // when such pixels found, reset topFound to let it check for next area
                    topFound = false
                }
                
                // check lower line
                if let c = textureData[thisPos.down] where checkIfShouldFlood(c) && !c.isTransparent && !bottomFound {
                    stack.push(thisPos.down)
                    bottomFound = true
                } else if let c = textureData[thisPos.down] where !checkIfShouldFlood(c) && bottomFound {
                    bottomFound = false
                }
            }
        }
    }
    
    private func fetchContoursOfRawGeometric(raw: SPRawGeometric) {
        let cvlines = CVWrapper.findContoursFromImage(raw.imageInTextureData(textureData))
        for cvline in cvlines as! SPCVLine {
            var line = SPLine()
            for rawPointValue in cvline.raw as NSValue {
                let p = rawPointValue.CGPointValue()
                SPLine<--p
            }
            for appPointValue in cvline.approx as NSValue {
                let p = appPointValue.CGPointValue()
                let vp = SPAnchorPoint(point: p)
                SPLine<--vp
            }
        }
    }
    
    /*
    /// Find borders from given CGPoints, here, it return SPLines with all points of borders and simplified(polygon approximation) vector paths.
    private func findBordersFrom(points: [CGPoint]) -> [SPLine] {
        let lines = [SPLine]()
        
        let borderPoints = points.filter { point in
            textureData.isBorderAtPoint(point)
        }
        
        for point in borderPoints {
            let line = SPLine()
            let l = trackLineStartFrom(point, searchingIn: &borderPoints)
            line.raw = l
            line = polygonApproximateThenVectorize(line)
        }
        
        return lines
    }
    
    private func trackLineStartFrom(point: CGPoint, inout searchingIn points: [CGPoint]) -> [CGPoint] {
        var linePoints = [point]
        var startPoint = point
        while let startPoint = startPoint.nearbyPointIn(points, clockwise: true) {
            linePoints.append(startPoint)
            if let index = points.indexOf(point) {
                points.removeAtIndex(index)
            }
        }
        
        return linePoints
    }
    
    /// Used to get polygon-approximated SPLine.
    private func polygonApproximateThenVectorize(line: SPLine) -> SPLine {
        
        
        return line
    }
*/
    
}






