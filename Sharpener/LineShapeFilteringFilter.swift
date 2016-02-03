//
//  LineShapeFilteringFilter.swift
//  Sharpener
//
//  Created by Inti Guo on 12/22/15.
//  Copyright © 2015 Inti Guo. All rights reserved.
//

import Foundation
import MetalKit

struct LineShapeDetectingUniforms {
    var threshold: Float
}

class LineShapeFilterFilteringFilter: MXNImageFilter {
    
    var threshold: Float {
        didSet {
            isDirty = true
        }
    }
    var radius: Int {
        didSet {
            isDirty = true
            generateWeightTexture()
        }
    }
    var weightTexture: MTLTexture!
    
    required init?(functionName: String, context: MXNContext, threshold: Float, radius: Int) {
        self.threshold = threshold
        self.radius = radius
        super.init(functionName: functionName, context: context)
    }
    
    convenience init?(context: MXNContext, threshold: Float, radius: Int) {
        self.init(functionName: "lineShapeFiltering", context: context, threshold: threshold, radius: radius)
    }
    
    required init?(functionName: String, context: MXNContext) {
        fatalError("init(functionName:context:) has not been implemented")
    }
    
    override func configureArgumentTableWithCommandEncoder(commandEncoder: MTLComputeCommandEncoder) {
        let uniforms = LineShapeDetectingUniforms(threshold: threshold)
        putBufferUniforms(uniforms, into: commandEncoder, size: sizeof(LineShapeDetectingUniforms), offset: 0, atIndex: 0)
        
        if weightTexture == nil {
            generateWeightTexture()
        }
        commandEncoder.setTexture(weightTexture, atIndex: 2)
    }
    
    func generateWeightTexture() {
        let size = radius * 2 + 1
        var weight = [Float](count: size*size, repeatedValue: 0)
        weight[0] = 1
        weight[size * size - 1] = 1
        weight[size - 1] = 1
        weight[(size-1)*size] = 1
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.R32Float, width: size, height: size, mipmapped: false)
        weightTexture = context.device?.newTextureWithDescriptor(textureDescriptor)
        let region = MTLRegionMake2D(0, 0, size, size)
        weightTexture.replaceRegion(region, mipmapLevel: 0, withBytes: weight, bytesPerRow: sizeof(Float)*size)
    }
}