//
//  SPRawGeometricsFinder.swift
//  Sharpener
//
//  Created by Inti Guo on 1/14/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import CoreGraphics
import MetalKit

protocol SPRawGeometricsFinderDelegate {
    func succefullyExtractedSeperatedTexture()
}

/// SPRawGeometricsFinder is used to descriminate shapes and lines from given UIImage.
/// >  It will firstly apply abunch of filter to filter out shape and lines, then seperate them into different groups, refine them (extracting lines from shape, ignoring small shapes in lines, etc.), and create a final seperation for texture, so user can choose to hide or show individual shape or line group in Refine View.
class SPRawGeometricsFinder {
    let context: MXNContext = MXNContext()
    var geometricsFilteringFilter: GeometricsFilteringFilter!
    var delegate: SPRawGeometricsFinderDelegate?
    
    init(medianFilterRadius: Int, thresholdingFilterThreshold: Float, lineShapeFilteringFilterAttributes: (threshold: Float, radius: Int), extractorSize: CGSize) {
        geometricsFilteringFilter = GeometricsFilteringFilter(context: context,
            medianFilterRadius: medianFilterRadius,
            thresholdingFilterThreshold: thresholdingFilterThreshold,
            lineShapeFilteringFilterAttributes: (lineShapeFilteringFilterAttributes.threshold, lineShapeFilteringFilterAttributes.radius))
    }
    
    /// Used to extract texture from UIImage, runs in Queue_Piority_High
    func extractTextureFrom(image: UIImage) {
        geometricsFilteringFilter.provider = MXNImageProvider(image: image, context: context)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            self.geometricsFilteringFilter.applyFilter()
            if self.geometricsFilteringFilter.texture == nil { return }
            self.extractSeperatedTextureForm(self.geometricsFilteringFilter.texture)
        }
    }
    
    /// Used to store rawGeometric extracted from texture, for shape seperation use.
    var rawGeometrics = [SPRawGeometric]()
    
    /// Used to create a first version of rawGeometrics to seperate them into different parts. Called in extractTextureFrom(). Runs in Queue_Piority_High, back to Main_Queue in the end.
    func extractSeperatedTextureForm(texture: MTLTexture) {
        var rawData = [UInt8](count: texture.width*texture.height*4, repeatedValue: 0)
        texture.getBytes(&rawData, bytesPerRow: texture.width * 4, fromRegion: MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0), size: MTLSize(width: texture.width, height: texture.height, depth: 1)), mipmapLevel: 0)
        var data = TextureData(data: rawData, width: texture.width, height: texture.height)
        for i in 0..<texture.width {
            for j in 0..<texture.height {
                if data[(i,j)]!.r != 255 && data[(i,j)]!.r != 0 {
                    var points = [CGPoint]()
                    flood(&data, x: i, y: j, into: &points)
                    let rawG = SPRawGeometric(type: .Shape, isHidden: false, raw: points, lineSize: 0, shapeSize: 0, simplePath: nil)
                    rawGeometrics.append(rawG)
                }
            }
        }
        dispatch_async(dispatch_get_main_queue()) {
            print(self.rawGeometrics)
            self.delegate?.succefullyExtractedSeperatedTexture()
        }
    }
    
    func extractGeometricsFrom(texture: MTLTexture) {
        
    }
    
    /// used to find a shape based on a seed point
    /// - todo: flood based on line scanning.
    private func flood(inout data: TextureData, x: Int, y: Int, inout into points: [CGPoint]) {
        let c = data[(x,y)]
        guard c != nil else { return }
        guard c!.r != 255 && c!.r != 0 else { return }
        
        data.eraseAt(x, y)
        points.append(CGPoint(x: x, y: y))
        
        flood(&data, x: x-1, y: y-1, into: &points)
        flood(&data, x: x-1, y: y, into: &points)
        flood(&data, x: x-1, y: y+1, into: &points)
        flood(&data, x: x, y: y-1, into: &points)
        flood(&data, x: x, y: y+1, into: &points)
        flood(&data, x: x+1, y: y-1, into: &points)
        flood(&data, x: x+1, y: y, into: &points)
        flood(&data, x: x+1, y: y+1, into: &points)
    }
}

struct TextureData {
    var data: [UInt8]
    let width: Int
    let height: Int
    subscript(position: (x: Int, y: Int)) -> (r: UInt8, g: UInt8, b: UInt8, a: UInt8)? {
        guard position.y <= height && position.x <= width && position.x >= 0 && position.y >= 0 else { return nil }
        let x = position.x, y = position.y
        let pos = (x + y * width) * 4
        return (data[pos], data[pos+1], data[pos+2], data[pos+3])
    }
    
    mutating func eraseAt(x: Int, _ y: Int) {
        guard y <= height && x <= width && x >= 0 && y >= 0 else { return }
        let pos = (x + y * width) * 4
        data[pos] = 255
        data[pos+1] = 255
        data[pos+2] = 255
    }
}

