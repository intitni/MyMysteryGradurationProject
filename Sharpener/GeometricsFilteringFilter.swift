//
//  GeometricsFilteringFilter.swift
//  Sharpener
//
//  Created by Inti Guo on 1/15/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation
import MetalKit

/// Composition Filter ← (ImageProvider)? > ThresholdingFilter > MedianFilter > LineShapeFilteringFilter > LineShapeRefiningFilter
class GeometricsFilteringFilter: MXNCompositionFilters, MXNDrawablePresentable {
    var thresholdingFilter: ThresholdingFilter!
    var medianFilter: MedianFilter!
    var lineShapeFilteringFilter: LineShapeFilterFilteringFilter!
    var lineShapeRefiningFilter: LineShapeRefiningFilter!
    
    var tailFilter: MXNImageFilter { return lineShapeRefiningFilter }
    var headFilter: MXNImageFilter { return thresholdingFilter }
    var texture: MTLTexture! { return tailFilter.texture }
    var provider: MXNTextureProvider? {
        didSet {
            headFilter.provider = provider
        }
    }
    
    init(context: MXNContext,
        medianFilterRadius: Int,
        thresholdingFilterThreshold: Float,
        lineShapeFilteringFilterAttributes: (threshold: Float, radius: Int)) {
            
        thresholdingFilter = ThresholdingFilter(context: context, thresholdingFactor: thresholdingFilterThreshold)
        medianFilter = MedianFilter(context: context, radius: medianFilterRadius)
        lineShapeFilteringFilter = LineShapeFilterFilteringFilter(context: context,
            threshold: lineShapeFilteringFilterAttributes.threshold,
            radius: lineShapeFilteringFilterAttributes.radius)
        lineShapeRefiningFilter = LineShapeRefiningFilter(context: context, radius: lineShapeFilteringFilterAttributes.radius + 2)
        
        lineShapeFilteringFilter.provider = medianFilter
        medianFilter.provider = thresholdingFilter
        lineShapeRefiningFilter.provider = lineShapeFilteringFilter
    }

}