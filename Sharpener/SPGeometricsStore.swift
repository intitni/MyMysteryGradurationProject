//
//  SPGeometricsStore.swift
//  Sharpener
//
//  Created by Inti Guo on 1/14/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation

/// SPGeometricsStore is used to store SPGeometrics
struct SPGeometricsStore {
    
    /// Singleton for proccessing progress
    static var universalStore = SPGeometricsStore()
    
    var rawStore = [SPRawGeometric]()
    var shapeStore = [SPShape]()
    var lineStore = [SPLineGroup]()
    var shapeCount: Int { return shapeStore.count }
    var lineCount: Int { return lineStore.count }
    var geometricsCount: Int { return shapeCount + lineCount }
}

// MARK: - Methods
extension SPGeometricsStore {
    mutating func removeAll() {
        shapeStore.removeAll()
        lineStore.removeAll()
    }
    
    mutating func append(shape: SPShape) {
        shapeStore.append(shape)
    }
    
    mutating func append(line: SPLineGroup) {
        lineStore.append(line)
    }
}