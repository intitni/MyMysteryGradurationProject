//
//  SPLineGroupVectorizor.swift
//  Sharpener
//
//  Created by Inti Guo on 1/28/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation


/// SPLineGroupVectorizor is used to track lines into a thin enough vector line, then using things like bezierpath-approximation
/// to smooth the result and give out shape-detection based suggestions.
class SPLineGroupVectorizor {
    
    // MARK: Properties
    private let context: MXNContext = MXNContext()
    
    var width: Int
    var height: Int
    
    var directionData: MXNTextureDataFloat!
    var rawData: MXNTextureData!
    var rawGeometric: SPRawGeometric!
    var magnetPoints = [MagnetPoint]()
    var trackedPoints = [CGPoint]()
    var trackedLines = [SPLine]()
    var harrisValues: MXNTextureDataFloat!
    
    var gradientTensorTexture: MTLTexture!
    
    // MARK: Main Process
    func vectorize(raw: SPRawGeometric) -> SPLineGroup {
        let lineGroup = SPLineGroup()
        
        rawGeometric = raw
        rawData = fetchRawDataFromRawLineGroup(rawGeometric)
        fetchDirectionData()
        //trackLineGroup()
        
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
    
    /// It applys gradientFieldDetectingFilter on raw and returns a direction data containg 2 vectors representing
    /// tengential direction and gradient direction.
    private func fetchDirectionData() {
        let filter = LineTrackingFilter(context: context)
        filter.provider = MXNImageProvider(image: UIImage(textureData: rawData), context: context)
        
        filter.applyFilter()
        directionData = MXNTextureDataFloat(texture: filter.eigenVectors)
        gradientTensorTexture = filter.gradientTensor
    }
    
    private func trackLineGroup() {
        let startPoint = findStartPoint()
        var startMagnetPoint = MagnetPoint(
            point: startPoint,
            directions: [(-tangentialDirectionOf(startPoint)).direction]
        )
        magnetPoints.append(startMagnetPoint)
        var startDirection = tangentialDirectionOf(startPoint).direction
        var shouldTrackInvertly = true
        
        var last = startPoint
        var current = startPoint
        var currentLine = SPLine()
        currentLine<--current
        
        while true {
            let tanCurrent = tangentialDirectionOf(current)
            let tanLast = tangentialDirectionOf(last)
            let s = !(tanLast • tanCurrent).isSignMinus
            last = current
            
            // Runge Kutta method
            let middle = current.interpolateSemiTowards(tangentialDirectionOf(current), forward: s)
            let tanMiddle = tangentialDirectionOf(middle)
            current = current.interpolateTowards(tanMiddle, forward: s)
            current = correctedPositionFor(current, tan: tanMiddle)
            
            currentLine<--current
            
            // TODO: first time closed path
            
            var meetsEndPoint = false
            if checkIfMeetsJunction(current) {
                let result = findJunctionPointStartFrom(current, last: last)
                
                if let p = result.point {
                    if !result.exist {
                        magnetPoints.append(p)
                    }
                
                    let inDirection = p.directions[result.directionIndex]
                    p.directions.removeAtIndex(result.directionIndex)
                    
                    // go towards junctionPoint
                    let straight = straightlyTrackToPointFrom(current, to: result.point!.point)
                    if !straight.isEmpty { current = straight.last! }
                    if straight.count > 1 { last = straight[straight.endIndex-2] }
                    currentLine.raw.appendContentsOf(straight)
                
                    if let smoothDirectionIndex = smoothDirectionIndexFor(inDirection, of: p) {
                        // shoot!
                        let thisDirection = startMagnetPoint.directions[smoothDirectionIndex].poleValue
                        let free = freelyTrackToDirectionFrom(current, to: thisDirection, steps: 3)
                        if !free.isEmpty { current = free.last! }
                        if free.count > 1 { last = free[free.endIndex-2] }
                        currentLine.raw.appendContentsOf(free)
                    } else {
                        meetsEndPoint = true
                    }
                } else {
                    meetsEndPoint = true
                }
            }
            
            if meetsEndPoint {
                var needNewStartPoint = true
                if shouldTrackInvertly {
                    // Should track from current start point, but invertly
                    if let directionIndex = invertDirectionIndexFor(startDirection, of: startMagnetPoint) {
                        // found invert direction of start point.
                        needNewStartPoint = false
                        shouldTrackInvertly = false
                        startDirection = startMagnetPoint.directions[directionIndex]
                        startMagnetPoint.directions.removeAtIndex(directionIndex)
                        
                        let free = freelyTrackToDirectionFrom(current, to: startDirection, steps: 3)
                        if !free.isEmpty { current = free.last! }
                        if free.count > 1 { last = free[free.endIndex-2] }
                        currentLine.raw.appendContentsOf(free)
                        shouldTrackInvertly = false
                        needNewStartPoint = false
                    } else {
                        shouldTrackInvertly = true
                    }
                } else {
                    // Did track invertly, and need to append new line into the old one
                    let newRaw: [CGPoint] = currentLine.raw.reverse()
                    let oldRaw: [CGPoint] = trackedLines[trackedLines.endIndex-1].raw
                    newRaw.appendContentsOf(oldRaw)
                    trackedLines.removeLast()
                    trackedLines.append(newRaw)
                    shouldTrackInvertly = true
                }
                guard needNewStartPoint else { continue }
                
                if let next = nextStartPoint() {
                    current = next.point
                    let thisDirection: MXNFreeVector
                    if case .Pole(let x) = next.directions[0] {
                        thisDirection = x
                        next.directions.removeFirst()
                    }
                    trackedLines.append(currentLine)
                    currentLine = SPLine()
                    currentLine<--current
                    
                    startMagnetPoint = next
                	    
                    let free = freelyTrackToDirectionFrom(current, to: thisDirection, steps: 3)
                    if !free.isEmpty { current = free.last! }
                    if free.count > 1 { last = free[free.endIndex-2] }
                    currentLine.raw.appendContentsOf(free)
                } else {
                    break
                }
            }
        }
    }

}


// MARK: - Utility Methods
extension SPLineGroupVectorizor {
    
