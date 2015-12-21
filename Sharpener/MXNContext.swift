//
//  MXNContext.swift
//  Sharpener
//
//  Created by Inti Guo on 12/20/15.
//  Copyright © 2015 Inti Guo. All rights reserved.
//

import Foundation
import MetalKit

class MXNContext {
    var device: MTLDevice?
    var library: MTLLibrary?
    var commandQueue: MTLCommandQueue?
    
    init(device: MTLDevice? = MTLCreateSystemDefaultDevice()) {
        self.device = device
        self.library = device?.newDefaultLibrary()
        self.commandQueue = device?.newCommandQueue()
    }
}