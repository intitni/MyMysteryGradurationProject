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
    var preBlurFilter: GaussianBlurFilter!
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
        
        preBlurFilter = GaussianBlurFilter(context: context, radius: 1, sigma: 1)
        gradientTensorCalculatingFilter = GradientTensorCalculatingFilter(context: context)
        gaussianBlurFilter = GaussianBlurFilter(context: context, radius: 6, sigma: 1.5)
        eigenValueVectorCalculatingFilter = EigenValueVectorCalculatingFilter(context: context)
        
        preBlurFilter.provider = t
        gradientTensorCalculatingFilter.provider = t
        gaussianBlurFilter.provider = gradientTensorCalculatingFilter
        eigenValueVectorCalculatingFilter.provider = gaussianBlurFilter
    }
}