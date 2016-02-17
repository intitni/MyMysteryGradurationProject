//
//  SPLineGroup.swift
//  Sharpener
//
//  Created by Inti Guo on 1/14/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation

class SPLineGroup: SPGeometrics, SPCurveRepresentable {
    var type: SPGeometricType { return .Line }
    var lines = [SPCurve]()
}