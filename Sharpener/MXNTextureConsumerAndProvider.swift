//
//  MXNTextureConsumerAndProvider.swift
//  Sharpener
//
//  Created by Inti Guo on 12/20/15.
//  Copyright © 2015 Inti Guo. All rights reserved.
//

import Foundation
import MetalKit

protocol MXNTextureProvider {
    var texture: MTLTexture! { get }
}

protocol MXNTextureConsumer {
    var provider: MXNTextureProvider? { get set }
}

protocol MXNDrawablePresentable {
    func presentToDrawable(drawable: CAMetalDrawable)
}

class MXNSimpleTextureProvider: MXNTextureProvider {
    var texture: MTLTexture!
    
    init(texture: MTLTexture) {
        self.texture = texture
    }
}

extension UIImage {
    convenience init(texture: MTLTexture) {
        let t = texture
        var rawData = [UInt8](count: t.width*t.height*4, repeatedValue: 0)
        t.getBytes(&rawData, bytesPerRow: t.width * 4, fromRegion: MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0), size: MTLSize(width: t.width, height: t.height, depth: 1)), mipmapLevel: 0)
        
        let providerRef = CGDataProviderCreateWithCFData(
            NSData(bytes: &rawData, length: rawData.count * sizeof(UInt8))
        )
        
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.ByteOrder32Big.rawValue | CGImageAlphaInfo.PremultipliedLast.rawValue)
        
        let renderingIntent = CGColorRenderingIntent.RenderingIntentDefault
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = t.width * bytesPerPixel
        
        let imageRef = CGImageCreate(Int(t.width), Int(t.height), 8, 8 * 4, bytesPerRow, colorSpace, bitmapInfo, providerRef, nil, false, renderingIntent)
        self.init(CGImage: imageRef!)
    }
    
    convenience init(textureData: MXNTextureData) {
        let rawData = textureData.data
        
        let providerRef = CGDataProviderCreateWithCFData(
            NSData(bytes: rawData, length: rawData.count * sizeof(UInt8))
        )
        
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.ByteOrder32Big.rawValue | CGImageAlphaInfo.PremultipliedLast.rawValue)
        
        let renderingIntent = CGColorRenderingIntent.RenderingIntentDefault
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = textureData.width * bytesPerPixel
        
        let imageRef = CGImageCreate(Int(textureData.width), Int(textureData.height), 8, 8 * 4, bytesPerRow, colorSpace, bitmapInfo, providerRef, nil, false, renderingIntent)
        self.init(CGImage: imageRef!)
    }
}