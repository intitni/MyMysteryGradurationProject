//
//  SPCurve.swift
//  Sharpener
//
//  Created by Inti Guo on 2/16/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation

class SPCurve {
    var raw: [CGPoint]
    var guesses = [SPGuess]()
    var applied: SPGuess?
    var preview: SPGuess?
    var vectorized = [SPAnchorPoint]()
    
    var smoothness: CGFloat = 0.36
    var farthestDistance: CGFloat?
    
    func appendRaw(point: CGPoint) { raw.append(point) }
    
    func appendVectorized(point: SPAnchorPoint) {
        guard vectorized.last?.anchorPoint != point.anchorPoint else { return }
        vectorized.append(point)
    }
    
    func appendCurve(curve: SPCurve) {
        if let last = vectorized.last, let first = curve.vectorized.first
            where last.anchorPoint == first.anchorPoint {
                vectorized.appendContentsOf(curve.vectorized.dropFirst(1))
        } else {
            vectorized.appendContentsOf(curve.vectorized)
        }
    }
    
    init(raw: [CGPoint] = []) {
        self.raw = raw
    }
    
    var bezierPath: UIBezierPath {
        if applied != nil {
            return applied!.bezierPath
        }
        
        let path = UIBezierPath()
        for (i, p) in vectorized.enumerate() {
            switch i {
            case 0:
                path==>p
            case vectorized.endIndex-1 where p.anchorPoint == vectorized.first?.anchorPoint:
                path-->|
            default:
                path~~>p
            }
        }
        return path
    }
    
    var previewBezierPath: UIBezierPath {
        if preview != nil {
            return preview!.bezierPath
        }
        
        let path = UIBezierPath()
        for (i, p) in vectorized.enumerate() {
            switch i {
            case 0:
                path==>p
            case vectorized.endIndex-1 where p.anchorPoint == vectorized.first?.anchorPoint:
                path-->|
            default:
                path~~>p
            }
        }
        return path
    }
    
    var shapeLayer: CAShapeLayer {
        let layer = CAShapeLayer()
        let path = bezierPath.CGPath
        layer.path = path
        layer.strokeColor = UIColor.spShapeColor().CGColor
        layer.lineWidth = 4
        layer.lineCap = kCALineCapRound
        layer.fillColor = UIColor.clearColor().CGColor
        
        return layer
    }
    
    var previewShapeLayer: CAShapeLayer {
        let layer = CAShapeLayer()
        let path = previewBezierPath.CGPath
        layer.path = path
        layer.strokeColor = UIColor.spShapeColor().CGColor
        layer.lineWidth = 4
        layer.lineCap = kCALineCapRound
        layer.fillColor = UIColor.clearColor().CGColor
        
        return layer
    }
}

func <--(inout left: SPCurve, right: CGPoint) {
    left.appendRaw(right)
}

func <--(inout left: SPCurve, right: SPAnchorPoint) {
    left.appendVectorized(right)
}

extension CGPoint {
    func rotateAround(ref: CGPoint, forDegree degree: CGFloat, clockWise: Bool = true) -> CGPoint {
        let rad = CGFloat(M_PI) / 180 * ( clockWise ? 360-degree : degree )
        let newX = (x-ref.x) * cos(rad) - (y-ref.y) * sin(rad) + ref.x
        let newY = (x-ref.x) * sin(rad) + (y-ref.y) * cos(rad) + ref.y
        return CGPoint(x: newX, y: newY)
    }
}