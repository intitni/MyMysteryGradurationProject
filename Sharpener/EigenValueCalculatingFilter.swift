//
//  EigenValueCalculatingFilter.swift
//  Sharpener
//
//  Created by Inti Guo on 2/8/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation
import MetalKit

class EigenValueVectorCalculatingFilter: MXNImageFilter {
    var eigenValues: MTLTexture! { return internalTexture }
    var eigenVectors: MTLTexture!
    var gradientTensor: MTLTexture? { return self.provider?.texture }
    
    required init?(functionName: String, context: MXNContext) {
        super.init(functionName: functionName, context: context)
        internalTextureFormat = MTLPixelFormat.RGBA32Float
    }
    
    convenience init?(context: MXNContext) {
        self.init(functionName: "eigenCalculating", context: context)
    }
    
    override func configureArgumentTableWithCommandEncoder(commandEncoder: MTLComputeCommandEncoder) {
        if eigenVectors == nil {
            readyOutTextures()
        }
        commandEncoder.setTexture(eigenVectors, atIndex: 2)
    }
    
    func readyOutTextures() {
        guard let inputTexture = self.provider?.texture else { return }
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(internalTextureFormat,
            width: inputTexture.width, height: inputTexture.height, mipmapped: false)
        eigenVectors = context.device?.newTextureWithDescriptor(textureDescriptor)
    }
}
