//
//  GradientTensorCalculatingFilter.swift
//  Sharpener
//
//  Created by Inti Guo on 2/7/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation
import MetalKit


class GradientTensorCalculatingFilter: MXNImageFilter {
    
    var xOperator: MTLTexture!
    var yOperator: MTLTexture!
    
    required init?(functionName: String, context: MXNContext) {
        super.init(functionName: functionName, context: context)
        internalTextureFormat = MTLPixelFormat.RGBA32Float
    }
    
    convenience init?(context: MXNContext) {
        self.init(functionName: "gradientTensorCalculating", context: context)
    }
    
    override func configureArgumentTableWithCommandEncoder(commandEncoder: MTLComputeCommandEncoder) {
        if xOperator == nil || yOperator == nil {
            generateWeightTexture()
        }
        commandEncoder.setTexture(xOperator, atIndex: 2)
        commandEncoder.setTexture(yOperator, atIndex: 3)
    }
    
    func generateWeightTexture() {
        let size = 3
        let weightX: [Float] = [-1,0,1,-2,0,2,-1,0,1]
        let weightY: [Float] = [-1,-2,-1,0,0,0,1,2,1]
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.R32Float, width: size, height: size, mipmapped: false)
        let region = MTLRegionMake2D(0, 0, size, size)
        
        xOperator = context.device?.newTextureWithDescriptor(textureDescriptor)
        xOperator.replaceRegion(region, mipmapLevel: 0, withBytes: weightX, bytesPerRow: sizeof(Float)*size)
        yOperator = context.device?.newTextureWithDescriptor(textureDescriptor)
        yOperator.replaceRegion(region, mipmapLevel: 0, withBytes: weightY, bytesPerRow: sizeof(Float)*size)
    }
}