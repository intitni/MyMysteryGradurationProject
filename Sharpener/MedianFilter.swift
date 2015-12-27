//
//  MedianFilter.swift
//  Sharpener
//
//  Created by Inti Guo on 12/23/15.
//  Copyright © 2015 Inti Guo. All rights reserved.
//

import Foundation
import MetalKit
import MetalPerformanceShaders

struct MedianFilterUniforms {
    var radius: Int
}

class MedianFilter: MXNImageFilter {
    
    var radius: Int {
        didSet {
            isDirty = true
        }
    }
    
    required init?(functionName: String, context: MXNContext, radius: Int) {
        self.radius = radius
        super.init(functionName: functionName, context: context)
    }
    
    convenience init?(context: MXNContext, radius: Int) {
        self.init(functionName: "medianFilter", context: context, radius: radius)
    }
    
    required init?(functionName: String, context: MXNContext) {
        fatalError("init(functionName:context:) has not been implemented")
    }
    
    override func configureArgumentTableWithCommandEncoder(commandEncoder: MTLComputeCommandEncoder) {
        let uniforms = MedianFilterUniforms(radius: radius)
        putBufferUniforms(uniforms, into: commandEncoder, size: sizeof(MedianFilterUniforms), offset: 0, atIndex: 0)
    }
}