    // MARK: Line Tracking Methods
    
    /// Get a start point from raw.
    private func findStartPoint() -> CGPoint {
        for point in rawGeometric.raw {
            if let d = directionData[point] where d.gradient.absolute < 1.1 {
                return point
            }
        }
        return rawGeometric.raw.first ?? CGPointZero
    }
    
    /// Check if current tracking point is meeting a junction ( or maybe an end )
    private func checkIfMeetsJunction(point: CGPoint) -> Bool {
        let edgePoints = edgePointsOf(point)
        if tangentialDirectionOf(edgePoints.left)
           .angleWith(tangentialDirectionOf(edgePoints.right)) >= 30 {
             return true
        }
        return false
    }
    
    /// Get the edge point of current tracking point.
    private func edgePointsOf(point: CGPoint) -> (left: CGPoint, right: CGPoint) {
        var left = point
        var right = point
        let gradient = gradientDirectionOf(point)
        
        while !rawData.isBackgroudAtPoint(left) {
            left = left + (-gradient)
        }
        while !rawData.isBackgroudAtPoint(right) {
            right = right + gradient
        }
        
        return (left, right)
    }
    
    /// Find next start point from magnetPoints.
    private func nextStartPoint() -> MagnetPoint? {
        for point in magnetPoints {
            if !point.directions.isEmpty {
                return point
            }
        }
        return nil
    }
    
