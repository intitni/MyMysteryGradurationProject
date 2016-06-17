//
//  MetalVideoView.swift
//  Sharpener
//
//  Created by Inti Guo on 12/21/15.
//  Copyright © 2015 Inti Guo. All rights reserved.
//

import Foundation
import MetalKit

class MetalVideoView: MTKView {
    var filter: MXNImageFilter!
    var shouldDraw: Bool = true
    
    init(frame frameRect: CGRect, device: MTLDevice, filter: MXNImageFilter) {
        super.init(frame: frameRect, device: device)
        self.filter = filter
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawRect(rect: CGRect) {
        guard let drawable = currentDrawable else { return }
        if shouldDraw {
            filter.presentToDrawable(drawable)
        }
    }
}
