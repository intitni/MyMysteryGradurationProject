//
//  SPRawGeometrics.swift
//  Sharpener
//
//  Created by Inti Guo on 1/14/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import CoreGraphics

struct SPRawGeometric {
    var type: SPGeometricType
    var isHidden: Bool = false
    var raw = [CGPoint]()
    var lineSize: Int
    var shapeSize: Int
    var shapeWieght: Int { return shapeSize / lineSize }
}