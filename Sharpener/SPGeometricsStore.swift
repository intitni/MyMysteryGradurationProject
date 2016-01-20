//
//  SPGeometricsStore.swift
//  Sharpener
//
//  Created by Inti Guo on 1/14/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation

/// SPGeometricsStore is used to store SPGeometrics
class SPGeometricsStore {
    
    /// Singleton for proccessing progress
    static var universalStore = SPGeometricsStore()
    
    var shapeStore = [SPShape]()
    var lineStore = [SPLineGroup]()
    var shapeCount: Int { return shapeStore.count }
    var lineCount: Int { return lineStore.count }
    var geometricsCount: Int { return shapeCount + lineCount }
}

// MARK: - Methods
extension SPGeometricsStore {
    func removeAll() {
        shapeStore.removeAll()
        lineStore.removeAll()
    }
    
    func append(shape: SPShape) {
        shapeStore.append(shape)
    }
    
    func append(line: SPLineGroup) {
        lineStore.append(line)
    }
}