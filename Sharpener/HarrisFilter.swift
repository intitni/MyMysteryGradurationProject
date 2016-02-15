//
//  HarrisFilter.swift
//  Sharpener
//
//  Created by Inti Guo on 2/10/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation
import MetalKit

struct HarrisFilterUniforms {
    var alpha: Float
}

class HarrisFilter: MXNImageFilter {
    var harrisValues: MTLTexture! { return internalTexture }
    var uniforms: HarrisFilterUniforms
    
    required init?(functionName: String, context: MXNContext, alpha: Float) {
        let newAlpha = max(0.04, min(0.06, alpha))
        uniforms = HarrisFilterUniforms(alpha: newAlpha)
        super.init(functionName: functionName, context: context)
        internalTextureFormat = MTLPixelFormat.RGBA32Float
    }
    
    convenience init(context: MXNContext, alpha: Float = 0.06) {
        self.init(functionName: "harris", context: context, alpha: alpha)!
    }

    required init?(functionName: String, context: MXNContext) {
        fatalError("init(functionName:context:) has not been implemented")
    }
    
    override func configureArgumentTableWithCommandEncoder(commandEncoder: MTLComputeCommandEncoder) {
        putBufferUniforms(uniforms, into: commandEncoder, size: sizeof(HarrisFilterUniforms), offset: 0, atIndex: 0)
    }
}