    /// Find junction point, if nil, then it's an end.
    private func findJunctionPointStartFrom(point: CGPoint, var last: CGPoint) -> (point: MagnetPoint?, exist: Bool, directionIndex: Int) {
        let circCount = 36
        var candidates = [JunctionPointCandidate]()
        let candidateCount = 5
        let step = 3
        var current = point
        for i in 1...step*candidateCount {
            let tanCurrent = tangentialDirectionOf(current)
            let tanLast = tangentialDirectionOf(last)
            let s = !(tanLast • tanCurrent).isSignMinus
            last = current
            let middle = current.interpolateSemiTowards(tangentialDirectionOf(current), forward: s)
            let tanMiddle = tangentialDirectionOf(middle)
            current = current.interpolateTowards(tanMiddle, forward: s)
            current = correctedPositionFor(current, tan: tanMiddle)
            if i % step == 0 {
                candidates.append(JunctionPointCandidate(point: current))
            }
        }
        
        if candidates.isEmpty { return (nil, false, 0) }
        
        for c in candidates {
            for p in magnetPoints {
                if c.point.distanceTo(p.point) <= 5 {
                    return (p, true, inDirectionIndexFor(MXNFreeVector(x:p.point.x-point.x,y:p.point.y-point.y), of: p))
                }
            }
        }
        
        for c in candidates {
            var lumi = [CGFloat]()
            for i in 0..<circCount {
                let distance = 20
                let sum: CGFloat = 0
                let direction = (360 / circCount * i).normalizedVector
                var this = point
                for _ in 1...distance {
                    this = this.interpolateTowards(direction, forward: true)
                    if rawData.isBackgroudAtPoint(c) {
                        sum += 255
                    }
                }
                sum /= CGFloat(distance)
                lumi.append(sum)
            }
            c.luminance = lumi
        }
        
        candidates.sortInPlace { $0.directions.count > $1.directions.count }
        let directionCount = candidates.first?.directions.count
        
        if directionCount <= 2 { return (nil, false, 0) }
        
        candidates = candidates.filter { $0.directions.count < directionCount }
                               .sort { $0.leastLuminance < $1.leastLuminance }
        
        guard let junctionPoint = candidates.first else { return (nil, false, 0) }
        let inDirectionIndex = inDirectionIndexFor(
            MXNFreeVector(x:junctionPoint.point.x-point.x,y:junctionPoint.point.y-point.y),
            of: junctionPoint.magnetPoint
        )
        return (junctionPoint.magnetPoint, false, inDirectionIndex)
    }
    
    /// Find invert direction for start point.
    private func invertDirectionIndexFor(direction: Direction2D, of point: MagnetPoint) -> Int? {
        let directionVector = direction.poleValue
        guard !directionVector.isZeroVector else { return nil }
        
        for (n, direction) in point.directions.enumerate() {
            if directionVector.angleWith(direction.poleValue) > 140 {
                return n
            }
        }
        
        return nil
    }
    
    /// 
    private func inDirectionIndexFor(inDirection: MXNFreeVector, of point: MagnetPoint) -> Int {
        let biggest = 0
        let index = 0
        for (n, direction) in point.directions.enumerate() {
            let angle = inDirection.angleWith(direction.poleValue)
            if angle > biggest {
                biggest = angle
                index = n
            }
        }
        return index
    }
    
    /// Find smooth direction for juntion point.
    private func smoothDirectionIndexFor(direction: Direction2D, of point: MagnetPoint) -> Int? {
        let directionVector = direction.poleValue
        guard !directionVector.isZeroVector else { return nil }
        
        for (n, direction) in point.directions.enumerate() {
            if directionVector.angleWith(direction.poleValue) < 40 {
                return n
            }
        }
        
        return nil
    }
    
    private func straightlyTrackToPointFrom(current: CGPoint, to target: CGPoint) -> [CGPoint] {
        var line = [CGPoint]()
        var point = current
        let direction = MXNFreeVector(x: target.x-current.x, y: target.y-current.y)
        let distance = Int(current.distanceTo(target))
        for _ in 1...distance {
            point = point + direction
            line.append(point)
        }
        line.append(target)
        return line
    }
    
    private func freelyTrackToDirectionFrom(current: CGPoint, to direction: MXNFreeVector, steps: Int) -> [CGPoint] {
        var line = [CGPoint]()
        var point = current
        for _ in 1...steps {
            point = point + direction
            point = correctedPositionWithoutAngleCorrectionFor(point)
            line.append(point)
        }
        return line
    }
    
    private func correctedPositionFor(var point: CGPoint, tan: MXNFreeVector) -> CGPoint {
        let gra = gradientDirectionOf(point)
        let left = point + (-gra)
        let right = point + gra
        if gradientValueOf(left) < gradientValueOf(point)
            && tangentialDirectionOf(left).angleWith(tan) < 10
            && rawData.isBackgroudAtPoint(left) {
                point = left
        } else if gradientValueOf(right) < gradientValueOf(point)
            && tangentialDirectionOf(right).angleWith(tan) < 10
            && rawData.isBackgroudAtPoint(right) {
                point = right
        }
        
        return point
    }
    
