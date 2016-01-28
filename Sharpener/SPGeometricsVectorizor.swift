//
//  SPGeometricsVectorizor.swift
//  Sharpener
//
//  Created by Inti Guo on 1/19/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation

/// SPGeometricsVectorizor is used to generate vectorized SPGeometrics from SPRawGeometrics storing in universalGeometricsStore.
///
/// It's devided into two parts:
/// 1. SPShapeVectorizor: It firstly uses **polygon-approximation** to simplifies the borders of a shape, than apply **bezierpath-approximation** on them
/// 2. SPLineGroupVectorizor: It apply a **thinning algorithm** o given strokes to skeletonize those lines, then apply **polygon-approximation** and **bezierpath-approximation** on them
///
/// Before bezierpath-approximation, it will also apply a **straight-line-approximation** on all the lines.
///
/// Shape detection will be applied too.
class SPGeometricsVectorizor {
    
}