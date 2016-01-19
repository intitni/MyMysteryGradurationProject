//
//  UIBezierPath+Sharpener.swift
//  Sharpener
//
//  Created by Inti Guo on 1/19/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation
import UIKit

/// Move to
infix operator ==> { associativity left precedence 140 }
func ==>(path: UIBezierPath, point: SPAnchorPoint) -> UIBezierPath {
    path.moveToPoint(point.anchorPoint)
    return path
}

/// Add line to
infix operator --> { associativity left precedence 140 }
func -->(path: UIBezierPath, point: SPAnchorPoint) -> UIBezierPath {
    path.addLineToPoint(point.anchorPoint)
    return path
}

/// Add Curve to
infix operator ~~> { associativity left precedence 140 }
func ~~>(path: UIBezierPath, point: SPAnchorPoint) -> UIBezierPath {
    path.addCurveToPoint(point.anchorPoint, controlPoint1: point.controlPointA ?? point.anchorPoint, controlPoint2: point.controlPointB ?? point.anchorPoint)
    return path
}

/// Close path
postfix operator -><- {}
postfix func -><-(path: UIBezierPath) {
    path.closePath()
}

/// Move to
func ==>(path: UIBezierPath, point: CGPoint) -> UIBezierPath {
    path.moveToPoint(point)
    return path
}

/// Add line to
func -->(path: UIBezierPath, point: CGPoint) -> UIBezierPath {
    path.addLineToPoint(point)
    return path
}

/// Add Curve to
func ~~>(path: UIBezierPath, point: (anchorPoint: CGPoint, controlPoint1: CGPoint, controlPoint2: CGPoint)) -> UIBezierPath {
    path.addCurveToPoint(point.anchorPoint, controlPoint1: point.controlPoint1, controlPoint2: point.controlPoint2)
    return path
}