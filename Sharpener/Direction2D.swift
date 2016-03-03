//
//  Direction2D.swift
//  Sharpener
//
//  Created by Inti Guo on 3/3/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import CoreGraphics

enum Direction2D {
    case Up, Down, Left, Right
    case North, South, West, East
    
    case UpLeft, DownLeft, UpRight, DownRight
    case Northwest, Southwest, Northeast, Southeast
    
    case Clockwise(degree: Double)
    case CounterClockwise(degree: Double)
    
    case Pole(vector: MXNFreeVector)
    
    /// Returns the stored value of .Pole, 0 Vector if it's not .Pole.
    var poleValue: MXNFreeVector {
        if case .Pole(let x) = self {
            return x
        }
        return MXNFreeVector(x: 0, y: 0)
    }
}


/// A free vector indicating direction and length.
struct MXNFreeVector: Equatable {
    var x: CGFloat
    var y: CGFloat
    
    static var zero: MXNFreeVector { return MXNFreeVector(x: 0, y: 0) }
    
    var absolute: CGFloat {
        return sqrt(x*x+y*y)
    }
    
    /// Returns a normalized vector of self.
    var normalized: MXNFreeVector {
        if absolute == 0 { return MXNFreeVector(x: 0, y: 0) }
        let newX = x / absolute
        let newY = y / absolute
        return MXNFreeVector(x: newX, y: newY)
    }
    
    /// Getting the Direction2D of it.
    var direction: Direction2D { return .Pole(vector: self) }
    
    init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
    }
    
    init(start: CGPoint, end: CGPoint) {
        x = end.x - start.x
        y = end.y - start.y
    }
    
    /// Calculate the angle between self and another free vector.
    /// - Returns: Angle in degree.
    func angleWith(another: MXNFreeVector) -> CGFloat {
        return MXNFreeVector.angleBetween(self, vectorB: another)
    }
    
    static func angleBetween(vectorA: MXNFreeVector, vectorB: MXNFreeVector) -> CGFloat {
        let cosValue = (vectorA • vectorB) / (vectorA.absolute * vectorB.absolute)
        return acos(cosValue) * 180 / CGFloat(M_PI)
    }
    
    var isZeroVector: Bool {
        if x == 0 && y == 0 {
            return true
        }
        return false
    }
}





// MARK: - Operators

func *(left: MXNFreeVector, right: CGFloat) -> MXNFreeVector {
    return MXNFreeVector(x: left.x * right, y: left.y * right)
}

func +(left: MXNFreeVector, right: MXNFreeVector) -> MXNFreeVector {
    return MXNFreeVector(x: left.x + right.x, y: left.y + right.y)
}

func +(left: CGPoint, right: MXNFreeVector) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func ==(left: MXNFreeVector, right: MXNFreeVector) -> Bool {
    if left.x == right.x && left.y == right.y {
        return true
    }
    return false
}

/// Inner production of two MXNFreeVectors
func •(left: MXNFreeVector, right: MXNFreeVector) -> CGFloat {
    return left.x * right.x + left.y * right.y
}

prefix func -(right: MXNFreeVector) -> MXNFreeVector {
    return MXNFreeVector(x: -right.x, y: -right.y)
}


// MARK: - Int
extension Int {
    var normalizedVector: MXNFreeVector {
        let y = sin(CGFloat(self) * CGFloat(M_PI) / 180)
        let x = cos(CGFloat(self) * CGFloat(M_PI) / 180)
        return MXNFreeVector(x: x, y: y)
    }
}

// MARK: - CGPoint
extension CGPoint  {
    var right: CGPoint     { return CGPoint(x: self.x + 1, y: self.y) }
    var left: CGPoint      { return CGPoint(x: self.x - 1, y: self.y) }
    var up: CGPoint        { return CGPoint(x: self.x, y: self.y - 1) }
    var down: CGPoint      { return CGPoint(x: self.x, y: self.y + 1) }
    
    var upleft: CGPoint    { return CGPoint(x: self.x - 1, y: self.y - 1) }
    var downleft: CGPoint  { return CGPoint(x: self.x + 1, y: self.y - 1) }
    var upright: CGPoint   { return CGPoint(x: self.x - 1, y: self.y + 1) }
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
    
    func pointAt(direction: Direction2D) -> CGPoint {
        switch direction {
        case .Up:        return self.up
        case .Down:      return self.down
        case .Left:      return self.left
        case .Right:     return self.right
        case .UpLeft:    return self.upleft
        case .DownLeft:  return self.downleft
        case .UpRight:   return self.upright
        case .DownRight: return self.downright
        default:         return self
        }
    }
    
    static func horizontalRangeFrom(pointA: CGPoint, to pointB: CGPoint) -> Range<Int> {
        return Int(pointA.x)...Int(pointB.x)
    }
    
    func nearbyPointIn(points: [CGPoint], clockwise: Bool) -> CGPoint? {
        var directions = [Direction2D]()
        if clockwise {
            directions = [.Up, .UpRight, .Right, .DownRight, .Down, .DownLeft, .Left, .UpLeft]
        } else {
            directions = [.Up, .UpLeft, .Left, .DownLeft, .Down, .DownRight, .Right, .UpRight]
        }
        
        for d in directions {
            let p = pointAt(d)
            if points.contains(p) {
                return pointAt(d)
            }
        }
        return nil
    }
    
    var isIntegerPoint: Bool {
        return self.x.isInteger && self.y.isInteger
    }
    
    func distancePow2To(point: CGPoint) -> CGFloat {
        let x2 = pow(point.x - x, 2)
        let y2 = pow(point.y - y, 2)
        return x2 + y2
    }
    
    func distanceTo(point: CGPoint) -> CGFloat {
        return sqrt(distancePow2To(point))
    }
    
    func interpolateTowards(direction: MXNFreeVector, forward: Bool) -> CGPoint {
        let newX = x + (forward ? direction.x : -direction.x)
        let newY = y + (forward ? direction.y : -direction.y)
        return CGPoint(x: newX, y: newY)
    }
    
    func interpolateSemiTowards(direction: MXNFreeVector, forward: Bool) -> CGPoint {
        let newDirection = MXNFreeVector(x: direction.x/2, y: direction.y/2)
        return interpolateTowards(newDirection, forward: forward)
    }
    
    static func centerPointOf(one: CGPoint, and another: CGPoint) -> CGPoint {
        return CGPoint(x: (one.x+another.x)/2, y: (one.y+another.y)/2)
    }
}
