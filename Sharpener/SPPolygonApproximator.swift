//
//  SPPolygonApproximator.swift
//  Sharpener
//
//  Created by Inti Guo on 1/27/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import UIKit

class SPPolygonApproximator {
    
    /// If distance if longer than or equal to threshold, such point should be a characteristic point of line.
    var threshold: CGFloat
    
    init(threshold: CGFloat) {
        self.threshold = threshold
    }
    
    /// It apply polygon-approximation *(Douglas–Peucker algorithm non-recursive)* on the raw values of a SPLine and 
    /// then put the polygon-approximated ones in SPLine's vectorized.
    func polygonApproximateSPLine(inout line: SPLine) {
        line.vectorized = polygonApproximate(line.raw).map { SPAnchorPoint(point: $0) }
    }
    
    /// It apply polygon-approximation *(Douglas–Peucker algorithm non-recursive)* on an array of CGPoint and returns the result.
    func polygonApproximate(points: [CGPoint]) -> [CGPoint] {
        let closed = points.last == points.first
        var manipPoints = (closed ? points.dropLast(1) : points.dropLast(0)).map {
            FeaturePoint(point: $0)
        }
        
        var stack = Stack(storage: [Int]())
        
        var endA: Int? = manipPoints.startIndex
        var endB: Int? = manipPoints.endIndex - 1
        manipPoints[endA!].isFeaturePoint = true
        manipPoints[endB!].isFeaturePoint = true
        stack.push(endB!)
        
        repeat {
            guard endA != nil && endB != nil else { break }
            let line = Line(endA: manipPoints[endA!].point, endB: manipPoints[endB!].point)
            guard let index = farthestPointForLine(line, indexA: endA!, indexB: endB!, manipPoints: &manipPoints) else {
                endA = stack.pop()
                endB = stack.top
                continue
            }
            if manipPoints[index].distance >= threshold {
                manipPoints[index].isFeaturePoint = true
                endB = index
                stack.push(index)
            } else {
                endA = stack.pop()
                endB = stack.top
            }
        } while !stack.isEmpty
        
        
        if manipPoints.count < points.count {
            manipPoints.append(manipPoints.first!)
        }
        
        var newPoints = manipPoints.filter { point in
            point.isFeaturePoint
        }.map { point in
            point.point
        }
        
        if closed && newPoints.first != nil {
            newPoints.append(newPoints.first!)
        }
        
        return newPoints
    }
    
    /// Find the farthest point in manipPoints to given line, returning the index of it.
    /// - parameter line: The line to calculate
    /// - returns: The index of the point in manipPoints. If no point sits between, returns nil.
    func farthestPointForLine(line: Line, indexA: Int, indexB: Int, inout manipPoints: [FeaturePoint] ) -> Int? {
        guard abs(indexA - indexB) > 1 else { return nil }
        var index = 0
        var max: CGFloat = 0
        let ra = indexA < indexB ? indexA : indexB
        let rb = indexA >= indexB ? indexA : indexB
        for i in ra+1..<rb {
            manipPoints[i].distance = line.distanceToPoint(manipPoints[i].point)
            if manipPoints[i].distance > max {
                index = i
                max = manipPoints[i].distance
            }
        }
        
        return index == 0 ? nil : index
    }
    
    
    // MARK: Internal Structs
    
    struct FeaturePoint {
        let point: CGPoint
        var isFeaturePoint: Bool
        var distance: CGFloat
        init(point: CGPoint) {
            self.point = point
            isFeaturePoint = false
            distance = 0
        }
    }
    
    struct Line {
        var endA: CGPoint
        var endB: CGPoint
        
        /// The denominator aka the length of line.
        var eruclideanDistance: CGFloat
        
        init(endA: CGPoint, endB: CGPoint) {
            self.endA = endA
            self.endB = endB
            let denominator = pow((self.endB.y - self.endA.y), 2)
                            + pow((self.endA.x - self.endB.x), 2)
            eruclideanDistance = sqrt(denominator)
        }
        
        /// For distance between point(x,y) and line((a,b)->(c,d)) should be <br> **|(d-b)x + (a-c)y + cb - ad| / √((d-b)^2 + (a-c)^2)**.
        func distanceToPoint(point: CGPoint) -> CGFloat {
            let numerator = (endB.y - endA.y) * point.x + (endA.x - endB.x) * point.y
                          + endB.x * endA.y - endA.x * endB.y
            return abs(numerator) / eruclideanDistance
        }
    }
}