    private func correctedPositionWithoutAngleCorrectionFor(var point: CGPoint) -> CGPoint {
        let gra = gradientDirectionOf(point)
        let left = point + (-gra)
        let right = point + gra
        if gradientValueOf(left) < gradientValueOf(point)
            && rawData.isBackgroudAtPoint(left) {
                point = left
        } else if gradientValueOf(right) < gradientValueOf(point)
            && rawData.isBackgroudAtPoint(right) {
                point = right
        }
        
        return point
    }
    
    // MARK: Direction Calculation
    
    /// Get the tangential direction of a point.
    /// - Returns: A normalized MXNFreeVector showing the tengential direction.
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
        else {
            // if any of those is nil, such point should not be valid
            return MXNFreeVector(x: 0, y: 0)
        }
        
        return bilinearInterporlation(this: (point.x, point.y),
            bX: CGFloat(xfloor), bY: CGFloat(yfloor), eX: CGFloat(xceil), eY: CGFloat(yceil),
            bXbY: dDownLeft, bXeY: dUpLeft, eXbY: dDownRight, eXeY: dUpRight).normalized
    }
    
    /// Get the gradient of a point when it is not a integer-point using bilinear interpolation.
    /// - Returns: A MXNFreeVector showing the gradient.
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
        else {
            // if any of those is nil, such point should not be valid
            return MXNFreeVector(x: 0, y: 0)
        }
        
