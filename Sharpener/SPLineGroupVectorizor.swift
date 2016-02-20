//
//  SPLineGroupVectorizor.swift
//  Sharpener
//
//  Created by Inti Guo on 1/28/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation

protocol SPLineGroupVectorizorVisualTestDelegate {
    func trackingToPoint(point: CGPoint)
}

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
    
    var testDelegate: SPLineGroupVectorizorVisualTestDelegate? = nil
    var visualTesting: Bool { return testDelegate == nil ? false : true }
    
    // MARK: Main Process
    func vectorize(raw: SPRawGeometric) -> SPLineGroup {
        let lineGroup = SPLineGroup()
        
        rawGeometric = raw
        rawData = fetchRawDataFromRawLineGroup(rawGeometric)
        fetchDirectionData()
        trackLineGroup()
        
        let curves = trackedLines.map { line -> SPCurve in
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
        
        lineGroup.lines = curves
        
        return lineGroup
    }
    
    // MARK: Initializing
    required init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
    
    convenience init(size: CGSize) {
        self.init(width: Int(size.width), height: Int(size.height))
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
        let (startPoint, left, right) = findStartPoint()
        var startMagnetPoint = MagnetPoint(
            point: startPoint,
            directions: [(-tangentialDirectionOf(startPoint)).direction]
        )
        magnetPoints.append(startMagnetPoint)
        var startDirection = tangentialDirectionOf(startPoint).direction
        var shouldTrackInvertly = true
        
        var last = startPoint
        var currentLeft = left, currentRight = right
        var lastLeft = left, lastRight = right
        var current = startPoint
        var currentLine = SPLine()
        currentLine<--current
        
        while true {
            let tanCurrent = tangentialDirectionOf(current)
            let tanLast = MXNFreeVector(start: last, end: current)
            let innerProduct = tanLast • tanCurrent
            // FIXME: avoid affects from mid point correction
            var s = !(innerProduct).isSignMinus
            if innerProduct == 0 { s = true }
            last = current
            
            // Runge Kutta method
            let middle = current.interpolateSemiTowards(tangentialDirectionOf(current), forward: s)
            let tanMiddle = tangentialDirectionOf(middle)
            let innerProduct2 = tanLast • tanMiddle
            s = !(innerProduct2).isSignMinus
            current = current.interpolateTowards(tanMiddle, forward: s)
            lastLeft = currentLeft; lastRight = currentRight
            (current, currentLeft, currentRight) = correctedPositionMidPointFor(current)
            currentLine<--current

            /////////////////////////////////////////////
            if visualTesting {
                dispatch_async(GCD.mainQueue) {
                    self.testDelegate?.trackingToPoint(current)
                }
                NSThread.sleepForTimeInterval(0.1)
            }
            /////////////////////////////////////////////
            
            var meetsEndPoint = false
            if rawData.isBackgroudAtPoint(current) && rawData.isBackgroudAtPoint(last) {
                meetsEndPoint = true
            }
            if trackedLines.count == 0 {
                if startMagnetPoint.shouldAttract(current,
                    withTengentialDirection: MXNFreeVector(start: current, end: startMagnetPoint.point)) {
                        if testDelegate != nil { print("### attracted by start point") }
                        // go towards start point
                        let straight = straightlyTrackToPointFrom(current, to: startMagnetPoint.point)
                        currentLine.raw.appendContentsOf(straight)
                        meetsEndPoint = true
                        startMagnetPoint.directions.removeAll()
                }
            }
            
            if checkIfMeetsJunction((currentLeft,currentRight), lastEdge: (lastLeft, lastRight)) && !meetsEndPoint {
                if visualTesting { print("### meets protential junction point") }
                
                let result = findJunctionPointStartFrom(current, last: last)
                
                if let p = result.point, let dIndex = result.directionIndex {
                    if visualTesting { print("### found junction point, \(result.exist ? "exist" : "new")") }
                    
                    if !result.exist {
                        magnetPoints.append(p)
                    }
                
                    let inDirection = p.directions[dIndex]
                    p.directions.removeAtIndex(dIndex)
                    
                    // go towards junctionPoint
                    let straight = straightlyTrackToPointFrom(current, to: result.point!.point)
                    if !straight.isEmpty { current = straight.last! }
                    if straight.count > 1 { last = straight[straight.endIndex-2] }
                    currentLine.raw.appendContentsOf(straight)
                
                    if let outDirectionIndex = smoothDirectionIndexFor(inDirection, of: p) {
                        // shoot!
                        let outDirection = p.directions[outDirectionIndex].poleValue
                        p.directions.removeAtIndex(outDirectionIndex)
                        let freeTrack = freelyTrackToDirectionFrom(current, to: outDirection, steps: 15)
                        if !freeTrack.isEmpty { current = freeTrack.last! }
                        last = p.point
                        currentLine.raw.appendContentsOf(freeTrack)
                    } else {
                        meetsEndPoint = true
                    }
                    // FIXME: consider junction count 2 is a junction point, but fewer free track step
                } else {
                    if result.junctionCount < 2 {
                        if visualTesting { print("### meets end point") }
                        meetsEndPoint = true
                    }
                }
            }
            
            if meetsEndPoint {
                var needNewStartPoint = true
                if shouldTrackInvertly {
                    // should track from current start point, but invertly.
                    if let directionIndex = invertDirectionIndexFor(startDirection, of: startMagnetPoint) {
                        if visualTesting { print("### track invertly") }
                        // found invert direction of start point.
                        needNewStartPoint = false
                        shouldTrackInvertly = false
                        startDirection = startMagnetPoint.directions[directionIndex]
                        startMagnetPoint.directions.removeAtIndex(directionIndex)
                        
                        current = startMagnetPoint.point
                        let free = freelyTrackToDirectionFrom(current, to: startDirection.poleValue, steps: 15)
                        if !free.isEmpty { current = free.last! }
                        if free.count > 1 { last = free[free.endIndex-2] }
                        currentLine.raw.appendContentsOf(free)
                        shouldTrackInvertly = false
                        needNewStartPoint = false
                        currentLine.raw = currentLine.raw.reverse()
                    } else {
                        shouldTrackInvertly = true
                    }
                } else {
                    // did track invertly, should turn shouldTrackInvertly back on.
                    shouldTrackInvertly = true
                }
                
                guard needNewStartPoint else { continue }
                
                if let next = nextStartPoint() {
                    if visualTesting { print("### new start point: \(next.point)") }
                    // need to find a new start point from magnetPoints, and append currentLine to trackedLines.
                    current = next.point
                    let outDirection: MXNFreeVector = next.directions.removeFirst().poleValue
                    trackedLines.append(currentLine)
                    currentLine = SPLine()
                    currentLine<--current
                    
                    startMagnetPoint = next
                	    
                    let free = freelyTrackToDirectionFrom(current, to: outDirection, steps: 10)
                    if !free.isEmpty { current = free.last! }
                    if free.count > 1 { last = free[free.endIndex-2] }
                    currentLine.raw.appendContentsOf(free)
                } else {
                    // when start points are exausted.
                    if visualTesting { print("!!! end") }
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
    private func findStartPoint() -> (start: CGPoint, left: CGPoint, right: CGPoint) {
        for point in rawGeometric.raw {
            if let d = directionData[point] where d.gradient.absolute < 0.01 {
                let (left, right) = edgePointsOf(point)
                return (CGPoint.centerPointOf(left, and: right), left, right)
            }
        }
        return (rawGeometric.raw.first ?? CGPointZero,rawGeometric.raw.first ?? CGPointZero,rawGeometric.raw.first ?? CGPointZero)
    }
    
    /// Check if current tracking point is meeting a junction ( or maybe an end )
    private func checkIfMeetsJunction(currentEdge: (left: CGPoint, right: CGPoint), lastEdge: (left: CGPoint, right: CGPoint)) -> Bool {
        let new = tangentialDirectionOf(currentEdge.left)
            .angleWith(tangentialDirectionOf(currentEdge.right))
        let old = tangentialDirectionOf(lastEdge.left)
            .angleWith(tangentialDirectionOf(lastEdge.right))
        guard new > old else { return false }
        if case 35...180 = new {
             return true
        }
        return false
    }
    
    /// Get the edge point of current tracking point.
    private func edgePointsOf(point: CGPoint) -> (left: CGPoint, right: CGPoint) {
        var left = point
        var right = point
        let gradient = gradientDirectionOf(point)
        if gradient.absolute == 0 { return (point, point) }
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
    private func findJunctionPointStartFrom(point: CGPoint, last lastPoint: CGPoint) -> (point: MagnetPoint?, exist: Bool, directionIndex: Int?, junctionCount: Int) {
        let circCount = 72
        var candidates = [JunctionPointCandidate]()
        let candidateCount = 6
        let step = 2
        var current = point
        var last = lastPoint
        var tanLast = MXNFreeVector(start: last, end: current)
        var candidateA = [JunctionPointCandidate]()
        var candidateB = [JunctionPointCandidate]()
        for i in 1...step*candidateCount {
            let tanCurrent = tangentialDirectionOf(current)
            let innerProduct = tanLast • tanCurrent
            var s = !(innerProduct).isSignMinus
            if innerProduct == 0 { s = true }
            last = current
            
            // Runge Kutta method
            let middle = current.interpolateSemiTowards(tanCurrent, forward: s)
            let tanMiddle = tangentialDirectionOf(middle)
            let innerProduct2 = tanLast • tanMiddle
            s = !(innerProduct2).isSignMinus
            current = current.interpolateTowards(tanMiddle, forward: s)
            tanLast = tanMiddle
            if i % step == 0 {
                if !rawData.isBackgroudAtPoint(current) {
                    candidateA.append(JunctionPointCandidate(point: current))
                }
            }
        }
        
        let tanDefault = MXNFreeVector(start: lastPoint, end: point).normalized
        current = point
        for i in 1...step*candidateCount {
            current = current.interpolateTowards(tanDefault, forward: true)
            if i % step == 0 {
                if !rawData.isBackgroudAtPoint(current) {
                    candidateB.append(JunctionPointCandidate(point: current))
                }
            }
        }

        for i in 0..<min(candidateA.count, candidateB.count) {
            let p = CGPoint.centerPointOf(candidateA[i].point, and: candidateB[i].point)
            if !rawData.isBackgroudAtPoint(p) {
                candidates.append(JunctionPointCandidate(point: p))
            }
        }
        
        candidates.appendContentsOf(candidateA)
        candidates.appendContentsOf(candidateB)
        
        if candidates.isEmpty { return (nil, false, 0, 0) }
        
        // find if such MagnetPoint is already found
        for c in candidates {
            for p in magnetPoints {
                if c.point.distanceTo(p.point) <= 10 {
                    if (MXNFreeVector(start: lastPoint, end: point) • MXNFreeVector(start: point, end: p.point)).isSignMinus {
                        return (nil, false, 0, 2)
                    }
                    if visualTesting { print("### Magnet Point already exists: \(p.point)") }
                    return (p, true, inDirectionIndexFor(MXNFreeVector(x:p.point.x-point.x,y:p.point.y-point.y), of: p), 0)
                }
            }
        }
        
        // Calculate luminance of candidates
        for c in candidates {
            var lumi = [CGFloat]()
            for i in 0..<circCount {
                let distance = 30
                var sum: CGFloat = 0
                let direction = (360 / circCount * i).normalizedVector
                var this = c.point
                var continuousMetWhite = 0
                var allWhite = false
                for _ in 1...distance {
                    this = this.interpolateTowards(direction, forward: true)
                    if rawData.isBackgroudAtPoint(this) && !allWhite {
                        sum += 255
                        continuousMetWhite += 1
                    } else {
                        continuousMetWhite = 0
                    }
                    if continuousMetWhite > distance / 3 {
                        allWhite = true
                    }
                    if allWhite {
                        sum += 255
                    }
                }
                sum /= CGFloat(distance)
                lumi.append(sum)
            }
            c.luminance = lumi // directions will be calculated
        }
        
        // filter the ones that have fewer directions than the others
        // also, select the one with lowest luminance value from previous result
        candidates.sortInPlace { $0.directions.count > $1.directions.count }
        let directionCount = candidates.first?.directions.count
        
        // a junction point neeed more than 2 directions
        if directionCount <= 2 {
            if visualTesting { print("### not a valid Junction Point: \(directionCount)") }
            return (nil, false, 0, directionCount!)
        }
        
        candidates = candidates.filter { $0.directions.count == directionCount }
                               .sort { $0.leastLuminance < $1.leastLuminance }
        
        guard let junctionPoint = candidates.first else {
            return (nil, false, 0, 0)
        }
        let inDirectionIndex = inDirectionIndexFor(
            MXNFreeVector(x:junctionPoint.point.x-point.x,y:junctionPoint.point.y-point.y),
            of: junctionPoint.magnetPoint
        )
        if visualTesting { print("### Junction Point: \(junctionPoint.magnetPoint.point))") }
        return (junctionPoint.magnetPoint, false, inDirectionIndex, 0)
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
    private func inDirectionIndexFor(inDirection: MXNFreeVector, of point: MagnetPoint) -> Int? {
        var biggest: CGFloat = 0
        var index: Int? = nil
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
        
        var maxIndex: Int? = nil
        var maxAngle: CGFloat = 0
        for (n, direction) in point.directions.enumerate() {
            let angle = directionVector.angleWith(direction.poleValue)
            if  angle > 120 && angle > maxAngle {
                maxIndex = n
                maxAngle = angle
            }
        }
        
        return maxIndex
    }
    
    private func straightlyTrackToPointFrom(current: CGPoint, to target: CGPoint) -> [CGPoint] {
        if visualTesting { print("=== straight tracking") }
        var line = [CGPoint]()
        var point = current
        let direction = MXNFreeVector(x: target.x-current.x, y: target.y-current.y).normalized
        let distance = Int(current.distanceTo(target))
        if distance > 0 {
            for _ in 1...distance {
                point = point + direction
                line.append(point)
                /////////////////////////////////////////////
                if visualTesting {
                    dispatch_async(GCD.mainQueue) {
                        self.testDelegate?.trackingToPoint(current)
                    }
                    NSThread.sleepForTimeInterval(0.1)
                }
                /////////////////////////////////////////////
            }
                
        }
        line.append(target)
        if visualTesting { print("~~~ straight tracking end") }
        return line
    }
    
    private func freelyTrackToDirectionFrom(current: CGPoint, to direction: MXNFreeVector, steps: Int) -> [CGPoint] {
        // FIXME: free track auto ends when tan is no longer messy
        if visualTesting { print("=== free tracking") }
        var line = [CGPoint]()
        var point = current
        for _ in 1...steps {
            point = point + direction
            line.append(point)
            /////////////////////////////////////////////
            if visualTesting {
                dispatch_async(GCD.mainQueue) {
                    self.testDelegate?.trackingToPoint(current)
                }
                NSThread.sleepForTimeInterval(0.1)
            }
            /////////////////////////////////////////////
        }
        if visualTesting { print("~~~ free tracking end") }
        return line
    }
    
    private func correctedPositionMidPointFor(point: CGPoint) -> (start: CGPoint, left: CGPoint, right: CGPoint) {
        let edges = edgePointsOf(point)
        let midPoint = CGPoint.centerPointOf(edges.left, and: edges.right)
        let v = MXNFreeVector(start: point, end: midPoint).normalized
        let new = point.interpolateTowards(v*CGFloat(0.5), forward: true)
        return (new, edges.left, edges.right)
    }
    
    private func correctedPositionFor(var point: CGPoint, tan: MXNFreeVector) -> CGPoint {
        let gra = gradientDirectionOf(point)
        let left = point + (-gra)
        let right = point + gra
        if gradientValueOf(left) < gradientValueOf(point)
            && tangentialDirectionOf(left).angleWith(tan) < 10
            && !rawData.isBackgroudAtPoint(left) {
                point = left
        } else if gradientValueOf(right) < gradientValueOf(point)
            && tangentialDirectionOf(right).angleWith(tan) < 10
            && !rawData.isBackgroudAtPoint(right) {
                point = right
        }
        
        return point
    }
    
    private func correctedPositionWithoutAngleCorrectionFor(var point: CGPoint) -> CGPoint {
        let gra = gradientDirectionOf(point)
        let left = point + (-gra)
        let right = point + gra
        if gradientValueOf(left) < gradientValueOf(point)
            && !rawData.isBackgroudAtPoint(left) {
                point = left
        } else if gradientValueOf(right) < gradientValueOf(point)
            && !rawData.isBackgroudAtPoint(right) {
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
            let dUpLeft = directionData[(xfloor, yceil)]?.tangential,
            let dDownLeft = directionData[(xfloor, yfloor)]?.tangential,
            let dUpRight = directionData[(xceil, yceil)]?.tangential,
            let dDownRight = directionData[(xceil, yfloor)]?.tangential
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
        else { return directionData[point]?.gradient ?? MXNFreeVector(x: 0, y: 0)}
        
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
                                                
        let r11 = bXbY * (eX - this.x)
        let r21 = eXbY * (this.x - bX)
        let r12 = bXeY * (eX - this.x)
        let r22 = eXeY * (this.x - bX)
        
        let r1 = r11 + r21
        let r2 = r12 + r22
        
        let p1 = r1 * (eY - this.y)
        let p2 = r2 * (this.y - bY)
        
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
        
        func shouldAttract(point: CGPoint,withTengentialDirection tan: MXNFreeVector) -> Bool {
                if distancePow2To(point) < attractZoneRadiusPow2 {
                    let result = isOfTheSameDirection(point, withTengentialDirection: tan)
                    if result.yes {
                        return true
                    }
                }
                return false
        }
        
        /// If the tangential direction of self and given point matches one of the directions, then true.
        private func isOfTheSameDirection(point: CGPoint,
            withTengentialDirection tan: MXNFreeVector) -> (yes: Bool, directionIndex: Int) {
                for (n, d) in directions.enumerate() {
                    if case .Pole(let v) = d where v.angleWith(tan) > 160 {
                        return (true, n)
                    }
                }
                return (false, 0)
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
        // TODO: use luminance deviation to average, on maximun directions, not minimum.
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
            // var correctedIndexes = [Int]()
            
            var newLuminance = Array<CGFloat>.smoothingWithStandardGaussianBlurOn(luminance)
            newLuminance = Array<CGFloat>.smoothingWithStandardGaussianBlurOn(newLuminance)
            
            // fetch every minimum value from f(angle) = luminance
            for var i in 0..<newLuminance.count {
                let previousIndex = i - 1 >= 0 ? i-1 : newLuminance.endIndex-1
                let nextIndex = i + 1 >= newLuminance.endIndex ? 0 : i+1
                if newLuminance[i] < 130 && newLuminance[previousIndex] > newLuminance[i] && newLuminance[nextIndex] > newLuminance[i] {
                    angleIndexes.append(i)
                } else if newLuminance[i] < 130 && newLuminance[previousIndex] > newLuminance[i] && newLuminance[nextIndex] == newLuminance[i] {
                    var count = 0
                    var next = i + 1 >= newLuminance.endIndex ? 0 : i+1
                    while next != i {
                        count += 1
                        if newLuminance[next] > newLuminance[i] {
                            angleIndexes.append(i+count/2)
                            break
                        } else if newLuminance[next] < newLuminance[i] {
                            break
                        }
                        next += 1
                        if next == newLuminance.endIndex { next = 0 }
                    }
                    i += count
                }
            }
            
            // fetch minimum luminace value
            leastLuminance = angleIndexes.reduce(0) { sum, this in
                return sum + luminance[this]
            }
            
            // fetch directions
            for i in angleIndexes {
                let vector = (360 / luminance.count * i).normalizedVector
                let newDirection = Direction2D.Pole(vector: vector)
                directions.append(newDirection)
            }
            
        }
    }
}



// MARK: - Extensions

extension Int {
    var normalizedVector: MXNFreeVector {
        let y = sin(CGFloat(self) * CGFloat(M_PI) / 180)
        let x = cos(CGFloat(self) * CGFloat(M_PI) / 180)
        return MXNFreeVector(x: x, y: y)
    }
}

extension XYZWPixel {
    var tangentialDirection: MXNFreeVector {
        return tangential.normalized
    }
    var gradientDirection: MXNFreeVector {
        return gradient.normalized
    }
    var tangential: MXNFreeVector {
        return MXNFreeVector(x: CGFloat(z), y: CGFloat(w))
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
        return interpolateTowards(newDirection, forward: forward)
    }
    
    static func centerPointOf(one: CGPoint, and another: CGPoint) -> CGPoint {
        return CGPoint(x: (one.x+another.x)/2, y: (one.y+another.y)/2)
    }
}

extension CGFloat {
    var isInteger: Bool {
        return floor(self) - self == 0
    }
}



