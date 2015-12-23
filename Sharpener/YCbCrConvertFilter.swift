//
//  YCbCrConvertFilter.swift
//  Sharpener
//
//  Created by Inti Guo on 12/20/15.
//  Copyright © 2015 Inti Guo. All rights reserved.
//

import Foundation
import MetalKit

class YCbCrConvertFilter: MXNImageFilter {
    var yTexture: MTLTexture!
    var cbcrTexture: MTLTexture!
    
    convenience init?(context: MXNContext) {
        self.init(functionName: "YCbCrColorConversion", context: context)
    }
    
    override func applyFilter() {
        guard yTexture != nil && cbcrTexture != nil else { return }
        
        if internalTexture == nil || internalTexture?.width != yTexture.width || internalTexture?.height != yTexture.height {
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(yTexture.pixelFormat,
                width: yTexture.width, height: yTexture.height, mipmapped: false)
            internalTexture = context.device?.newTextureWithDescriptor(textureDescriptor)
        }
        
        let threadgroupCounts = MTLSizeMake(8, 8, 1)
        let threadgroups = MTLSizeMake(yTexture.width / threadgroupCounts.width, yTexture.height / threadgroupCounts.height, 1)
        
        guard let commandBuffer = context.commandQueue?.commandBuffer() else { return }
        
        let commandEncoder = commandBuffer.computeCommandEncoder()
        commandEncoder.setComputePipelineState(pipeline)
        commandEncoder.setTexture(yTexture, atIndex: 0) // read texture
        commandEncoder.setTexture(cbcrTexture, atIndex: 1) // read texture
        commandEncoder.setTexture(internalTexture, atIndex: 2) // write texture
        commandEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadgroupCounts)
        commandEncoder.endEncoding()
        
        commandBuffer.commit()
        if shouldWaitUntilCompleted { commandBuffer.waitUntilCompleted() }
    }
    
    override func presentToDrawable(drawable: CAMetalDrawable) {
        guard yTexture != nil && cbcrTexture != nil else { return }
        
        if internalTexture == nil || internalTexture?.width != yTexture.width || internalTexture?.height != yTexture.height {
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(yTexture.pixelFormat,
                width: yTexture.width, height: yTexture.height, mipmapped: false)
            internalTexture = context.device?.newTextureWithDescriptor(textureDescriptor)
        }

        let threadgroupCounts = MTLSizeMake(8, 8, 1)
        let threadgroups = MTLSizeMake(yTexture.width / threadgroupCounts.width, yTexture.height / threadgroupCounts.height, 1)
        
        guard let commandBuffer = context.commandQueue?.commandBuffer() else { return }
        
        let commandEncoder = commandBuffer.computeCommandEncoder()
        commandEncoder.setComputePipelineState(pipeline)
        commandEncoder.setTexture(yTexture, atIndex: 0) // read texture
        commandEncoder.setTexture(cbcrTexture, atIndex: 1) // read texture
        commandEncoder.setTexture(drawable.texture, atIndex: 2) // write texture
        commandEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadgroupCounts)
        commandEncoder.endEncoding()
        
        commandBuffer.presentDrawable(drawable)
        commandBuffer.commit()
    }
}