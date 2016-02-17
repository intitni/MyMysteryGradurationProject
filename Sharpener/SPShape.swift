//
//  SPShape.swift
//  Sharpener
//
//  Created by Inti Guo on 1/14/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation

class SPShape: SPGeometrics, SPCurveRepresentable {
    var type: SPGeometricType { return .Shape }
    var lines = [SPCurve]()
}