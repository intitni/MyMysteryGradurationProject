//
//  SPGeometricsVectorizor.swift
//  Sharpener
//
//  Created by Inti Guo on 1/19/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation

protocol SPGeometricsVectorizorDelegate: class {
    func didFinishVectorizing(store: SPGeometricsStore)
    func didFinishAnIndividualVectorizingFor(geometric: SPGeometrics, withIndex index: Int, countOfTotal count: Int)
}

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
    
    weak var delegate: SPGeometricsVectorizorDelegate?
    
    func vectorize(store: SPGeometricsStore) {
        let store = SPGeometricsStore.universalStore
        
        for (i, raw) in store.rawStore.enumerate() where !raw.isHidden {
            switch raw.type {
            case .Shape:
                let v = SPShapeVectorizor()
                let s = v.vectorize(raw)
                store.shapeStore.append(s)
                self.delegate?.didFinishAnIndividualVectorizingFor(s, withIndex: i, countOfTotal: store.rawStore.count)
            case .Line:
                let v = SPLineGroupVectorizor(width: 600, height: 800)
                let l = v.vectorize(raw)
                store.lineStore.append(l)
                self.delegate?.didFinishAnIndividualVectorizingFor(l, withIndex: i, countOfTotal: store.rawStore.count)
            }
        }
        
        self.delegate?.didFinishVectorizing(store)
    }
}