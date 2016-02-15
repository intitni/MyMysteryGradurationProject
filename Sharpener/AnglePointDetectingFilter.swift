//
//  AnglePointDetectingFilter.swift
//  Sharpener
//
//  Created by Inti Guo on 2/10/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation

class AnglePointDetectingFilter: MXNCompositionFilters {
    var t: ThresholdingFilter!
    var gradientTensorCalculatingFilter: DirectionTensorCalculatingFilter!
    var gaussianBlurFilter: GaussianBlurFilter!
    var harrisFilter: HarrisFilter!
    var invert: InvertFilter!
    
    var tailFilter: MXNImageFilter { return harrisFilter }
    var headFilter: MXNImageFilter { return t }
    var texture: MTLTexture! { return tailFilter.texture }
    var provider: MXNTextureProvider? {
        didSet {
            headFilter.provider = provider
        }
    }
    
    var harrisValues: MTLTexture { return harrisFilter.harrisValues }
    
    init(context: MXNContext) {
        t = ThresholdingFilter(context: context, thresholdingFactor: 0.5)
        invert = InvertFilter(context: context)
        gradientTensorCalculatingFilter = DirectionTensorCalculatingFilter(context: context)
        gaussianBlurFilter = GaussianBlurFilter(context: context, radius: 4, sigma: 2)
        harrisFilter = HarrisFilter(context: context, alpha: 0.04)
        
        invert.provider = t
        gradientTensorCalculatingFilter.provider = invert
        gaussianBlurFilter.provider = gradientTensorCalculatingFilter
        harrisFilter.provider = gaussianBlurFilter
    }
}