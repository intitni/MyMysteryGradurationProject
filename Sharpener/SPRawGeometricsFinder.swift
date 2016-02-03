//
//  SPRawGeometricsFinder.swift
//  Sharpener
//
//  Created by Inti Guo on 1/14/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import CoreGraphics
import MetalKit

/// Delegate of SPRawGeometricsFinder
public protocol SPRawGeometricsFinderDelegate: class {
    /// Called at the end of `process()`, after SPRawGeometricsFinder done its work.
    func succefullyFoundRawGeometrics()
}

/// SPRawGeometricsFinder is used to descriminate shapes and lines from given UIImage.
///
/// It will firstly apply abunch of filter to filter out shape and lines, then seperate them into different groups, refine them (extracting lines from shape, ignoring small shapes in lines, etc.), and create a final seperation for texture, so user can choose to hide or show individual shape or line group in Refine View.
public class SPRawGeometricsFinder {
    
    // MARK: Properties
    
    private let context: MXNContext = MXNContext()
    private var geometricsFilteringFilter: GeometricsFilteringFilter!
    weak var delegate: SPRawGeometricsFinderDelegate?
    var texture: MTLTexture { return geometricsFilteringFilter.texture }
    
    /// Used to store rawGeometric extracted from texture, for shape seperation use.
    var rawGeometrics = [SPRawGeometric]()
    /// Used to store rawGeometric extracted from previous extracted rawGeometrics.
    var extractedRawGeometrics = [SPRawGeometric]()
    /// Extracted data of texture
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
    
    /// Process and given UIImage, when done, it will tell its delegate, and store everything in universalStore.
    public func process(image: UIImage) {
        geometricsFilteringFilter.provider = MXNImageProvider(image: image, context: context)
        // TODO: Use NSOperation to make it cancelable.
        dispatch_async(GCD.newSerialQueue("rawgeometrics_finding")) {
            
            self.extractTexture()
            self.extractSeperatedTexture()
            self.extractRawGeometrics()
            self.findContoursOfEachAndPerformSimpleVectorization()
            
            dispatch_async(GCD.mainQueue) {
                SPGeometricsStore.universalStore.rawStore = self.rawGeometrics
                self.delegate?.succefullyFoundRawGeometrics()
            }
        }
    }
    
    /// Used to extract texture from UIImage.
    private func extractTexture() {
        self.geometricsFilteringFilter.applyFilter()
        textureData = MXNTextureData(texture: texture)
    }
    
    /// Used to create a first version of rawGeometrics to seperate them into different parts.
    private func extractSeperatedTexture() {
        var tempTextureData: MXNTextureData = textureData
        for i in 0..<tempTextureData.width {
            for j in 0..<tempTextureData.height {
                guard tempTextureData[(i,j)]!.isNotWhiteAndBlack && !tempTextureData[(i,j)]!.isTransparent else { continue }
                let points = flood(i, j, from: &tempTextureData) { $0.isNotWhiteAndBlack }
                let rawG = SPRawGeometric(raw: points)
                if points.count > 20 { rawGeometrics.append(rawG) }
            }
        }
    }
    
    /// Used to refine seperations.
    private func extractRawGeometrics() {
        var tempTextureData: MXNTextureData = textureData
        var newGeometrics = [SPRawGeometric]()
        defer { textureData = tempTextureData; rawGeometrics = newGeometrics }
        
        for var raw in rawGeometrics {
            
            // calculate size
            for point in raw.raw {
                guard let c = textureData[point] else { continue }
                switch c {
                case let c where c.isInLine:
                    raw.lineSize += 1
                case let c where c.isInShape || c.isInShapeBorder:
                    raw.shapeSize += 1
                default: break
                }
            }
            
            // TODO: Secondary Geometric Seperation
            if checkIfIsShape(raw) {
                raw.type = .Shape
                
                // clean tiny red parts
                // extract big red parts to another rawGeometics
                // turn blue parts into green
                for point in raw.raw {
                    if let c = tempTextureData[point] where c.isInLine {
                        tempTextureData.toShapeAt(point)
                    } else if let c = tempTextureData[point] where c.isInShapeBorder {
                        tempTextureData.toShapeAt(point)
                    }
                }
                
            } else {
                raw.type = .Line
                
                // clean all green and blue parts
                for point in raw.raw {
                    if let c = tempTextureData[point] where c.isInShape || c.isInShapeBorder {
                        tempTextureData.toLineAt(point)
                    }
                }
            }
            newGeometrics.append(raw)
        }
    }

    /// Used to create simple vector borders for each SPRawGeometrics to display.
    private func findContoursOfEachAndPerformSimpleVectorization() {
        var newGeometrics = [SPRawGeometric]()
        defer { rawGeometrics = newGeometrics }
        
        for var raw in rawGeometrics {
            fetchContoursOfRawGeometric(&raw)
            newGeometrics.append(raw)
        }
    }
    
}


// MARK: - Utility Methods
extension SPRawGeometricsFinder {
    /// Used to find a shape based on a seed point, line-scanning version.
    ///
    /// It calls a generic version of `flood()`.
    ///
    /// - Parameters:
    ///     - point: flood starts from
    ///     - from: the textureData that needs process
    ///     - matching: points' pattern that should be flooded
    ///
    /// - Returns: flood result
    private func flood(point: CGPoint, inout from textureData: MXNTextureData, matching checkIfShouldFlood: (RGBAPixel) -> Bool) -> [CGPoint] {
        return flood(Int(point.x), Int(point.y), from: &textureData, matching: checkIfShouldFlood)
    }
    
    /// Finds contours of a given SPRawGeometric with OpenCV and casts them back to SPLines, then perform polygon-approximation on them
    private func fetchContoursOfRawGeometric(inout raw: SPRawGeometric) {
        let cvlines = CVWrapper.findContoursFromBytes(raw.bytesData(textureData) as! [NSNumber], width:textureData.width, height:textureData.height)
        for cvline in cvlines {
            var line = SPLine()
            for rawPointValue in cvline.raw as! [NSValue] {
                let p = rawPointValue.CGPointValue()
                line<--p
            }
            let polygonApproximator = SPPolygonApproximator(threshold: 1.5)
            polygonApproximator.polygonApproximateSPLine(&line)
            raw.borders.append(line)
        }
    }
    
    /// Used to find a shape based on a seed point, line-scanning version.
    /// 1. Starts from a seed point, it scans all points on left/right sides until reaches borders.
    /// 2. Then checks for upper/lower lines if there exists some points that need to be fill.
    /// 3. Mark the left most point of each areas found above, and do the same things on them(go to 1).
    /// 4. End when no more such points found.
    ///
    /// - Parameters:
    ///     - x: x-position of seed point
    ///     - y: y-position of seed point
    ///     - from: the textureData that needs process
    ///     - matching: points' pattern that should be flooded
    ///
    /// - Returns: flood result
    private func flood(x: Int, _ y: Int, inout from textureData: MXNTextureData, matching checkIfShouldFlood: (RGBAPixel) -> Bool) -> [CGPoint] {
        guard let c = textureData[(x,y)] else { return [CGPoint]() }
        guard checkIfShouldFlood(c) && !c.isTransparent else { return [CGPoint]() }
        
        var points = [CGPoint]()
        
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
        return points
    }
    
    func checkIfIsShape(raw: SPRawGeometric) -> Bool {
        if raw.shapeWeight > 0.01 {
            return true
        }
        return false
    }
}






