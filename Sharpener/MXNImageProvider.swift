//
//  MXNImageProvider.swift
//  Sharpener
//
//  Created by Inti Guo on 12/20/15.
//  Copyright © 2015 Inti Guo. All rights reserved.
//

import Foundation
import MetalKit

class MXNImageProvider: MXNTextureProvider {
    var texture: MTLTexture!
    
    required init(image: UIImage, context: MXNContext) {
        texture = textureFromImage(image, context: context)
    }
    
    convenience init?(imageName: String, context: MXNContext) {
        if let image = UIImage(named: imageName) {
            self.init(image: image, context: context)
        } else {
            return nil
        }
    }
    
    func textureFromImage(image: UIImage, context: MXNContext) -> MTLTexture? {
        guard context.device != nil else { return nil }
        
        let imageRef = image.CGImage
        let imageWidth = CGImageGetWidth(imageRef)
        let imageHeight = CGImageGetHeight(imageRef)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = imageWidth * bytesPerPixel
        let bitsPerComponent = 8
        var rawData = [UInt8](count: imageWidth*imageHeight*4, repeatedValue: 0) // an array storing image data
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.ByteOrder32Big.rawValue | CGImageAlphaInfo.PremultipliedLast.rawValue)
        let bitmapContext = CGBitmapContextCreate(&rawData, imageWidth, imageHeight,
            bitsPerComponent, bytesPerRow,
            colorSpace,
            bitmapInfo.rawValue)
        //CGContextTranslateCTM(bitmapContext, 0, CGFloat(imageHeight))
        //CGContextScaleCTM(bitmapContext, 1, -1)
        
        CGContextDrawImage(bitmapContext, CGRectMake(0, 0, CGFloat(imageWidth), CGFloat(imageHeight)), imageRef)
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.RGBA8Unorm,
            width: imageWidth, height: imageHeight,
            mipmapped: true)
        texture = context.device!.newTextureWithDescriptor(textureDescriptor)
        let region = MTLRegionMake2D(0, 0, imageWidth, imageHeight)
        texture.replaceRegion(region, mipmapLevel: 0, withBytes: &rawData, bytesPerRow: bytesPerRow)
        
        return texture
    }
}