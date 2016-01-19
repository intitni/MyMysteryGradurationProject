//
//  SPRawGeometrics.swift
//  Sharpener
//
//  Created by Inti Guo on 1/14/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import UIKit

struct SPRawGeometric {
    var type: SPGeometricType = .Shape
    var isHidden: Bool = false
    var raw = [CGPoint]()
    var lineSize: Int = 0
    var shapeSize: Int = 0
    var shapeWeight: Int { return shapeSize / (lineSize + shapeSize + 1) }
    var borders = [SPLine]()
    
    init(raw: [CGPoint] = [CGPoint]()) {
        self.raw = raw
    }
}
