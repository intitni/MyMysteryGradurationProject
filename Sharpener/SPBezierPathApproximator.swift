//
//  SPBezierPathApproximator.swift
//  Sharpener
//
//  Created by Inti Guo on 2/2/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation

class SPBezierPathApproximator {
    
    /// Deviation to endurance.
    var threshold: CGFloat { return 50 * smoothness + 1 }
    
    /// Smoothness of approximation, 0 to 1.
    var smoothness: CGFloat
    
    init(smoothness: CGFloat = 0.10) {
        self.smoothness = smoothness
    }
    
    /// Apply BezierPath approximation on given `SPCurve`,  and store vectorized results in `SPCurve.vectorized`.
    ///
    /// Process:
    /// 1. Smooth the line by Polygon approximation.
    /// 2. Using Polygon approximation to find feature points in the line, then split the line into seperate lines.
    /// 3. Apply BezierPath approximation on each.
    /// 4. If Deviation is smaller than threshold, we embrace the result. Or, we will find the point leading in deviation, and split the line according to it.
    /// 5. After fetching a new `SPCurve`, we append it to the old long one, and do a little bit angle correction to connect point to make it smooth.
    /// 
    /// - Parameter line: The `SPCurve` that needs to be approximated.`
    func approximate(line: SPCurve) {
        let curve = SPCurve(raw: line.raw)
        let raw = line.raw
        
        if line.farthestDistance == nil {
            line.farthestDistance = fetchFarthestDistanceFrom(line.raw)
        }
        line.smoothness = smoothness
        let splitedLines = [SPLine(raw: raw)]

        for line in splitedLines {
            let c = approximateSplittedLine(line)
            curve.appendCurve(c)
        }

        if let first = curve.vectorized.first, let last = curve.vectorized.last
        where first.anchorPoint == last.anchorPoint && curve.vectorized.count >= 3{
            let second = curve.vectorized[1]
            let newAnchorPoints = newAnchorPointsForLast(last, andNext: second)
            curve.vectorized[curve.vectorized.endIndex-1] = newAnchorPoints.last
            curve.vectorized[1] = newAnchorPoints.next
        }
        
        line.vectorized = curve.vectorized
    }
    
    private func fetchFarthestDistanceFrom(points: [CGPoint]) -> CGFloat {
        guard points.count >= 3 else { return 0 }
        let closed = points.last == points.first
        var manipPoints = closed ? points.dropLast(1) : points.dropLast(0)
        let line = SPPolygonApproximator.Line(endA: manipPoints.first!, endB: manipPoints.last!)
        var max: CGFloat = 0
        for i in 1..<manipPoints.endIndex-1 {
            let distance = line.distanceToPoint(manipPoints[i])
            if distance > max { max = distance }
        }
        return max
    }
    
    /// Used to split SPLine base on an array of points.
    /// - Parameters:
    ///     - x: line: The `SPLine` that needs to be approximated.
    ///     - points: The splitters.
    /// - Returns: A Array of splitted `SPLine`s
    private func splitSPLine(line: SPLine, accordingTo points: [CGPoint]) -> [SPLine] {
        var splittedLines = [SPLine]()
        var currentLine = SPLine()
        var currentSplitterIndex = 1
        for p in line.raw {
            currentLine <-- p
            if p == points[currentSplitterIndex] {
                if currentLine.raw.count >= 5 {
                    splittedLines.append(currentLine)
                    currentLine = SPLine()
                    currentLine <-- p
                }
                currentSplitterIndex += 1
            }
        }
        
        return splittedLines
    }
    
