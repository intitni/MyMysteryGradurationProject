//
//  SPLine.swift
//  Sharpener
//
//  Created by Inti Guo on 1/14/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import CoreGraphics
import UIKit

protocol SPLineRepresentable {
    var representingLines: [SPLine] { get }
    var bezierPath: UIBezierPath { get }
}

extension SPLineRepresentable {
    var bezierPath: UIBezierPath {
        let path = UIBezierPath()
        representingLines.forEach { border in
            path.appendPath(border.bezierPath)
        }
        return path
    }
}

struct SPLine {
    enum Guess {
        case Straight(start: CGPoint, end: CGPoint)
        case PartialStraight(straightLines: [(startIndex: Int, endIndex: Int)])
        case Circle(center: CGPoint, radius: CGFloat)
        case Triangle(a: CGPoint, b: CGPoint, c: CGPoint)
        case Rectangle(a: CGPoint, b: CGPoint, c: CGPoint, d: CGPoint)
        case Closed(on: CGPoint)
        case RoundedRect(a: CGPoint, b: CGPoint, c: CGPoint, d: CGPoint, radius: CGFloat)
        case Symmetric(top: CGPoint, bottom: CGPoint)
    }
    
    var raw = [CGPoint]()
    var guesses = [Guess]()
    var applied = [Guess]()
    var vectorized = [SPAnchorPoint]()
    mutating func appendVectorized(point: SPAnchorPoint) { vectorized.append(point) }
    mutating func appendRaw(point: CGPoint) { raw.append(point) }
}

func <--(inout left: SPLine, right: CGPoint) {
    left.appendRaw(right)
}

func <--(inout left: SPLine, right: SPAnchorPoint) {
    left.appendVectorized(right)
}

struct SPAnchorPoint {
    var anchorPoint: CGPoint
    var controlPointA: CGPoint?
    var controlPointB: CGPoint?
    
    init(point: CGPoint) {
        self.anchorPoint = point
    }
}

extension SPLine {
    var bezierPath: UIBezierPath {
        let path = UIBezierPath()
        for (i, p) in vectorized.enumerate() {
            switch i {
            case 0:
                path==>p
            case vectorized.endIndex where p.anchorPoint == vectorized.first?.anchorPoint:
                path-><-
            default:
                path~~>p
            }
        }
        return path
    }
}