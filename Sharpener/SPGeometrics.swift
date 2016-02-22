//
//  SPGeometrics.swift
//  Sharpener
//
//  Created by Inti Guo on 1/14/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation
import MetalKit


enum SPGeometricType {
    case Shape, Line
}

// MARK: - SPGeometrics
protocol SPGeometrics: class {
    var type: SPGeometricType { get }
    var lines: [SPCurve] { get set }
}

// MARK: - For All SPGeometrics
extension SPGeometrics {
    var geometric: SPGeometrics { return self }
}

// MARK: - Where SPLineRepresentable
extension SPGeometrics where Self: SPCurveRepresentable {
    var representingLines: [SPCurve] { return lines }
    var fillColor: UIColor {
        switch type {
        case .Shape:
            return UIColor.spShapeColor()
        case .Line:
            return UIColor.spLineColor()
        }
    }
}

func <--(inout left: SPGeometrics, right: SPCurve) {
    left.lines.append(right)
}


