//
//  SPLine.swift
//  Sharpener
//
//  Created by Inti Guo on 1/14/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import UIKit

struct SPLine {
    var raw = [CGPoint]()
    var guesses = [SPGuess]()
    var applied: SPGuess? = nil
    var vectorized = [SPAnchorPoint]()
    
    init(raw: [CGPoint] = []) {
        self.raw = raw
    }
    
    mutating func appendVectorized(point: SPAnchorPoint) { vectorized.append(point) }
    mutating func appendRaw(point: CGPoint) { raw.append(point) }
}

func <--(inout left: SPLine, right: CGPoint) {
    left.appendRaw(right)
}

func <--(inout left: SPLine, right: SPAnchorPoint) {
    left.appendVectorized(right)
}

struct SPAnchorPoint: CustomStringConvertible {
    var anchorPoint: CGPoint
    var controlPointA: CGPoint?
    var controlPointB: CGPoint?
    
    init(point: CGPoint, controlPointA: CGPoint? = nil, controlPointB: CGPoint? = nil) {
        self.anchorPoint = point
        self.controlPointA = controlPointA
        self.controlPointB = controlPointB
    }
    
    var description: String {
        return "\(controlPointA) o- \(anchorPoint) -o \(controlPointB)"
    }
}

extension SPLine {
    var bezierPath: UIBezierPath {
        let path = UIBezierPath()
        for (i, p) in vectorized.enumerate() {
            switch i {
            case 0:
                path==>p
            default:
                path~~>p
            }
        }
        return path
    }
}