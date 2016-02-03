//
//  SPLineGroup.swift
//  Sharpener
//
//  Created by Inti Guo on 1/14/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation

struct SPLineGroup: SPGeometrics, SPLineRepresentable {
    var type: SPGeometricType { return .Line }
    var lines = [SPLine]()
}