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
    var threshold: CGFloat = 10
    
    /// Apply BezierPath approximation on given `SPLine`, returning a `SPCurve` with vectorized results stored in `SPCurve.vectorized`.
    ///
    /// Process:
    /// 1. Using Polygon approximation to find feature points in the line, then split the line into seperate lines.
    /// 2. Apply BezierPath approximation on each.
    /// 3. If Deviation is smaller than threshold, we embrace the result. Or, we will find the point leading in deviation, and split the line according to it.
    /// 4. After fetching a new `SPCurve`, we append it to the old long one, and do a little bit angle correction to connect point to make it smooth.
    /// 
    /// - Parameter line: The `SPLine` that needs to be approximated.
    /// - Returns: A approximated result in `SPCurve`
    func approximate(line: SPLine) -> SPCurve {
        let curve = SPCurve(raw: line.raw)
        
        // 1. polygon approximation and split!
        let polyApprox = SPPolygonApproximator(threshold: 5)
        let splitors = polyApprox.polygonApproximate(line.raw)
        let splitedLines = splitSPLine(line, accordingTo: splitors)
        
        // 2. approximate every line
        for line in splitedLines {
            let c = approximateSplittedLine(line)
            curve.appendCurve(c)
        }
        
        return curve
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
                splittedLines.append(currentLine)
                currentLine = SPLine()
                currentLine <-- p
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
        guard line.raw.count >= 2 else {
            let s = SPCurve(raw: [])
            s.vectorized = [SPAnchorPoint(point: line.raw.first!), SPAnchorPoint(point: line.raw.last!)]
            return s
        }
        guard line.raw.count >= 1 else {
            return SPCurve(raw: [])
        }
        
        var curve = SPCurve(raw: [])
        var splittedLines = [line]
        var manipIndex = 0
        
        while manipIndex < splittedLines.count {
            let raw = splittedLines[manipIndex].raw
            let v0 = raw.first!
            let v3 = raw.last!
            let (v1, v2) = vsForPoints(raw)
            let (deviation, splitterIndex) = deviationSumForPoints(raw, v0: v0, v1: v1, v2: v2, v3: v3)
            
            if deviation < threshold || checkIfSplitterIndex(splitterIndex, isValidWhenLengthIs: raw.endIndex) {
                // Accept!
                let anchorPoint1 = SPAnchorPoint(point: v0)
                let anchorPoint2 = SPAnchorPoint(point: v3, controlPointA: v1, controlPointB: v2)
                
                curve <-- anchorPoint1
                curve <-- anchorPoint2
                
                manipIndex += 1
            } else {
                // Split!
                let (left, right) = splitSPLine(splittedLines[manipIndex], accordingTo: splitterIndex)
                splittedLines[manipIndex].raw = left.raw
                splittedLines.insert(right, atIndex: manipIndex+1)
            }
        }
        
        return curve
    }
    
    /// Check if `splitterIndex` is valid. 
    ///
    ///To calculate v1 and v2, we need  **at least 2 points (excluding start and end)** in a `SPLine`.
    private func checkIfSplitterIndex(splitterIndex: Int, isValidWhenLengthIs length: Int) -> Bool {
        return splitterIndex <= 2 || splitterIndex > length-4
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
            let count = points.count
            for i in 1..<count-2 {
                let position = CGFloat(i) / CGFloat(count-1)
                let d = deviationForPoint(points[i], at: position,
                    v0: v0, v1: v1, v2: v2, v3: v3)
                sum += d
                
                if d > max {
                    farthestIndex = i
                    max = d
                }
            }
            
            return (sum, farthestIndex)
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