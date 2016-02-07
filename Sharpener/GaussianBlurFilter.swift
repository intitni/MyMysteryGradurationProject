//
//  GaussianBlurFilter.swift
//  Sharpener
//
//  Created by Inti Guo on 2/7/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation
import MetalKit


class GaussianBlurFilter: MXNImageFilter {
    
    var radius: Int {
        didSet {
            isDirty = true
            generateWeightTexture()
        }
    }
    var sigma: Double {
        didSet {
            isDirty = true
            sigmaPow2 = sigma * sigma
            pre = 1 / (2 * 3.141593 * sigmaPow2)
            generateWeightTexture()
        }
    }
    var sigmaPow2: Double
    var pre: Double
    let e: Double =  2.71828
    var weightTexture: MTLTexture!
    
    required init?(functionName: String, context: MXNContext, radius: Int, sigma: Double) {
        self.radius = radius
        super.init(functionName: functionName, context: context)
    }
    
    convenience init?(context: MXNContext, radius: Int, sigma: Double = 1.5) {
        self.init(functionName: "gaussianBlur", context: context, radius: radius, sigma: sigma)
    }
    
    required init?(functionName: String, context: MXNContext) {
        fatalError("init(functionName:context:) has not been implemented")
    }
    
    override func configureArgumentTableWithCommandEncoder(commandEncoder: MTLComputeCommandEncoder) {
        if weightTexture == nil {
            generateWeightTexture()
        }
        commandEncoder.setTexture(weightTexture, atIndex: 2)
    }
    
    func generateWeightTexture() {
        let size = radius * 2 + 1
        var weight = [Float](count: size*size, repeatedValue: 0)
        for i in 0..<weight.count {
            let p = CGPoint(x: i%size, y: i/size)
            weight[i] = weightForPoint(p)
        }
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.R32Float, width: size, height: size, mipmapped: false)
        weightTexture = context.device?.newTextureWithDescriptor(textureDescriptor)
        let region = MTLRegionMake2D(0, 0, size, size)
        weightTexture.replaceRegion(region, mipmapLevel: 0, withBytes: weight, bytesPerRow: sizeof(Float)*size)
    }
    
    /// G(x, y) = (1 / 2πσ²)  * e^( -(x² + y²) / 2σ² )
    private func weightForPoint(point: CGPoint) -> Float {
        let mxppyp = Double(-pow(point.x, 2) - pow(point.y, 2))
        let post = pow(e, mxppyp / 2 / sigmaPow2)
        return Float(pre * post)
    }
}