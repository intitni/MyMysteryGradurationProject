//
//  LineTrackingFilter.swift
//  Sharpener
//
//  Created by Inti Guo on 2/9/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation

class LineTrackingFilter: MXNCompositionFilters {
    var t: ThresholdingFilter!
    var gradientTensorCalculatingFilter: GradientTensorCalculatingFilter!
    var gaussianBlurFilter: GaussianBlurFilter!
    var eigenValueVectorCalculatingFilter: EigenValueVectorCalculatingFilter!
    
    var tailFilter: MXNImageFilter { return eigenValueVectorCalculatingFilter }
    var headFilter: MXNImageFilter { return t }
    var texture: MTLTexture! { return tailFilter.texture }
    var provider: MXNTextureProvider? {
        didSet {
            headFilter.provider = provider
        }
    }
    
    var gradientTensor: MTLTexture { return eigenValueVectorCalculatingFilter.gradientTensor! }
    var eigenValues: MTLTexture { return eigenValueVectorCalculatingFilter.eigenValues! }
    var eigenVectors: MTLTexture { return eigenValueVectorCalculatingFilter.eigenVectors }

    init(context: MXNContext) {
        t = ThresholdingFilter(context: context, thresholdingFactor: 0.5)
        
        gradientTensorCalculatingFilter = GradientTensorCalculatingFilter(context: context)
        gaussianBlurFilter = GaussianBlurFilter(context: context, radius: 2)
        eigenValueVectorCalculatingFilter = EigenValueVectorCalculatingFilter(context: context)
        
        gradientTensorCalculatingFilter.provider = t
        gaussianBlurFilter.provider = gradientTensorCalculatingFilter
        eigenValueVectorCalculatingFilter.provider = gaussianBlurFilter
    }
}