//
//  SPLineGroupVectorizor.swift
//  Sharpener
//
//  Created by Inti Guo on 1/28/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation


/// SPLineGroupVectorizor is used to track lines into a thin enough vector line, then using things like bezierpath-approximation to smooth the result and give out shape-detection based suggestions.
class SPLineGroupVectorizor {
    
    // MARK: Properties
    private let context: MXNContext = MXNContext()
    
    var width: Int
    var height: Int
    
    var directionData: MXNTextureDataFloat!
    var rawData: MXNTextureData!
    var rawGeometric: SPRawGeometric!
    var magnetPoints = [CGPoint]()
    var trackedPoints = [CGPoint]()
    
    // MARK: Main Process
    func vectorize(raw: SPRawGeometric) -> SPLineGroup {
        let lineGroup = SPLineGroup()
        
        rawGeometric = raw
        rawData = fetchRawDataFromRawLineGroup(rawGeometric)
        
        // FIXME: this will not fetch direction data, it only fetches gradient tensor, we need to calculate evalue and evector from it.
        fetchDirectionData()
        //trackLineGroup()
        //seperateLineGroup()
        
        return lineGroup
    }
    
    // MARK: Initializing
    init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
    
    // MARK: Sub Processes
    
    /// It generates a texture data for raw.
    ///
    /// - Parameters:
    ///     - raw: The SPRawGeometric that needs to be analysed.
    /// - Returns: The texuture data.
    private func fetchRawDataFromRawLineGroup(raw: SPRawGeometric) -> MXNTextureData {
        return MXNTextureData(points: raw.raw, width: width, height: height)
    }
    
    /// It applys gradientFieldDetectingFilter on raw and returns a direction data containg 2 vectors representing tengential direction and gradient direction.
    ///
    /// - Returns: A direction data containg 2 vectors representing tengential direction and gradient direction
    private func fetchDirectionData() {
        let filter = LineTrackingFilter(context: context)
        filter.provider = MXNImageProvider(image: UIImage(textureData: rawData), context: context)
        
        filter.applyFilter()
        directionData = MXNTextureDataFloat(texture: filter.eigenVectors)
        
        for i in 0..<100 {
            for j in 0..<100 {
                let p = CGPoint(x: i, y: j)
                let t = directionData[p]
                guard let a = t else { continue }
                if a.x == 0 { print("•"); continue }
                switch (a.z, a.w) {
                case let (x, y) where x != 0 && y/x < 0.5579 && y/x >= -0.5579:
                    print("⟷"); continue
                case let (x, y) where x != 0 && y/x >= 0.5579 && y/x < 22.5882:
                    print("⤢"); continue
                case let (x, y) where x != 0 && y/x < -0.5579 && y/x >= -22.5882:
                    print("⤡"); continue
                default:
                    print("⇅"); continue
                }
            }
            print("↵")
        }
    }
    
    private func trackLineGroup() {
        let startPoint = findStartPoint()
        magnetPoints.append(startPoint)
        trackedPoints.append(startPoint)
        
        var stack = Stack(storage: [CGPoint]())
        stack.push(startPoint)
        
        let last = startPoint
        let current = startPoint
        while !stack.isEmpty {
            let tanCurrent = tangentialDirectionOf(current)
            let tanLast = tangentialDirectionOf(last)
            //let s = !(tanLast • tanCurrent).isSignMinus
            // current +=
        }
    }
    
    private func seperateLineGroup() {
        
    }
}


// MARK: - Utility Methods
extension SPLineGroupVectorizor {
    
    /// Get a start point from raw.
    private func findStartPoint() -> CGPoint {
        for point in rawGeometric.raw {
            if let d = directionData[point] where d.gradient.absolute < 1.1 {
                return point
            }
        }
        return rawGeometric.raw.first ?? CGPointZero
    }
    
