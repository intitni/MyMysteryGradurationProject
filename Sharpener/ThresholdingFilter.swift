//
//  ThresholdingFilter.swift
//  Sharpener
//
//  Created by Inti Guo on 12/22/15.
//  Copyright © 2015 Inti Guo. All rights reserved.
//

import Foundation
import MetalKit
import MetalPerformanceShaders

struct ThresholdingUniforms {
    var thresholdingFactor: Float
}

class ThresholdingFilter: MXNImageFilter {
    
    var thresholdingFactor: Float {
        didSet {
            isDirty = true
        }
    }
    
    required init?(functionName: String, context: MXNContext, thresholdingFactor: Float) {
        self.thresholdingFactor = thresholdingFactor
        super.init(functionName: functionName, context: context)
    }
    
    convenience init?(context: MXNContext, thresholdingFactor: Float) {
        self.init(functionName: "thresholding", context: context, thresholdingFactor: thresholdingFactor)
    }
    
    required init?(functionName: String, context: MXNContext) {
        fatalError("init(functionName:context:) has not been implemented")
    }
    
    override func configureArgumentTableWithCommandEncoder(commandEncoder: MTLComputeCommandEncoder) {
        let uniforms = ThresholdingUniforms(thresholdingFactor: thresholdingFactor)
        putBufferUniforms(uniforms, into: commandEncoder, size: sizeof(ThresholdingUniforms), offset: 0, atIndex: 0)
    }
}
