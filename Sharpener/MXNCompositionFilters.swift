//
//  MXNCompositionFilters.swift
//  Sharpener
//
//  Created by Inti Guo on 1/15/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation
import MetalKit

protocol MXNCompositionFilters: MXNTextureConsumer, MXNTextureProvider {
    /// Should be the last filter in chain
    var tailFilter: MXNImageFilter { get }
    /// Should be the first filter in chain
    var headFilter: MXNImageFilter { get }
    var texture: MTLTexture! { get }
    var provider: MXNTextureProvider? { get set }
}

extension MXNCompositionFilters {
    func applyFilter() {
        guard provider != nil && tailFilter.provider != nil else { return }
        tailFilter.applyFilter()
    }
}

extension MXNCompositionFilters where Self: MXNDrawablePresentable {
    func presentToDrawable(drawable: CAMetalDrawable) {
        guard provider != nil && tailFilter.provider != nil else { return }
        tailFilter.presentToDrawable(drawable)
    }
}