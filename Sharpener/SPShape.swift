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
    
    /// CAShapeLayer made up of bezierPath.
    var shapeLayer: CAShapeLayer {
        let layer = CAShapeLayer()
        
        layer.path = bezierPath.CGPath
        layer.fillRule = kCAFillRuleEvenOdd
        layer.fillColor = fillColor.CGColor
        layer.backgroundColor = UIColor.clearColor().CGColor
        
        return layer
    }
    
    var shapeLayerPure: CAShapeLayer {
        let layer = CAShapeLayer()
        
        let path = bezierPath.CGPath
        layer.path = path
        layer.fillRule = kCAFillRuleEvenOdd
        layer.fillColor = UIColor.spOutlineColor().CGColor
        layer.backgroundColor = UIColor.clearColor().CGColor
        
        return layer
    }
    
    var previewShapeLayer: CAShapeLayer {
        let layer = CAShapeLayer()
        
        let path = previewBezierPath.CGPath
        layer.path = path
        layer.fillRule = kCAFillRuleEvenOdd
        layer.fillColor = UIColor.spOutlineColor().CGColor
        layer.backgroundColor = UIColor.clearColor().CGColor
        
        return layer
    }
}