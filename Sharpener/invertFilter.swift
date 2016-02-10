//
//  invertFilter.swift
//  Sharpener
//
//  Created by Inti Guo on 2/10/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation
import MetalKit

class InvertFilter: MXNImageFilter {
    required init?(functionName: String, context: MXNContext) {
        super.init(functionName: functionName, context: context)
    }
    
    convenience init?(context: MXNContext) {
        self.init(functionName: "invert", context: context)
    }
}