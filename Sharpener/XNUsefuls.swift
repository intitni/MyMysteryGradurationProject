//
//  XNUsefuls.swift
//  Sharpener
//
//  Created by Inti Guo on 1/17/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation
import UIKit

//  MARK: - UILabel Text Change Animation

extension UILabel {
    static var textChangeAnimation = CATransition() {
        didSet {
            textChangeAnimation.duration = 0.15;
            textChangeAnimation.type = kCATransitionFade;
        }
    }
    
    func setText(text: String, withAnimation: Bool) {
        if withAnimation {
            layer.addAnimation(UILabel.textChangeAnimation, forKey: "changeTextTransition")
            self.text = text
        } else {
            self.text = text
        }
    }
}


//  MARK: - UIBezierPath Operators

/// Move to
infix operator ==> { associativity left precedence 140 }
func ==>(path: UIBezierPath, point: CGPoint) -> UIBezierPath {
    path.moveToPoint(point)
    return path
}

/// Add line to
infix operator --> { associativity left precedence 140 }
func -->(path: UIBezierPath, point: CGPoint) -> UIBezierPath {
    path.addLineToPoint(point)
    return path
}

/// Add Curve to
infix operator ~~> { associativity left precedence 140 }
func ~~>(path: UIBezierPath, point: (anchorPoint: CGPoint, controlPoint1: CGPoint, controlPoint2: CGPoint)) -> UIBezierPath {
    path.addCurveToPoint(point.anchorPoint, controlPoint1: point.controlPoint1, controlPoint2: point.controlPoint2)
    return path
}

/// Close path
postfix operator -><- {}
postfix func -><-(path: UIBezierPath) {
    path.closePath()
}

// MARK: - CGPoint CGRect CGSize  Scaled Property

extension CGPoint {
    func scaled(scale: CGFloat) -> CGPoint {
        return CGPoint(x: x * scale, y: y * scale)
    }
}

extension CGRect {
    func scaled(scale: CGFloat) -> CGRect {
        return CGRect(x: origin.x * scale, y: origin.y * scale, width: width * scale, height: height * scale)
    }
}

extension CGSize {
    func scaled(scale: CGFloat) -> CGSize {
        return CGSize(width: width * scale, height: height * scale)
    }
}