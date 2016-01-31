//
//  MXNTextureData.swift
//  Sharpener
//
//  Created by Inti Guo on 1/18/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation
import MetalKit
import CoreGraphics

struct MXNTextureData {

    var data: [UInt8]
    let width: Int
    let height: Int
    let bytesPerPixel: Int
    
    init(texture: MTLTexture) {
        var rawData = [UInt8](count: texture.width*texture.height*4, repeatedValue: 0)
        texture.getBytes(&rawData, bytesPerRow: texture.width * 4, fromRegion: MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0), size: MTLSize(width: texture.width, height: texture.height, depth: 1)), mipmapLevel: 0)
        self.init(data: rawData, width: texture.width, height: texture.height)
    }
    
    init(data: [UInt8], width: Int, height: Int, bytesPerPixel: Int = 4) {
        self.width = width
        self.height = height
        self.data = data
        self.bytesPerPixel = bytesPerPixel
    }
    
    subscript(position: (x: Int, y: Int)) -> RGBAPixel? {
        let x = position.x, y = position.y
        guard y < height && x < width && x >= 0 && y >= 0 else { return nil }
        let pos = (x + y * width) * bytesPerPixel
        return RGBAPixel(r:data[pos], g:data[pos+1], b:data[pos+2], a:data[pos+3])
    }
    
    subscript(position: CGPoint) -> RGBAPixel? {
        get {
            let x = Int(position.x), y = Int(position.y)
            guard y < height && x < width && x >= 0 && y >= 0 else { return nil }
            let pos = (x + y * width) * bytesPerPixel
            return RGBAPixel(r:data[pos], g:data[pos+1], b:data[pos+2], a:data[pos+3])
        }
        set {
            let x = Int(position.x), y = Int(position.y)
            guard y < height && x < width && x >= 0 && y >= 0 && newValue != nil else { return }
            let pos = (x + y * width) * bytesPerPixel
            data[pos] = newValue!.r
            data[pos+1] = newValue!.g
            data[pos+2] = newValue!.b
            data[pos+3] = newValue!.a
        }
    }
    
    func indexOfPoint(position: CGPoint) -> Int? {
        let x = Int(position.x), y = Int(position.y)
        guard y < height && x < width && x >= 0 && y >= 0 else { return nil }
        return x + y * width
    }
    
    mutating func eraseAt(x: Int, _ y: Int) {
        guard y < height && x < width && x >= 0 && y >= 0 else { return }
        let pos = (x + y * width) * 4
        data[pos] = 255
        data[pos+1] = 255
        data[pos+2] = 255
    }
    
    mutating func cleanAt(x: Int, _ y: Int) {
        guard y < height && x < width && x >= 0 && y >= 0 else { return }
        let pos = (x + y * width) * 4
        data[pos + 3] = 0
    }
    
    mutating func cleanAt(point: CGPoint) {
        let x = Int(point.x), y = Int(point.y)
        guard y < height && x < width && x >= 0 && y >= 0 else { return }
        let pos = (x + y * width) * 4
        data[pos + 3] = 0
    }
    
    mutating func toShapeBorderAt(point: CGPoint) {
        let x = Int(point.x), y = Int(point.y)
        guard y < height && x < width && x >= 0 && y >= 0 else { return }
        let pos = (x + y * width) * 4
        data[pos] = 66
        data[pos+1] = 133
        data[pos+2] = 214
    }
    
    mutating func toLineAt(point: CGPoint) {
        let x = Int(point.x), y = Int(point.y)
        guard y < height && x < width && x >= 0 && y >= 0 else { return }
        let pos = (x + y * width) * 4
        data[pos] = 209
        data[pos+1] = 117
        data[pos+2] = 120
    }
    
    mutating func toShapeAt(point: CGPoint) {
        let x = Int(point.x), y = Int(point.y)
        guard y < height && x < width && x >= 0 && y >= 0 else { return }
        let pos = (x + y * width) * 4
        data[pos] = 107
        data[pos+1] = 181
        data[pos+2] = 161
    }
    
    /// Check if this point is border of this data, 4-way version
    func isBorderAtPoint(point: CGPoint) -> Bool {
        let shouldCheckPoints = [point.up, point.down, point.left, point.right]
        for point in shouldCheckPoints {
            if let c = self[point] {
                if !c.isNotWhiteAndBlack { return true }
            } else { // when it's border of texture, it's border of shape
                return true
            }
        }
        
        return false
    }
}

struct RGBAPixel {
    var r: UInt8
    var g: UInt8
    var b: UInt8
    var a: UInt8
}

extension RGBAPixel {
    var isNotWhiteAndBlack: Bool { return self.r != 255 && self.r != 0 }
    var isInShape: Bool { return self.r == 107 }
    var isInShapeBorder: Bool { return self.r == 66 }
    var isInLine: Bool { return self.r == 209 }
    var isTransparent: Bool { return self.a == 0 }
    
    /* 
            66, 133, 214 0.25 b
            209, 117, 120 0.82 r
            107, 181, 161 0.42 g
        */
}

