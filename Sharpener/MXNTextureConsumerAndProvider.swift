//
//  MXNTextureConsumerAndProvider.swift
//  Sharpener
//
//  Created by Inti Guo on 12/20/15.
//  Copyright © 2015 Inti Guo. All rights reserved.
//

import Foundation
import MetalKit

protocol MXNTextureProvider {
    var texture: MTLTexture! { get }
}

protocol MXNTextureConsumer {
    var provider: MXNTextureProvider? { get set }
}

protocol MXNDrawablePresentable {
    func presentToDrawable(drawable: CAMetalDrawable)
}

class MXNSimpleTextureProvider: MXNTextureProvider {
    var texture: MTLTexture!
    
    init(texture: MTLTexture) {
        self.texture = texture
    }
}