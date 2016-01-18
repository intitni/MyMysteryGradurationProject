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
        let x = Int(position.x), y = Int(position.y)
        guard y < height && x < width && x >= 0 && y >= 0 else { return nil }
        let pos = (x + y * width) * bytesPerPixel
        return RGBAPixel(r:data[pos], g:data[pos+1], b:data[pos+2], a:data[pos+3])
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
    
    struct RGBAPixel {
        var r: UInt8
        var g: UInt8
        var b: UInt8
        var a: UInt8
        
        var isNotWhiteAndBlack: Bool { return self.r != 255 && self.r != 0 }
        var isInShape: Bool { return self.r == 40 }
        var isInShapeBorder: Bool { return self.r == 50 }
        var isInLine: Bool { return self.r == 60 }
        var isTransparent: Bool { return self.a == 0 }
    }
}

