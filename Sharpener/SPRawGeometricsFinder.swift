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
    func succefullyExtractedSeperatedTexture()
}

/// SPRawGeometricsFinder is used to descriminate shapes and lines from given UIImage.
/// >  It will firstly apply abunch of filter to filter out shape and lines, then seperate them into different groups, refine them (extracting lines from shape, ignoring small shapes in lines, etc.), and create a final seperation for texture, so user can choose to hide or show individual shape or line group in Refine View.
class SPRawGeometricsFinder {
    let context: MXNContext = MXNContext()
    var geometricsFilteringFilter: GeometricsFilteringFilter!
    weak var delegate: SPRawGeometricsFinderDelegate?
    var texture: MTLTexture { return geometricsFilteringFilter.texture }
    
    init(medianFilterRadius: Int, thresholdingFilterThreshold: Float, lineShapeFilteringFilterAttributes: (threshold: Float, radius: Int), extractorSize: CGSize) {
        geometricsFilteringFilter = GeometricsFilteringFilter(context: context,
            medianFilterRadius: medianFilterRadius,
            thresholdingFilterThreshold: thresholdingFilterThreshold,
            lineShapeFilteringFilterAttributes: (lineShapeFilteringFilterAttributes.threshold, lineShapeFilteringFilterAttributes.radius))
    }
    
    /// Used to extract texture from UIImage, runs in Queue_Piority_High
    func extractTextureFrom(image: UIImage) {
        geometricsFilteringFilter.provider = MXNImageProvider(image: image, context: context)
        dispatch_async(dispatch_queue_create("rawgeometrics_finding", DISPATCH_QUEUE_SERIAL)) {
            self.geometricsFilteringFilter.applyFilter()
            if self.geometricsFilteringFilter.texture == nil { return }
            dispatch_async(GCD.mainQueue) {
                self.extractSeperatedTextureForm()
            }
        }
    }
    
    /// Used to store rawGeometric extracted from texture, for shape seperation use.
    var rawGeometrics = [SPRawGeometric]()
    /// Used to store rawGeometric extracted from previous extracted rawGeometrics.
    var extractedRawGeometrics = [SPRawGeometric]()
    var textureData: MXNTextureData!
    
    /// Used to create a first version of rawGeometrics to seperate them into different parts. Called in extractTextureFrom(). Runs in Queue_Piority_High.
    func extractSeperatedTextureForm() {
        textureData = MXNTextureData(texture: texture)
        
        for i in 0..<texture.width {
            for j in 0..<texture.height {
                guard textureData[(i,j)]!.isNotWhiteAndBlack else { continue }
                var points = [CGPoint]()
                flood(i, y: j, into: &points)
                let rawG = SPRawGeometric(type: .Shape, isHidden: false, raw: points, lineSize: 0, shapeSize: 0, simplePath: nil)
                rawGeometrics.append(rawG)
            }
        }
        print(textureData)
        extractGeometrics()
    }
    
    /// Used to refine seperations. Called in extractSeperatedTextureForm(). Runs in Queue_Piority_High.
    func extractGeometrics() {
        for var g in rawGeometrics {
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
            } else {
                g.type = .Line
                
                // clean all green and blue parts
            }
        }
    }
    
    /// Used to find a shape based on a seed point, line-scanning version.
    private func flood(x: Int, y: Int, inout into points: [CGPoint]) {
        guard let c = textureData[(x,y)] else { return }
        guard c.isNotWhiteAndBlack else { return }
        
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
            while let c = textureData[rightPos.right] where c.isNotWhiteAndBlack {
                if !c.isTransparent { // if it's not yet added to points
                    points.append(rightPos.right)
                    textureData.cleanAt(rightPos.right)
                }
                rightPos.move(.Right)
            }
            
            // fill left
            var leftPos = pos
            while let c = textureData[leftPos.left] where c.isNotWhiteAndBlack {
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
                // check upper line
                if let c = textureData[thisPos.up] where c.isNotWhiteAndBlack && c.isTransparent && !topFound {
                    stack.push(thisPos.up)
                    topFound = true
                }
                // check lower line
                if let c = textureData[thisPos.down] where c.isNotWhiteAndBlack && c.isTransparent && !bottomFound {
                    stack.push(thisPos.down)
                    bottomFound = true
                }
            }
        }
    }
}



extension CGPoint  {
    var right: CGPoint { return CGPoint(x: self.x + 1, y: self.y) }
    var left: CGPoint { return CGPoint(x: self.x - 1, y: self.y) }
    var up: CGPoint { return CGPoint(x: self.x, y: self.y + 1) }
    var down: CGPoint { return CGPoint(x: self.x, y: self.y - 1) }
    mutating func move(direction: Direction2D) {
        switch direction {
        case .Up: self.y += 1
        case .Down: self.y -= 1
        case .Left: self.x -= 1
        case .Right: self.x += 1
        default: break
        }
    }
    
    static func horizontalRangeFrom(pointA: CGPoint, to pointB: CGPoint) -> Range<Int> {
        return Int(pointA.x)...Int(pointB.x)
    }
}




