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
    var isHidden: Bool = false
    var raw = [CGPoint]()
    var lineSize: Int
    var shapeSize: Int
    var shapeWeight: Int { return shapeSize / (lineSize + shapeSize + 1) }
    var simplePath: UIBezierPath?
}
