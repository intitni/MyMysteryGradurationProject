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
    
    /// CAShapeLayer made up of bezierPath.
    var shapeLayer: CAShapeLayer {
        let layer = CAShapeLayer()
        
        layer.path = bezierPath.CGPath
        layer.strokeColor = fillColor.CGColor
        layer.fillColor = UIColor.clearColor().CGColor
        layer.lineWidth = 4
        layer.backgroundColor = UIColor.clearColor().CGColor
        
        return layer
    }
    
    var shapeLayerPure: CAShapeLayer {
        let layer = CAShapeLayer()
        layer.path = bezierPath.CGPath
        layer.strokeColor = UIColor.spOutlineColor().CGColor
        layer.fillColor = UIColor.clearColor().CGColor
        layer.lineWidth = 4
        layer.lineCap = kCALineCapRound
        layer.backgroundColor = UIColor.clearColor().CGColor
        
        return layer
    }
    
    var previewShapeLayer: CAShapeLayer {
        let layer = CAShapeLayer()
        layer.path = previewBezierPath.CGPath
        layer.strokeColor = UIColor.spOutlineColor().CGColor
        layer.fillColor = UIColor.clearColor().CGColor
        layer.lineWidth = 4
        layer.lineCap = kCALineCapRound
        layer.backgroundColor = UIColor.clearColor().CGColor
        
        return layer
    }
}