//
//  SPShapeDetector.swift
//  Sharpener
//
//  Created by Inti Guo on 2/2/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation

class SPShapeDetector {
    var encloseCircleCenter = CGPointZero
    var encloseCircleRadius: CGFloat = 0
    var poleStart = CGPointZero
    var poleEnd = CGPointZero
    var poleStartIndex = 0
    var poleEndIndex = 0
    
    func detect(line: SPCurve, inShape: Bool) -> [SPGuess] {
        let guesses = [SPGuess]()
    
        return guesses
    }
    
    private func detectCircle(line: SPCurve) -> SPGuess? {
        let c = CGFloat(line.raw.count)
        let endurance: CGFloat = c / 2 / CGFloat(M_PI) * 0.1
        
        var raw = line.raw
        
        var max: CGFloat = 0
        var endA = CGPointZero, endB = CGPointZero
        
        for i in 0..<raw.count-1 {
            let p = raw[i]
            for j in i+1..<raw.count {
                let t = raw[j]
                let distance = p.distanceTo(t)
                if distance > max {
                    max = distance
                    endA = p
                    endB = t
                    poleStartIndex = i
                    poleEndIndex = j
                }
            }
        }
        
        let center = CGPoint.centerPointOf(endA, and: endB)
        let radius = max / 2
        
        var offset: CGFloat = 0
        var offsetCount: CGFloat = 0
        
        for p in line.raw {
            let deviation = center.distanceTo(p) - radius
            if deviation > endurance {
                offset += deviation
                offsetCount += 1
            }
        }
        
        encloseCircleCenter = center
        encloseCircleRadius = radius
        poleStart = endA
        poleEnd = endB
        
        offset /= offsetCount
        if offset > c * 0.2 {
            return nil
        }
        
        return SPGuess(guessType: .Circle(center: center, radius: radius))
    }
    
    private func detectRectangle(line: SPLine) -> SPGuess? {
        guard encloseCircleCenter != CGPointZero else { return nil }
        var maxLeft: CGFloat = 0, leftIndex: Int = 0
        var maxRight: CGFloat = 0, rightIndex: Int = 0
        let diagonalA = SPPolygonApproximator.Line(endA: poleStart, endB: poleEnd)
        
        for i in 0..<poleStartIndex {
            let p = line.raw[i]
            let distance = diagonalA.distanceToPoint(p)
            if distance > maxLeft {
                maxLeft = distance
                leftIndex = i
            }
        }
        for i in poleEndIndex+1..<line.raw.endIndex {
            let p = line.raw[i]
            let distance = diagonalA.distanceToPoint(p)
            if distance > maxLeft {
                maxLeft = distance
                leftIndex = i
            }
        }
        for i in poleStartIndex+1..<poleEndIndex {
            let p = line.raw[i]
            let distance = diagonalA.distanceToPoint(p)
            if distance > maxRight {
                maxRight = distance
                rightIndex = i
            }
        }
        
        let diagonalB = SPPolygonApproximator.Line(endA: line.raw[leftIndex], endB: line.raw[rightIndex])
        let diagonalALength = diagonalA.eruclideanDistance
        
        // Diagnol not equal or close enough
        guard diagonalALength - diagonalB.eruclideanDistance < diagonalALength * 0.05 else { return nil }
        
        let vAC = MXNFreeVector(start: poleStart, end: line.raw[leftIndex])
        let vAD = MXNFreeVector(start: poleStart, end: line.raw[rightIndex])
        let vBC = MXNFreeVector(start: poleEnd, end: line.raw[leftIndex])
        let vBD = MXNFreeVector(start: poleEnd, end: line.raw[rightIndex])
        
        let angleA = vAD.angleWith(vAC)
        let angleB = vBD.angleWith(vBC)
        let angleC = vAD.angleWith(vBD)
        let angleD = 360 - angleA - angleB - angleC
        
        // Angle not vertical
        if angleA > 100 || angleA < 80
        || angleB > 100 || angleB < 80
        || angleC > 100 || angleB < 80
        || angleD > 100 || angleB < 80 {
            return nil
        }
        
        var rawAD, rawAC, rawBC, rawCD: [CGPoint]
        for i in 0..<line.raw.endIndex {
            switch i {
            case poleStartIndex..<rightIndex:
                
            }
        }
    }
    
    private func detectStraight(line: SPCurve) -> SPGuess? {
        let endurance: CGFloat = 10
        
        guard let first = line.raw.first, let last = line.raw.last where first != last else { return nil }
        let a = (last.y - first.y) / (last.x - first.x)
        let b = first.y - a * first.x
        
        var deviation: CGFloat = 0
        
        for p in line.raw {
            deviation += p.y - a * p.y + b
        }
        deviation /= CGFloat(line.raw.count)
        if deviation > endurance { return nil }
        return SPGuess(guessType: .Straight(start: first, end: last))
    }
    
    private func detectPolygon(line: SPCurve) -> SPGuess {
        let c = CGFloat(line.raw.count)
        let approx = SPPolygonApproximator(threshold: c * 0.3)
        let points = approx.polygonApproximate(line.raw)
        
        return SPGuess(guessType: .Polygon(points: points))
    }
}