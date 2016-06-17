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
        
        let curves = raw.borders.map { line in
            SPCurve(raw: line.raw)
        }
        
        curves.forEach { c in
            let shapeDetector = SPShapeDetector()
            c.guesses = shapeDetector.detect(c, inShape: true)
            let approx = SPBezierPathApproximator()
            approx.approximate(c)
        }
        
        shape.lines = curves
        
        return shape
    }
}