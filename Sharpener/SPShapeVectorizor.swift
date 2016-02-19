//
//  SPShapeVectorizor.swift
//  Sharpener
//
//  Created by Inti Guo on 1/28/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation

class SPShapeVectorizor {
    
    /// It use bezierpath-approximation to vectorize a SPRawGeometric
    func vectorize(raw: SPRawGeometric) -> SPShape {
        let shape = SPShape()
        
        let curves = raw.borders.map { line -> SPCurve in
            let curve = SPCurve(raw: line.raw)
            return curve
        }
        
        curves.forEach { c in
            let shapeDetector = SPShapeDetector()
            let guesses = shapeDetector.detect(c, inShape: false)
            c.guesses = guesses
            let approx = SPBezierPathApproximator()
            approx.approximate(c)
        }
        
        shape.lines = curves
        
        return shape
    }
}