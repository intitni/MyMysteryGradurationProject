//
//  CGPoint+Sharpener.swift
//  Sharpener
//
//  Created by Inti Guo on 1/19/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation
import CoreGraphics

extension CGPoint  {
    var right: CGPoint { return CGPoint(x: self.x + 1, y: self.y) }
    var left: CGPoint { return CGPoint(x: self.x - 1, y: self.y) }
    var up: CGPoint { return CGPoint(x: self.x, y: self.y - 1) }
    var down: CGPoint { return CGPoint(x: self.x, y: self.y + 1) }
    
    var upleft: CGPoint { return CGPoint(x: self.x - 1, y: self.y - 1) }
    var downleft: CGPoint { return CGPoint(x: self.x + 1, y: self.y - 1) }
    var upright: CGPoint { return CGPoint(x: self.x - 1, y: self.y + 1) }
    var downright: CGPoint { return CGPoint(x: self.x + 1, y: self.y + 1) }
    
    /// Move this point 1pt away to given Direction2D.
    /// > Up, Down, Left, Right, and their combinations are supported.
    mutating func move(direction: Direction2D) {
        switch direction {
        case .Up:        self.y -= 1
        case .Down:      self.y += 1
        case .Left:      self.x -= 1
        case .Right:     self.x += 1
        case .UpLeft:    self.x -= 1; self.y -= 1
        case .DownLeft:  self.x += 1; self.y -= 1
        case .UpRight:   self.x -= 1; self.y += 1
        case .DownRight: self.x += 1; self.y += 1
        default: break
        }
    }
    
    static func horizontalRangeFrom(pointA: CGPoint, to pointB: CGPoint) -> Range<Int> {
        return Int(pointA.x)...Int(pointB.x)
    }
}

enum Direction2D {
    case Up, Down, Left, Right
    case North, South, West, East
    
    case UpLeft, DownLeft, UpRight, DownRight
    case Northwest, Southwest, Northeast, Southeast
    
    case Clockwise(degree: Double)
    case CounterClockwise(degree: Double)
}