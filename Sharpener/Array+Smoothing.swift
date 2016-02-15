//
//  Array+Smoothing.swift
//  Sharpener
//
//  Created by Inti Guo on 2/14/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation

extension Array {
    
    /// Smoothing an array with given 1-d operator
    static func smoothingWithOperator(o: [CGFloat], on a: [CGFloat], isCircle: Bool = true) -> [CGFloat]? {
        
        func operateIndex(currentIndex: Int) -> [Int?] {
            var indexes = [Int?]()
            let length = a.count
            let radius = o.count / 2
            for i in currentIndex-radius...currentIndex+radius {
                let index: Int?
                switch i {
                case let x where x < 0:
                    index = isCircle ? (length + i) : nil
                case let x where x >= length:
                    index = isCircle ? (i - length) : nil
                default:
                    index = i
                }
                indexes.append(index)
            }
            return indexes
        }
        
        let operatorWidth = o.count
        guard operatorWidth.isOdd && operatorWidth <= a.count else { return nil }
        var out = [CGFloat]()
        
        for i in 0..<a.endIndex {
            let oIndexes = operateIndex(i)
            var sum: CGFloat = 0
            for j in 0..<oIndexes.endIndex {
                guard let oi = oIndexes[j] else { continue }
                sum += a[oi] * o[j]
            }
            out.append(sum)
        }
        
        return out
    }
    
    static func smoothingWithStandardGaussianBlurOn(a: [CGFloat], isCircle: Bool = true) -> [CGFloat] {
        let gaussianR2: [CGFloat] = [0.06795, 0.17065, 0.5, 0.17065, 0.06795]
        return Array.smoothingWithOperator(gaussianR2, on: a, isCircle: isCircle)!
    }
    
}

extension Int {
    var isOdd: Bool { return self % 2 != 0 }
    var isEven: Bool { return !isOdd }
}

