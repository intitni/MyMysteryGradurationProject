//
//  SPGuess.swift
//  Sharpener
//
//  Created by Inti Guo on 2/16/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation

class SPGuess {
    
    enum GuessType {
        case Straight(start: CGPoint, end: CGPoint)
        // case PartialStraight(straightLines: [(startIndex: Int, endIndex: Int)])
        case Circle(center: CGPoint, radius: CGFloat)
        case Rectangle(center: CGPoint, height: CGFloat, width: CGFloat, rotation: CGFloat, radius: CGFloat)
        case Closed(closeStartIndex: Int, closeEndIndex: Int)
        case RoundedRect(center: CGPoint, height: CGFloat, width: CGFloat, rotation: CGFloat, radius: CGFloat)
        case Polygon(points: [CGPoint])
        // case Symmetric(top: CGPoint, bottom: CGPoint)
    }
    
    var guessType: GuessType?
    
    init(guessType: GuessType) {
        self.guessType = guessType
    }
    
    var bezierPath: UIBezierPath {
        var path = UIBezierPath()
        
        switch guessType! {
        case .Straight(start: let x, end: let y):
            path ==> x
            path --> y
        case .Circle(center: let c, radius: let r):
            path = UIBezierPath(ovalInRect: CGRect(x: c.x-r, y: c.y-r, width: 2*r, height: 2*r))
        case .Rectangle(center: let c, height: let h, width: let w, rotation: let r, radius: let rd):
            break
        case .Polygon(points: let ps):
            for (i, pt) in ps.enumerate() {
                if i == 0 { path ==> pt }
                else { path --> pt }
            }
            if ps.last == ps.first {
                path-->|
            }
        default: break
        }
        
        return path
    }
    
    var description: String {
        guard guessType != nil else { return "" }
        switch self.guessType! {
        case .Straight:
            return "Straight Line"
        case .Circle:
            return "Circle"
        case .Rectangle:
            return "Rectangle"
        case .Closed:
            return "Closed"
        case .RoundedRect:
            return "Rounded Rectangle"
        case .Polygon:
            return "Polygon"
        }
    }
}