    /// Apply BezierPath approximation on given `SPLine`, returning a `SPCurve` with vectorized results stored in `SPCurve.vectorized`. Privately called in `approximate(line: SPLine) -> SPCurve`
    ///
    /// Process:
    /// 1. Create an array for future splittion.
    /// 2. Iterate through such array, if `deviation` is acceptable or `splitterIndex` is **not** valid, we embrace the result; if not, we seperate the line and put them in the right position in that array.
    ///
    /// - Parameter line: The `SPLine` that needs to be approximated.
    /// - Returns: A approximated result in `SPCurve`
    private func approximateSplittedLine(line: SPLine) -> SPCurve {
        guard line.raw.count >= 5 else {
            let s = SPCurve()
            s.vectorized = [SPAnchorPoint(point: line.raw.first!), SPAnchorPoint(point: line.raw.last!)]
            return s
        }
        guard line.raw.count >= 1 else {
            return SPCurve()
        }
        
        var curve = SPCurve()
        var splittedLines = [line]
        var manipIndex = 0
        
        while manipIndex < splittedLines.count {
            
            let raw = splittedLines[manipIndex].raw
            let v0 = raw.first!
            let v3 = raw.last!
            let (v1, v2) = vsForPoints(raw)
            let (deviation, splitterIndex) = deviationSumForPoints(raw, v0: v0, v1: v1, v2: v2, v3: v3)
            
            if deviation < threshold
            || !checkIfSplitterIndex(splitterIndex, isValidWhenLengthIs: raw.endIndex) {
                // accept
                let anchorPoint1 = SPAnchorPoint(point: v0)
                var anchorPoint2 = SPAnchorPoint(point: v3, controlPointA: v1, controlPointB: v2)
                
                if manipIndex > 0 {
                    // smooth the connection, and re-approximate the previous part of curve
                    if let last = curve.vectorized.last {
                        let (newLast, newNext) = newAnchorPointsForLast(last, andNext: anchorPoint2)
                        anchorPoint2 = newNext
                        curve.vectorized.removeLast()
                        curve <-- newLast
                    }
                }
                
                curve <-- anchorPoint1
                curve <-- anchorPoint2
                
                manipIndex += 1
            } else {
                // split again
                let (left, right) = splitSPLine(splittedLines[manipIndex], accordingTo: splitterIndex)
                splittedLines[manipIndex].raw = left.raw
                splittedLines.insert(right, atIndex: manipIndex+1)
            }
        }
        
        return curve
    }

    /// Fetch a new `AnchorPoint` with smoothed control points.
    private func newAnchorPointsForLast(point: SPAnchorPoint, andNext next: SPAnchorPoint) -> (last: SPAnchorPoint, next: SPAnchorPoint) {
        guard let controlPointA = point.controlPointB, let controlPointB = next.controlPointA else {
            return (point, next)
        }
        guard controlPointA != point.anchorPoint || controlPointB != point.anchorPoint else {
            return (point, next)
        }
        let vA = MXNFreeVector(start: point.anchorPoint, end: controlPointA)
        let vB = MXNFreeVector(start: point.anchorPoint, end: controlPointB)
        
        guard vA.angleWith(vB) > 140 else { return (point, next) }
        guard vA.absolute > point.anchorPoint.distanceTo(next.anchorPoint) || vB.absolute > point.anchorPoint.distanceTo(next.anchorPoint) else { return (point, next) }
        
        let xplus = MXNFreeVector(start: CGPointZero, end: CGPoint(x: 1, y: 0))
        var alpha = vA.angleWith(xplus)
        alpha = alpha > 90 ? 180 - alpha : alpha
        var beta = vB.angleWith(xplus)
        beta = beta > 90 ? 180 - beta : beta
        
        let theta = 180 - vA.angleWith(vB)
        let thetaB = theta * vA.absolute / (vA.absolute + vB.absolute)
        let thetaA = theta - thetaB
        
        let newControlPointA = controlPointA.rotateAround(point.anchorPoint, forDegree: thetaA, clockWise: alpha >= beta)
        let newControlPointB = controlPointB.rotateAround(point.anchorPoint, forDegree: thetaB, clockWise: beta > alpha)
        
        return (SPAnchorPoint(point: point.anchorPoint, controlPointA: point.controlPointA, controlPointB: newControlPointA),
            SPAnchorPoint(point: next.anchorPoint, controlPointA: newControlPointB, controlPointB: next.controlPointB))
    }
    
    /// Check if `splitterIndex` is valid. 
    ///
    /// To calculate v1 and v2, we need  **at least 2 points (excluding start and end)** in a `SPLine`.
    private func checkIfSplitterIndex(splitterIndex: Int, isValidWhenLengthIs length: Int) -> Bool {
        return splitterIndex > 3 && splitterIndex <= length-5
    }
    
    /// Used to split SPLine base on an index of point.
    /// - Parameters:
    ///     - x: line: The `SPLine` that needs to be approximated.
    ///     - index: The splitter's index.
    /// - Returns: The left and right lines splitted.
    private func splitSPLine(line: SPLine, accordingTo index: Int) -> (left: SPLine, right: SPLine) {
        var left = SPLine()
        var right = SPLine()
        
        for (i, p) in line.raw.enumerate() {
            switch i {
            case let x where x < index:
                left <-- p
            case let x where x == index:
                left <-- p
                right <-- p
            default:
                right <-- p
            }
        }
        
        return (left, right)
    }
    
