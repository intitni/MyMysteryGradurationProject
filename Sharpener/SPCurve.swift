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
    var applied: SPGuess? = nil
    var vectorized = [SPAnchorPoint]()
    func appendRaw(point: CGPoint) { raw.append(point) }
    
    func appendVectorized(point: SPAnchorPoint) {
        guard vectorized.last?.anchorPoint != point.anchorPoint else { return }
        vectorized.append(point)
    }
    
    func appendCurve(curve: SPCurve) {
        if let last = vectorized.last, let first = curve.vectorized.first
            where last.anchorPoint == first.anchorPoint {
                vectorized.appendContentsOf(curve.vectorized.dropFirst())
        } else {
            vectorized.appendContentsOf(curve.vectorized)
        }
    }
    
    private func newAnchorPointFor(point: SPAnchorPoint) -> SPAnchorPoint {
        guard let controlPointA = point.controlPointA, let controlPointB = point.controlPointB else {
            return point
        }
        guard point.controlPointA == point.anchorPoint || point.controlPointB == point.anchorPoint else {
            return point
        }
        let vA = MXNFreeVector(start: point.anchorPoint, end: controlPointA)
        let vB = MXNFreeVector(start: point.anchorPoint, end: controlPointB)
        
        guard vA.angleWith(vB) > 90 else { return point }
        
        let xplus = MXNFreeVector(start: CGPointZero, end: CGPoint(x: 1, y: 0))
        var alpha = vA.angleWith(xplus)
        alpha = alpha > 180 ? alpha - 180 : alpha
        var beta = vB.angleWith(xplus)
        beta = beta > 180 ? beta - 180 : beta
        
        let theta = 180 - vA.angleWith(vB)
        let thetaA = theta * vA.absolute / (vA.absolute + vB.absolute)
        let thetaB = theta - thetaA
        
        let newControlPointA = controlPointA.rotateAround(point.anchorPoint, forDegree: thetaA, clockWise: thetaA >= thetaB)
        let newControlPointB = controlPointB.rotateAround(point.anchorPoint, forDegree: thetaB, clockWise: thetaB > thetaA)
        
        return SPAnchorPoint(point: point.anchorPoint, controlPointA: newControlPointA, controlPointB: newControlPointB)
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
                path~~>p
            case vectorized.endIndex where p.anchorPoint == vectorized.first?.anchorPoint:
                path-><-
            default:
                path~~>p
            }
        }
        return path
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
        let newY = (x-ref.x) * sin(rad) - (y-ref.y) * cos(rad) + ref.y
        return CGPoint(x: newX, y: newY)
    }
}