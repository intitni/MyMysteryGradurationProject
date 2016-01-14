//
//  SPShape.swift
//  Sharpener
//
//  Created by Inti Guo on 1/14/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation

struct SPShape: SPGeometrics {
    var type: SPGeometricType { return .Shape }
    var lines = [SPLine]()
}