    /// Calculate the Average deviation and the leading one's index for given points.
    private func deviationSumForPoints(points: [CGPoint],
        v0: CGPoint, v1: CGPoint, v2: CGPoint, v3: CGPoint) -> (deviation: CGFloat, farthestIndex: Int) {
            var sum: CGFloat = 0
            var farthestIndex = 0
            var max: CGFloat = 0
            var realMax: CGFloat = 0
            let count = points.count
            
            for i in 1..<count-2 {
                let position = CGFloat(i) / CGFloat(count-1)
                let d = deviationForPoint(points[i], at: position,
                    v0: v0, v1: v1, v2: v2, v3: v3)
                sum += d
                
                if d > max {
                    realMax = d
                    if checkIfSplitterIndex(i, isValidWhenLengthIs: count) {
                        farthestIndex = i
                        max = d
                    }
                }
            }
            return (realMax, farthestIndex)
    }
    
    /// Calculate the Average deviation for a point.
    private func deviationForPoint(point: CGPoint, at position: CGFloat,
        v0: CGPoint, v1: CGPoint, v2: CGPoint, v3: CGPoint) -> CGFloat {
            let q = argumentB(k: 0, forPosition: position) * v0
                  + argumentB(k: 1, forPosition: position) * v1
                  + argumentB(k: 2, forPosition: position) * v2
                  + argumentB(k: 3, forPosition: position) * v3
            let deviationPoint = q - point
            return pow(deviationPoint.x, 2) + pow(deviationPoint.y, 2)
    }
    
    /// Calculate the coordinates of V1 and V2 with fomular:
    /// 
    /// v1 = (a2*c1 - a12*c2) / (a1a2 - powa12); <br> v2 = (a1*c2 - a12*c1) / (a1a2 - powa12);
    private func vsForPoints(points: [CGPoint]) -> (v1: CGPoint, v2: CGPoint) {
        let count = points.count
        
        let a1 = argumentA(k: 1, forPointsCount: count)
        let a2 = argumentA(k: 2, forPointsCount: count)
        let a12 = argumentA12ForPointsCount(count)
        let c1 = argumentC(k: 1, forPoints: points)
        let c2 = argumentC(k: 2, forPoints: points)
        let a1a2 = a1*a2
        let powa12 = pow(a12, 2)
        
        assert(a1a2 - powa12 != 0, "a1a2 - powa12 = 0")
        
        let v1 = (a2*c1 - a12*c2) / (a1a2 - powa12)
        let v2 = (a1*c2 - a12*c1) / (a1a2 - powa12)
        
        return (v1, v2)
    }
    
    private func argumentA(k k: Int, forPointsCount count: Int) -> CGFloat {
        var a: CGFloat = 0
        for i in 1..<count-2 {
            let position = CGFloat(i) / CGFloat(count-1)
            a += pow(argumentB(k: k, forPosition: position), 2)
        }
        return a
    }
    
    private func argumentA12ForPointsCount(count: Int) -> CGFloat {
        var a: CGFloat = 0
        for i in 1..<count-2 {
            let position = CGFloat(i) / CGFloat(count-1)
            a += argumentB(k: 1, forPosition: position) * argumentB(k: 2, forPosition: position)
        }
        return a
    }
    
    private func argumentC(k k: Int, forPoints points: [CGPoint]) -> CGPoint {
        let count = points.count
        var c: CGPoint = CGPointZero
        for i in 1..<count-2 {
            let position = CGFloat(i) / CGFloat(count-1)
            c = c + (argumentB(k: k, forPosition: position) * (points[i] - argumentB(k: 0, forPosition: position)*points[0] - argumentB(k: 3, forPosition: position)*points[count-1]))
        }
        return c
    }
    
    private func argumentB(k k: Int, forPosition position: CGFloat) -> CGFloat {
        var m: CGFloat = 1
        if k == 1 || k == 2 {
            m = 3
        }
        return pow(position, CGFloat(k)) * pow(1-position, CGFloat(3-k)) * m
    }
}


func *(left: CGFloat, right: CGPoint) -> CGPoint {
    return CGPoint(x: left * right.x, y: left * right.y)
}

func /(left: CGPoint, right: CGFloat) -> CGPoint {
    return CGPoint(x: left.x / right, y: left.y / right)
}

func -(left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x-right.x, y: left.y-right.y)
}

func +(left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x+right.x, y: left.y+right.y)
}