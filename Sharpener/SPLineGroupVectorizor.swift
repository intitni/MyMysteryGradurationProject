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
    
    var gradientTensorTexture: MTLTexture!
    
    var testDelegate: SPLineGroupVectorizorVisualTestDelegate? = nil
    var visualTesting: Bool { return testDelegate != nil }
    
    // MARK: Main Process
    func vectorize(raw: SPRawGeometric) -> SPLineGroup {
        let lineGroup = SPLineGroup()
        
        rawGeometric = raw
        fetchRawDataFromRawLineGroup()
        fetchDirectionData()
        trackLineGroup()
        
        let curves = trackedLines.map { line in
            SPCurve(raw: line.raw)
        }
        
        curves.forEach { c in
            let shapeDetector = SPShapeDetector()
            c.guesses = shapeDetector.detect(c, inShape: false)
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
    private func fetchRawDataFromRawLineGroup() {
        rawData = MXNTextureData(points: rawGeometric.raw, width: width, height: height)
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
        
        // FIXME: Figure out what is causing an infinite loop here.
        while currentLine.raw.count < 20000 {
            let tanCurrent = tangentialDirectionOf(current)
            let tanLast = MXNFreeVector(start: last, end: current)
            // FIXME: avoid affects from mid point correction
            var s = !(tanLast • tanCurrent).isSignMinus
            last = current
            
            // Runge Kutta method
            let middle = current.interpolateSemiTowards(tangentialDirectionOf(current), forward: s)
            var tanMiddle = tangentialDirectionOf(middle)
            if tanMiddle.isZeroVector { tanMiddle = tanLast }
            s = !(tanLast • tanMiddle).isSignMinus
            current = current.interpolateTowards(tanMiddle, forward: s)
            lastLeft = currentLeft
            lastRight = currentRight
            (current, currentLeft, currentRight) = correctedPositionMidPointFor(current)

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
            } else {
                currentLine<--current
            }
            
            // First line loop handling
            if trackedLines.count == 0 {
                if startMagnetPoint.shouldAttract(current,
                        withTengentialDirection: MXNFreeVector(start: current, end: startMagnetPoint.point)) {
                    if visualTesting { print("### attracted by start point") }
                    // go towards start point
                    let straight = straightlyTrackToPointFrom(current, to: startMagnetPoint.point)
                    currentLine.raw.appendContentsOf(straight)
                    meetsEndPoint = true
                    startMagnetPoint.directions.removeAll()
                }
            }
            
            // Junction detection
            if checkIfMeetsJunction((currentLeft,currentRight), lastEdge: (lastLeft, lastRight)) && !meetsEndPoint {
                if visualTesting { print("### meets protential junction point") }
                
                let result = findJunctionPointStartFrom(current, last: last)
                
                if let p = result.point, let dIndex = result.directionIndex {
                    if visualTesting { print("### found junction point, \(result.exist ? "exist" : "new")") }
            
                    if !result.exist { magnetPoints.append(p) }
                
                    let inDirection = p.directions[dIndex]
                    p.directions.removeAtIndex(dIndex)
                    
                    // go towards junctionPoint
                    let straight = straightlyTrackToPointFrom(current, to: result.point!.point)
                    if !straight.isEmpty { current = straight.last! }
                    if straight.count > 1 { last = straight[straight.endIndex-2] }
                    currentLine.raw.appendContentsOf(straight)
                
                    if let outDirectionIndex = smoothDirectionIndexFor(inDirection, of: p) {
                        let outDirection = p.directions[outDirectionIndex].poleValue
                        p.directions.removeAtIndex(outDirectionIndex)
                        let freeTrack = freelyTrackToDirectionFrom(current, to: outDirection, steps: 12)
                        if !freeTrack.isEmpty { current = freeTrack.last! }
                        last = p.point
                        currentLine.raw.appendContentsOf(freeTrack)
                    } else {
                        meetsEndPoint = true
                    }
                } else {
                    if result.directionCount <= 1 {
                        if visualTesting { print("### meets end point") }
                        meetsEndPoint = true
                    }
                }
            }
            
            // End point handling
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
        return (rawGeometric.raw.first ?? CGPointZero, rawGeometric.raw.first ?? CGPointZero, rawGeometric.raw.first ?? CGPointZero)
    }
    
    /// Check if current tracking point is meeting a junction ( or maybe an end )
    private func checkIfMeetsJunction(
        currentEdge: (left: CGPoint, right: CGPoint),
        lastEdge: (left: CGPoint, right: CGPoint)
    ) -> Bool {
        let new = tangentialDirectionOf(currentEdge.left)
            .angleWith(tangentialDirectionOf(currentEdge.right))
        let old = tangentialDirectionOf(lastEdge.left)
            .angleWith(tangentialDirectionOf(lastEdge.right))
        if currentEdge.left.distanceTo(currentEdge.right) - lastEdge.left.distanceTo(lastEdge.right) > 4 {
            return true
        }
        guard new > old else { return false }
        if case 35...180 = new { return true }
        return false
    }
    
    /// Get the edge point of current tracking point.
    private func edgePointsOf(point: CGPoint) -> (left: CGPoint, right: CGPoint) {
        var left = point
        var right = point
        let gradient = gradientDirectionOf(point) * CGFloat(0.2)
        if gradient.absolute == 0 { return (point, point) }
        while !rawData.isBackgroudAtPoint(left) { left = left + (-gradient) }
        while !rawData.isBackgroudAtPoint(right) { right = right + gradient }
        return (left, right)
    }
    
    /// Find next start point from magnetPoints.
    private func nextStartPoint() -> MagnetPoint? {
        for point in magnetPoints {
            if !point.directions.isEmpty { return point }
        }
        return nil
    }
    
    /// Find junction point, if nil, then it's an end.
    /// - Returns:
    /// point: The junction point, nil if not a junction point<br>
    /// exist: If a junction point already exists.<br>
    /// directionIndex: The direction's index the current point is entering the junction point.<br>
    /// directionCount: Used when its not a junction point.<br>
    private func findJunctionPointStartFrom(
        startPoint: CGPoint, last lastPoint: CGPoint
    ) -> (point: MagnetPoint?, exist: Bool, directionIndex: Int?, directionCount: Int) {
        var candidates = [JunctionPointCandidate]()
        let candidateCount = 6
        let step = 1
        var current = startPoint
        var last = lastPoint
        var tanLast = MXNFreeVector(start: last, end: current)
        var candidateA = [JunctionPointCandidate]()
        var candidateB = [JunctionPointCandidate]()
        
        for i in 1...step*candidateCount {
            let tanCurrent = tangentialDirectionOf(current)
            var s = !(tanLast • tanCurrent).isSignMinus
            last = current
            
            // Runge Kutta method
            let middle = current.interpolateSemiTowards(tanCurrent, forward: s)
            var tanMiddle = tangentialDirectionOf(middle)
            if tanMiddle.isZeroVector { tanMiddle = tanLast }
            s = !(tanLast • tanMiddle).isSignMinus
            current = current.interpolateTowards(tanMiddle, forward: s)
            tanLast = tanMiddle
            if i % step == 0 {
                if !rawData.isBackgroudAtPoint(current) {
                    candidateA.append(JunctionPointCandidate(point: current))
                }
            }
        }
        
        let tanDefault = MXNFreeVector(start: lastPoint, end: startPoint).normalized
        current = startPoint
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
        candidates.append(JunctionPointCandidate(point: startPoint))
        
        if candidates.isEmpty { return (nil, false, 0, 0) }
        
        // find if such MagnetPoint is already found
        for c in candidates {
            for p in magnetPoints {
                if c.point.distanceTo(p.point) <= 15 {
                    if (MXNFreeVector(start: lastPoint, end: startPoint) • MXNFreeVector(start: startPoint, end: p.point)).isSignMinus {
                        return (nil, false, 0, 2)
                    }
                    if visualTesting { print("### Magnet Point already exists: \(p.point)") }
                    return (p, true, inDirectionIndexFor(MXNFreeVector(start: startPoint, end: p.point), of: p), 0)
                }
            }
        }

        fetchLuminanceDistributionForCandidates(candidates)

        // filter the ones that have fewer directions than the others
        // also, select the one with lowest luminance value from previous result
        let directionCount = candidates.reduce(0, combine: { count, candidate in
            candidate.directions.count > count ? candidate.directions.count : count
        })
        
        // a junction point neeed more than 1 directions
        guard directionCount > 1 else { return (nil, false, 0, directionCount) }
        
        candidates = candidates.filter {
            $0.directions.count == directionCount
        } .sort {
            $0.leastLuminance < $1.leastLuminance
        }
        
        guard let junctionPoint = candidates.first else { return (nil, false, 0, directionCount) }
        
        if junctionPoint.magnetPoint.directions.count == 2
        && junctionPoint.directions[0].poleValue.angleWith(junctionPoint.directions[1].poleValue) > 120 {
            return (nil, false, 0, directionCount)
        }
        
        let inDirectionIndex = inDirectionIndexFor(MXNFreeVector(start: startPoint, end: junctionPoint.point),
            of: junctionPoint.magnetPoint)
        if visualTesting { print("### Junction Point: \(junctionPoint.magnetPoint.point)), count: \(directionCount)") }
        return (junctionPoint.magnetPoint, false, inDirectionIndex, directionCount)
    }

    private func fetchLuminanceDistributionForCandidates(candidates: [JunctionPointCandidate]) {
        let circCount = 72
        let distance = 30
        let stepScaleFactor: CGFloat = 0.5

        for c in candidates {
            var lumi = [CGFloat]()
            for i in 0..<circCount {
                var sum: CGFloat = 0
                let direction = (360 / circCount * i).normalizedVector
                var current = c.point
                var continuouslyMetWhiteCounter = 0
                var shouldIgnoreTheRest = false
                for _ in 1...distance {
                    current = current.interpolateTowards(direction * stepScaleFactor, forward: true)
                    if rawData.isBackgroudAtPoint(current) && !shouldIgnoreTheRest {
                        sum += 255
                        continuouslyMetWhiteCounter += 1
                    } else {
                        continuouslyMetWhiteCounter = 0
                    }
                    if continuouslyMetWhiteCounter > distance / 5 { shouldIgnoreTheRest = true }
                    if shouldIgnoreTheRest { sum += 255 }
                }
                sum /= CGFloat(distance)
                lumi.append(sum)
            }
            c.luminance = lumi // directions will be calculated
        }
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
    
    ///  Find the indirection for given direction vector, if a angle is small enough than return it, if not, return nil.
    private func inDirectionIndexFor(inDirection: MXNFreeVector, of point: MagnetPoint) -> Int? {
        var biggest: CGFloat = 0
        var index: Int? = nil
        var angle: CGFloat = 0
        for (n, direction) in point.directions.enumerate() {
            angle = inDirection.angleWith(direction.poleValue)
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
            if angle > 120 && angle > maxAngle {
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
        }
        if visualTesting { print("~~~ free tracking end") }
        return line
    }
    
    /// Correcting by moving a tracking position 0.2 pixel towards its center point.
    private func correctedPositionMidPointFor(point: CGPoint) -> (start: CGPoint, left: CGPoint, right: CGPoint) {
        let edges = edgePointsOf(point)
        let midPoint = CGPoint.centerPointOf(edges.left, and: edges.right)
        let v = MXNFreeVector(start: point, end: midPoint).normalized
        if rawData.isBackgroudAtPoint(midPoint) {
            return (point, edges.left, edges.right)
        }
        let new = point.interpolateTowards(v*CGFloat(0.2), forward: true)
        return (new, edges.left, edges.right)
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
    func bilinearInterporlation(
        this this: (x: CGFloat, y: CGFloat),
        bX: CGFloat, bY: CGFloat, eX: CGFloat, eY: CGFloat,
        bXbY: MXNFreeVector, bXeY: MXNFreeVector,
        eXbY: MXNFreeVector, eXeY:  MXNFreeVector
    ) -> MXNFreeVector {
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
                if result.yes { return true }
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
                calculateDeviation()
            }
        }
        // TODO: use luminance deviation to average, on maximun directions, not minimum.
        // I guess we can use center of each maximum directions as minimum directions, and check their luminance deviation to their average.
        var leastLuminance: CGFloat = 0
        var deviation: CGFloat = 0
        var angleIndexes = [Int]()
        var directions = [Direction2D]()
        
        init(point: CGPoint) {
            self.point = point
        }
        
        var magnetPoint: MagnetPoint {
            return MagnetPoint(point: point, directions: directions)
        }
        
        func calculateDirection() {
            guard !luminance.isEmpty else { return }
            angleIndexes = [Int]()
            
            // 2 times of gaussian blur
            var newLuminance = Array<CGFloat>.smoothingWithStandardGaussianBlurOn(luminance)
            newLuminance = Array<CGFloat>.smoothingWithStandardGaussianBlurOn(newLuminance)
            
            // fetch every minimum value from f(angle) = luminance
            for var i in 0..<newLuminance.count {
                let previousIndex = i - 1 >= 0 ? i-1 : newLuminance.endIndex-1
                let nextIndex = i + 1 >= newLuminance.endIndex ? 0 : i+1
                if newLuminance[i] < 100 && newLuminance[previousIndex] > newLuminance[i] && newLuminance[nextIndex] > newLuminance[i] {
                    angleIndexes.append(i)
                } else if newLuminance[i] < 100 && newLuminance[previousIndex] > newLuminance[i] && newLuminance[nextIndex] == newLuminance[i] {
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
        
        /// Taking the directions in the middle of each pair of correct directions, calculate the average of their luminance deviation to their luminance average, stores in `var deviation`.
        func calculateDeviation() {
            guard angleIndexes.count >= 2 else { return }
            var deviationIndexes = [Int]()
            for (i, index) in angleIndexes.enumerate() {
                var newIndex = 0
                if i == angleIndexes.endIndex - 1 {
                    let left = luminance.count - index - 1
                    let right = angleIndexes[0] + 1
                    let gap = (left + right) / 2
                    newIndex = left >= right ? index + gap : angleIndexes[0] - gap
                } else {
                    newIndex = (index + angleIndexes[i+1]) / 2
                }
                deviationIndexes.append(newIndex)
            }
            
            let average = deviationIndexes.reduce(CGFloat(0), combine: {
                return $0 + luminance[$1]
            }) / CGFloat(deviationIndexes.count)
            
            deviation = deviationIndexes.reduce(CGFloat(0), combine: {
                return $0 + abs(luminance[$1] - average)
            })
        }

    }
}






