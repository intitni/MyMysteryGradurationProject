//
//  RedOnlyFilter.swift
//  Sharpener
//
//  Created by Inti Guo on 12/20/15.
//  Copyright © 2015 Inti Guo. All rights reserved.
//

import Foundation
import MetalKit

class RedOnlyFilter: MXNImageFilter, MXNDrawablePresentable {
    
    convenience init?(context: MXNContext) {
        self.init(functionName: "red_only", context: context)
    }
    
    func presentDrawable(drawable: CAMetalDrawable) {
        guard let inputTexture = self.provider?.texture else { return } // one should always have provider
        if internalTexture == nil || internalTexture?.width != inputTexture.width || internalTexture?.height != inputTexture.height {
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(inputTexture.pixelFormat,
                width: inputTexture.width, height: inputTexture.height, mipmapped: false)
            internalTexture = context.device?.newTextureWithDescriptor(textureDescriptor)
        }
        
        let threadgroupCounts = MTLSizeMake(8, 8, 1)
        let threadgroups = MTLSizeMake(inputTexture.width / threadgroupCounts.width, inputTexture.height / threadgroupCounts.height, 1)
        
        guard let commandBuffer = context.commandQueue?.commandBuffer() else { return }
        
        let commandEncoder = commandBuffer.computeCommandEncoder()
        commandEncoder.setComputePipelineState(pipeline)
        commandEncoder.setTexture(inputTexture, atIndex: 0) // read texture
        commandEncoder.setTexture(drawable.texture, atIndex: 1) // write texture
        configureArgumentTableWithCommandEncoder(commandEncoder) // do shader specific stuff
        commandEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadgroupCounts)
        commandEncoder.endEncoding()
        
        commandBuffer.presentDrawable(drawable)
        commandBuffer.commit()
    }
}