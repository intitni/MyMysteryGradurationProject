//
//  SPLineRepresentable.swift
//  Sharpener
//
//  Created by Inti Guo on 2/1/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import UIKit

protocol SPLineRepresentable {
    var representingLines: [SPLine] { get }
    var bezierPath: UIBezierPath { get }
    var shapeLayer: CAShapeLayer { get }
    var fillColor: UIColor { get }
}

extension SPLineRepresentable {
    /// UIBezierPath made up of SPLines.
    var bezierPath: UIBezierPath {
        let path = UIBezierPath()
        representingLines.forEach { border in
            path.appendPath(border.bezierPath)
        }

        return path
    }

    /// CAShapeLayer made up of bezierPath.
    var shapeLayer: CAShapeLayer {
        let layer = CAShapeLayer()
        
        layer.path = bezierPath.CGPath
        layer.fillRule = kCAFillRuleEvenOdd
        layer.fillColor = fillColor.CGColor
        layer.backgroundColor = UIColor.blackColor().CGColor

        return layer
    }
}

protocol SPCurveRepresentable {
    var representingLines: [SPCurve] { get }
    var bezierPath: UIBezierPath { get }
    var shapeLayer: CAShapeLayer { get }
    var fillColor: UIColor { get }
}

extension SPCurveRepresentable {
    /// UIBezierPath made up of SPLines.
    var bezierPath: UIBezierPath {
        let path = UIBezierPath()
        representingLines.forEach { border in
            path.appendPath(border.bezierPath)
        }
        
        return path
    }
    
    /// CAShapeLayer made up of bezierPath.
    var shapeLayer: CAShapeLayer {
        let layer = CAShapeLayer()
        
        layer.path = bezierPath.CGPath
        layer.fillRule = kCAFillRuleEvenOdd
        layer.fillColor = fillColor.CGColor
        layer.backgroundColor = UIColor.blackColor().CGColor
        
        return layer
    }
}

