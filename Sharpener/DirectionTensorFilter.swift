//
//  DirectionTensorFilter.swift
//  Sharpener
//
//  Created by Inti Guo on 2/10/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation
import MetalKit


class DirectionTensorCalculatingFilter: MXNImageFilter {
    
    var xOperator: MTLTexture!
    var yOperator: MTLTexture!
    
    required init?(functionName: String, context: MXNContext) {
        super.init(functionName: functionName, context: context)
        internalTextureFormat = MTLPixelFormat.RGBA32Float
    }
    
    convenience init?(context: MXNContext) {
        self.init(functionName: "directionTensorCalculating", context: context)
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
        let weightX: [Float] = [0,0,0,-1,0,1,0,0,0]
        let weightY: [Float] = [0,-1,0,0,0,0,0,1,0]
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.R32Float, width: size, height: size, mipmapped: false)
        let region = MTLRegionMake2D(0, 0, size, size)
        
        xOperator = context.device?.newTextureWithDescriptor(textureDescriptor)
        xOperator.replaceRegion(region, mipmapLevel: 0, withBytes: weightX, bytesPerRow: sizeof(Float)*size)
        yOperator = context.device?.newTextureWithDescriptor(textureDescriptor)
        yOperator.replaceRegion(region, mipmapLevel: 0, withBytes: weightY, bytesPerRow: sizeof(Float)*size)
    }
}