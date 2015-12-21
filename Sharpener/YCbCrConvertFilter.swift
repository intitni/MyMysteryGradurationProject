//
//  YCbCrConvertFilter.swift
//  Sharpener
//
//  Created by Inti Guo on 12/20/15.
//  Copyright © 2015 Inti Guo. All rights reserved.
//

import Foundation
import MetalKit

class YCbCrConvertFilter: MXNTextureProvider {
    var yTexture: MTLTexture!
    var cbcrTexture: MTLTexture!
    
    var context: MXNContext!
    var uniformBuffer: MTLBuffer?
    var pipeline: MTLComputePipelineState!
    var isDirty: Bool = true
    var kernalFunction: MTLFunction!
    var texture: MTLTexture! {
        get {
            if isDirty {
                applyFilter()
            }
            return internalTexture
        }
    }
    var internalTexture: MTLTexture?
    var shouldWaitUntilCompleted: Bool = true
    
     init?(context: MXNContext) {
        guard context.device != nil && context.commandQueue != nil && context.library != nil else { return nil }
        
        self.context = context
        self.kernalFunction = context.library!.newFunctionWithName("YCbCrColorConversion")
        if self.kernalFunction == nil { return nil }
        do {
            try self.pipeline = context.device!.newComputePipelineStateWithFunction(self.kernalFunction)
        } catch {
            return nil
        }
    }

    func applyFilter() {
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
}