        return bilinearInterporlation(this: (point.x, point.y),
            bX: CGFloat(xfloor), bY: CGFloat(yfloor), eX: CGFloat(xceil), eY: CGFloat(yceil),
            bXbY: dDownLeft, bXeY: dUpLeft, eXbY: dDownRight, eXeY: dUpRight)
    }
    
    /// Get the gradient direction of a point.
    /// - Returns: A normalized MXNFreeVector showing the gradient direction
    private func gradientDirectionOf(point: CGPoint) -> MXNFreeVector {
        return gradientOf(point).normalized
    }
    
    /// Get tthe gradientValue of a point.
    /// - Returns: The gradient value of point, the higher the value is, the high the chance of it being a border point of line.
    private func gradientValueOf(point: CGPoint) -> CGFloat {
        return gradientOf(point).absolute
    }
    
    /// Performs a bilinear Interporlation on given point and four guiding points. (VALUE: MXNFreeVector)
    /// - Parameters:
    ///     - this: The give point
    ///     - others: The other points locations and values 
    /// - Returns: The value for given point.
    func bilinearInterporlation(this this: (x: CGFloat, y: CGFloat),
                                            bX: CGFloat, bY: CGFloat, eX: CGFloat, eY: CGFloat,
                                            bXbY: MXNFreeVector, bXeY: MXNFreeVector,
                                            eXbY: MXNFreeVector, eXeY:  MXNFreeVector)
                                            -> MXNFreeVector {
        
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


// MARK: - Internal Structs / Classes

extension SPLineGroupVectorizor {
    /// A special point that attracts tracking point.
    class MagnetPoint {
        var point: CGPoint
        var directions: [Direction2D]
        let attractZoneRadiusPow2: CGFloat = 100
        
        init(point: CGPoint, directions: [Direction2D]) {
            self.point = point
            self.directions = directions
        }
        
        func shouldAttract(point: CGPoint,withTengentialDirection tan: MXNFreeVector)
            -> (shouldAtrract: Bool, directionIndex: Int) {
                if distancePow2To(point) < attractZoneRadiusPow2 {
                    let result = isOfTheSameDirection(point, withTengentialDirection: tan)
                    if result.yes {
                        return (true, result.directionIndex)
                    }
                }
                return (false, 0)
        }
        
        /// If the tangential direction of self and given point matches one of the directions, then true.
        private func isOfTheSameDirection(point: CGPoint,
            withTengentialDirection tan: MXNFreeVector) -> (yes: Bool, directionIndex: Int) {
                for (n, d) in directions.enumerate() {
                    if case .Pole(let v) = d where v.angleWith(tan) < 10 {
                        return (true, n)
                    }
                }
                return (false, n)
        }
        
        func distancePow2To(point: CGPoint) -> CGFloat {
            return point.distancePow2To(self.point)
        }
    }
    
    class JunctionPointCandidate {
        var point: CGPoint
        var luminance = [CGFloat]() {
            didSet {
                calculateDirection()
            }
        }
        var leastLuminance: CGFloat = 0
        var directions = [Direction2D]()
        
        init(point: CGPoint) {
            self.point = point
        }
        
        var magnetPoint: MagnetPoint {
            return MagnetPoint(point: point, directions: directions)
        }
        
        func calculateDirection() {
            guard !luminance.isEmpty else { return }
            var angleIndexes = [Int]()
            var correctedIndexes = [Int]()
            var least = 0
            
            // fetch every minimum value from f(angle) = luminance
            for var i in 0..<luminance.count {
                let previousIndex = i - 1 >= 0 ? i-1 : luminance.endIndex-1
                let nextIndex = i + 1 >= luminance.endIndex ? 0 : luminance.endIndex-1
                if luminance[i] < 50 && luminance[previousIndex] > luminance[i] && luminance[nextIndex] > luminance[i] {
                    angleIndexes.append(i)
                } else if luminance[i] < 50 && luminance[previousIndex] > luminance[i] && luminance[nextIndex] == luminance[i] {
                    var count = 0
                    var next = i + 1 >= luminance.endIndex ? 0 : i+1
                    while next != i {
                        count += 1
                        if luminance[next] > luminance[i] {
                            angleIndexes.append(i+count/2)
                            break
                        } else if luminance[next] < luminance[i] {
                            break
                        }
                    }
                    i += count
                }
            }
            
            // combine similar directions
            while !angleIndexes.isEmpty {
                var combineIndex = [Int]()
                var current = angleIndexes.removeFirst()
                combineIndex.append(current)
                for i in 0..<angleIndexes.count {
                    if angleIndexes[i] - current <= 2 {
                        combineIndex.append(angleIndexes[i])
                    }
                }
                for i in combineIndex {
                    angleIndexes.removeAtIndex(angleIndexes.indexOf(i))
                }
                correctedIndexes.append( combineIndex.sortInPlace()[combineIndex.count/2] )
            }
            
            // fetch minimum luminace value
            leastLuminance = correctedIndexes.reduce(0) { sum, this in
                return sum += luminance[this]
            }
            
            // fetch directions
            for i in correctedIndexes {
                let vector = (360 / luminance.count * i).normalizedVector
                let newDirection = .Pole(vector: vector)
                directions.append(newDirection)
            }
            
        }
    }
}



// MARK: - Extensions

extension Int {
    var normalizedVector: MXNFreeVector {
        let y = sin(self)
        let x = cos(self)
        return MXNFreeVector(x: x, y: y)
    }
}

extension XYZWPixel {
    var tangentialDirection: MXNFreeVector {
        return MXNFreeVector(x: CGFloat(z), y: CGFloat(w)).normalized
    }
    var gradientDirection: MXNFreeVector {
        return MXNFreeVector(x: CGFloat(x), y: CGFloat(y)).normalized
    }
    var gradient: MXNFreeVector {
        return MXNFreeVector(x: CGFloat(x), y: CGFloat(y))
    }
}

extension CGPoint {
    var isIntegerPoint: Bool {
        return self.x.isInteger && self.y.isInteger
    }
    
    func distancePow2To(point: CGPoint) -> CGFloat {
        let x2 = pow(point.x - x, 2)
        let y2 = pow(point.y - y, 2)
        return x2 + y2
    }
    
    func distanceTo(point: CGPoint) -> CGFloat {
        return sqrt(distancePow2To(point))
    }
    
    func interpolateTowards(direction: MXNFreeVector, forward: Bool) -> CGPoint {
        let newX = x + (forward ? direction.x : -direction.x)
        let newY = y + (forward ? direction.y : -direction.y)
        return CGPoint(x: newX, y: newY)
    }
    
    func interpolateSemiTowards(direction: MXNFreeVector, forward: Bool) -> CGPoint {
        let newDirection = MXNFreeVector(x: direction.x/2, y: direction.y/2)
        return interpolateSemiTowards(newDirection, forward: forward)
    }
}

extension CGFloat {
    var isInteger: Bool {
        return floor(self) - self == 0
    }
}