    /// Get the tangential direction of a point when it is not a integer-point using bilinear interpolation.
    private func tangentialDirectionOf(point: CGPoint) -> MXNFreeVector {
        guard !point.isIntegerPoint && directionData.ifPointIsValid(point)
        else { return directionData[point]?.tangentialDirection ?? MXNFreeVector(x: 0, y: 0)}
        
        let xceil = Int(ceil(point.x))
        let xfloor = Int(floor(point.x))
        let yceil = Int(ceil(point.y))
        let yfloor = Int(floor(point.y))
        
        guard
            let dUpLeft = directionData[(xfloor, yceil)]?.tangentialDirection,
            let dDownLeft = directionData[(xfloor, yfloor)]?.tangentialDirection,
            let dUpRight = directionData[(xceil, yceil)]?.tangentialDirection,
            let dDownRight = directionData[(xceil, yfloor)]?.tangentialDirection
        else { return MXNFreeVector(x: 0, y: 0) } // if any of those is nil, such point should not be valid
        
        return bilinearInterporlation(this: (point.x, point.y),
            bX: CGFloat(xfloor), bY: CGFloat(yfloor), eX: CGFloat(xceil), eY: CGFloat(yceil),
            bXbY: dDownLeft, bXeY: dUpLeft, eXbY: dDownRight, eXeY: dUpRight).normalized
    }
    
    /// Get the gradient of a point when it is not a integer-point using bilinear interpolation.
    private func gradientOf(point: CGPoint) -> MXNFreeVector {
        guard !point.isIntegerPoint && directionData.ifPointIsValid(point)
            else { return directionData[point]?.tangentialDirection ?? MXNFreeVector(x: 0, y: 0)}
        
        let xceil = Int(ceil(point.x))
        let xfloor = Int(floor(point.x))
        let yceil = Int(ceil(point.y))
        let yfloor = Int(floor(point.y))
        
        guard let dUpLeft = directionData[(xfloor, yceil)]?.gradient,
            let dDownLeft = directionData[(xfloor, yfloor)]?.gradient,
            let dUpRight = directionData[(xceil, yceil)]?.gradient,
            let dDownRight = directionData[(xceil, yfloor)]?.gradient
        else { return MXNFreeVector(x: 0, y: 0) } // if any of those is nil, such point should not be valid
        
        return bilinearInterporlation(this: (point.x, point.y),
            bX: CGFloat(xfloor), bY: CGFloat(yfloor), eX: CGFloat(xceil), eY: CGFloat(yceil),
            bXbY: dDownLeft, bXeY: dUpLeft, eXbY: dDownRight, eXeY: dUpRight)
    }
    
    /// Get the gradient direction of a point when it is not a integer-point using bilinear interpolation.
    private func gradientDirectionOf(point: CGPoint) -> MXNFreeVector {
        return gradientOf(point).normalized
    }
    
    func bilinearInterporlation(this this: (x: CGFloat, y: CGFloat),
        bX: CGFloat, bY: CGFloat, eX: CGFloat, eY: CGFloat,
        bXbY: MXNFreeVector, bXeY: MXNFreeVector, eXbY: MXNFreeVector, eXeY:  MXNFreeVector) -> MXNFreeVector {
        
        let r11 = bXbY * ((eX - this.x) / (eX - bX))
        let r21 = eXbY * ((this.x - bX) / (eX - bX))
        let r12 = bXeY * ((eX - this.x) / (eX - bX))
        let r22 = eXeY * ((this.x - bX) / (eX - bX))
        
        let r1 = r11 + r21
        let r2 = r12 + r22
        
        let p1 = r1 * ((eY - this.y) / (eY - bY))
        let p2 = r2 * ((this.y - bY) / (eY - bY))
        
        return p1 + p2
    }
}


// MARK: - Extensions

extension XYZWPixel {
    var tangentialDirection: MXNFreeVector { return MXNFreeVector(x: CGFloat(x), y: CGFloat(y)).normalized }
    var gradientDirection: MXNFreeVector { return MXNFreeVector(x: CGFloat(z), y: CGFloat(w)).normalized }
    var gradient: MXNFreeVector { return MXNFreeVector(x: CGFloat(z), y: CGFloat(w)) }
}

extension CGPoint {
    var isIntegerPoint: Bool {
        return self.x.isInteger && self.y.isInteger
    }
}

extension CGFloat {
    var isInteger: Bool {
        return floor(self) - self == 0
    }
}



