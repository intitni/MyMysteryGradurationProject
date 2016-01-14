//
//  SPRawGeometrics.swift
//  Sharpener
//
//  Created by Inti Guo on 1/14/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import UIKit

struct SPRawGeometric {
    var type: SPGeometricType
    var raw = [CGPoint]()
    var rectSize: Int
    var shapeSize: Int
    var shapeWieght: Int { return shapeSize / rectSize }
}