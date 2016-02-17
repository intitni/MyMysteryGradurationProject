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
        case Rectangle(a: CGPoint, b: CGPoint, c: CGPoint, d: CGPoint)
        case Closed(closePoint: CGPoint)
        case RoundedRect(a: CGPoint, b: CGPoint, c: CGPoint, d: CGPoint, radius: CGFloat)
        case Polygon(points: [CGPoint])
        // case Symmetric(top: CGPoint, bottom: CGPoint)
    }
    
    var guessType: GuessType?
    
    var bezierPath: UIBezierPath {
        let path = UIBezierPath()
        
        return path
    }
}