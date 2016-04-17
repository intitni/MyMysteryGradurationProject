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
    func foundMagnetPoint(point: CGPoint)
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
    var noMagnetPointFound: Bool { return magnetPoints.isEmpty }
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
        var startDirection = tangentialDirectionOf(startPoint).direction
        var shouldTrackInvertly = true
        
        var last = startPoint
        var currentLeft = left, currentRight = right
        var lastLeft = left, lastRight = right
        var current = startPoint
        var lineAfterJunctionFound = SPLine()
        var lineBeforeJunctionFound = SPLine()
        lineBeforeJunctionFound<--current

        while lineAfterJunctionFound.raw.count < 20000 {
            let tanCurrent = tangentialDirectionOf(current)
            let tanLast = MXNFreeVector(start: last, end: current)
            last = current
            current = rkInterpolate(from: current, to: tanCurrent, lastDirection: tanLast)
            lastLeft = currentLeft; lastRight = currentRight
            (current, currentLeft, currentRight) = correctedPositionMidPointFor(current, last: last)

            /////////////////////////////////////////////
            if visualTesting {
                dispatch_async(GCD.mainQueue) {
                    self.testDelegate?.trackingToPoint(current)
                }
                NSThread.sleepForTimeInterval(0.05)
            }
            /////////////////////////////////////////////
            
            var meetsEndPoint = false
            if rawData.isBackgroudAtPoint(current) && rawData.isBackgroudAtPoint(last) {
                meetsEndPoint = true
            } else if noMagnetPointFound {
                lineBeforeJunctionFound<--current
            } else {
                lineAfterJunctionFound<--current
            }

            // First line loop handling
            if magnetPoints.count == 0
            && lineBeforeJunctionFound.raw.count > 10
            && startMagnetPoint.shouldAttract(current, withTengentialDirection: MXNFreeVector(start: current, end: startMagnetPoint.point))
            && checkIfConnected(forPoint: current, and: startMagnetPoint.point) {
                if visualTesting { print("### attracted by start point") }
                let straight = straightlyTrackToPointFrom(current, to: startMagnetPoint.point)
                lineBeforeJunctionFound.raw.appendContentsOf(straight)
                meetsEndPoint = true
                startMagnetPoint.directions.removeAll()
            }
            
            // junction detection
            if checkIfMeetsJunction((currentLeft,currentRight), lastEdge: (lastLeft, lastRight))
            && !meetsEndPoint
            && lineBeforeJunctionFound.raw.count > 3 {
                if visualTesting { print("### meets protential junction point") }

                var lastPointForJunctionDetection = last
                var currentPointForJunctionDetection = current
                if noMagnetPointFound {
                    let countMinus = lineBeforeJunctionFound.raw.count <= 5 ? lineBeforeJunctionFound.raw.count : 6
                    if lineBeforeJunctionFound.raw.count > 5 { lastPointForJunctionDetection = lineBeforeJunctionFound.raw[lineBeforeJunctionFound.raw.endIndex - countMinus] }
                    if lineBeforeJunctionFound.raw.count > 2 { currentPointForJunctionDetection = last }
                } else {
                    let countMinus = lineAfterJunctionFound.raw.count <= 5 ? lineAfterJunctionFound.raw.count : 6
                    if lineAfterJunctionFound.raw.count > 5 { lastPointForJunctionDetection = lineAfterJunctionFound.raw[lineAfterJunctionFound.raw.endIndex - countMinus] }
                    if lineAfterJunctionFound.raw.count > 2 { currentPointForJunctionDetection = last }
                }

                let result = findJunctionPointStartFrom(currentPointForJunctionDetection, last: lastPointForJunctionDetection)
                
                if let p = result.point, let dIndex = result.directionIndex {
                    if visualTesting {
                        print("### found junction point, \(result.exist ? "exist" : "new")")
                        if !result.exist { testDelegate?.foundMagnetPoint((result.point?.point)!) }
                    }

                    if noMagnetPointFound {
                        startMagnetPoint = p
                        shouldTrackInvertly = true
                    }
                    if !result.exist { magnetPoints.append(p) }
                
                    let inDirection = p.directions[dIndex]
                    if result.exist || magnetPoints.count != 1 { p.directions.removeAtIndex(dIndex) }
                    
                    // go towards junctionPoint
                    let straight = straightlyTrackToPointFrom(current, to: result.point!.point)
                    if !straight.isEmpty { current = straight.last! }
                    if straight.count > 1 { last = straight[straight.endIndex-2] }
                    lineAfterJunctionFound.raw.appendContentsOf(straight)
                
                    if let outDirectionIndex = smoothDirectionIndexFor(inDirection, of: p) {
                        let outDirection = p.directions[outDirectionIndex].poleValue
                        p.directions.removeAtIndex(outDirectionIndex)
                        let freeTrack = freelyTrackToDirectionFrom(current, to: outDirection, steps: 15)
                        if !freeTrack.isEmpty { current = freeTrack.last! }
                        last = p.point
                        lineAfterJunctionFound.raw.appendContentsOf(freeTrack)
                    } else {
                        meetsEndPoint = true
                    }
                } else if result.directionCount <= 1 {
                    meetsEndPoint = true
                }
            }
            
            // end point handling
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
                        if noMagnetPointFound {
                            lineBeforeJunctionFound.raw = lineBeforeJunctionFound.raw.reverse()
                            lineBeforeJunctionFound.raw.appendContentsOf(free)
                        } else {
                            lineAfterJunctionFound.raw = lineAfterJunctionFound.raw.reverse()
                            lineAfterJunctionFound.raw.appendContentsOf(free)
                        }

                        needNewStartPoint = false
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
                    startDirection = Direction2D.Pole(vector: outDirection)
                    trackedLines.append(lineAfterJunctionFound)
                    lineAfterJunctionFound = SPLine()
                    lineAfterJunctionFound<--current
                    
                    startMagnetPoint = next
                	    
                    let free = freelyTrackToDirectionFrom(current, to: outDirection, steps: 15)
                    if !free.isEmpty { current = free.last! }
                    if free.count > 1 { last = free[free.endIndex-2] }
                    lineAfterJunctionFound.raw.appendContentsOf(free)
                } else {
                    // when start points are exausted.
                    if visualTesting { print("!!! end") }
                    if trackedLines.count == 0 { trackedLines.append(lineBeforeJunctionFound) }
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

    private func rkInterpolate(
        from current: CGPoint,
        to direction: MXNFreeVector, lastDirection: MXNFreeVector, scale: CGFloat = 1
    ) -> CGPoint {
        let middle = current.interpolateSemiTowards(direction * scale, forward: !(lastDirection • direction).isSignMinus)
        var tanMiddle = tangentialDirectionOf(middle)
        if tanMiddle.isZeroVector { tanMiddle = lastDirection }
        return current.interpolateTowards(tanMiddle * scale, forward: !(lastDirection • tanMiddle).isSignMinus)
    }

    /// Check if current tracking point is meeting a junction ( or maybe an end )
    private func checkIfMeetsJunction(
        currentEdge: (left: CGPoint, right: CGPoint),
        lastEdge: (left: CGPoint, right: CGPoint)
    ) -> Bool {
        let new = tangentialDirectionOf(currentEdge.left).angleWith(tangentialDirectionOf(currentEdge.right))
        let old = tangentialDirectionOf(lastEdge.left).angleWith(tangentialDirectionOf(lastEdge.right))
        if currentEdge.left.distanceTo(currentEdge.right) - lastEdge.left.distanceTo(lastEdge.right) > 2 {
            return true
        }
        if case 30...180 = new where new > old { return true }
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
        let candidateCount = 13
        let stepScale: CGFloat = 0.7
        var current = startPoint

        let tanDefault = MXNFreeVector(start: lastPoint, end: startPoint).normalized * stepScale
        let verticalOftanDefault = tanDefault.verticalVector
        for _ in 1...candidateCount {
            current = current.interpolateTowards(tanDefault, forward: true)
            let left = current.interpolateTowards(verticalOftanDefault, forward: true)
            let right = current.interpolateTowards(verticalOftanDefault, forward: false)
            if !rawData.isBackgroudAtPoint(current) {
                candidates.append(JunctionPointCandidate(point: current))
            }
            if !rawData.isBackgroudAtPoint(left) {
                candidates.append(JunctionPointCandidate(point: left))
            }
            if !rawData.isBackgroudAtPoint(right) {
                candidates.append(JunctionPointCandidate(point: right))
            }
        }
        
        // find if such MagnetPoint is already found
        let closestMagnetPointResult = closestConnectedMagnetPoint(forPoint: startPoint, andLast: lastPoint)
        if let p = closestMagnetPointResult.point {
            if closestMagnetPointResult.distance <= 12 {
                if visualTesting { print("### Magnet Point already exists: \(p.point)") }
                return (p, true, inDirectionIndexFor(MXNFreeVector(start: lastPoint, end: p.point), of: p, shouldGuard: true), 0)
            }
        }
        if visualTesting {
            print("\(candidates.count) candidates found")
        }
        fetchLuminanceDistributionForCandidates(candidates)

        // filter the ones that have fewer directions than the others
        // also, select the one with lowest luminance value from previous result
        let directionCount = candidates.reduce(0) { count, candidate in
            candidate.directions.count > count ? candidate.directions.count : count
        }
        if visualTesting {
            print("max direction count: \(directionCount)")
        }

        var leastLuminance: CGFloat = 255
        
        candidates = candidates.filter {
            $0.directions.count == directionCount
        } .sort {
            return $0.leastLuminance < $1.leastLuminance
        } .performed {
            if let first = $0.first { leastLuminance = first.leastLuminance }
        } .filter {
            $0.leastLuminance - leastLuminance < 5
        } .sort {
            $0.deviation < $1.deviation
        }
        
        guard let junctionPoint = candidates.first else { return (nil, false, 0, directionCount) }

        // a junction point neeed more than 1 directions
        guard directionCount > 1 else {
            if directionCount == 1
            && (MXNFreeVector(start: lastPoint, end: startPoint) • junctionPoint.directions.first!.poleValue).isSignMinus {
                return (nil, false, 0, directionCount)
            }
            return (nil, false, 0, 2)
        }
        
        if junctionPoint.magnetPoint.directions.count == 2
        && junctionPoint.directions[0].poleValue.angleWith(junctionPoint.directions[1].poleValue) > 120 {
            return (nil, false, 0, directionCount)
        }
        
        let inDirectionIndex = inDirectionIndexFor(MXNFreeVector(start: lastPoint, end: junctionPoint.point),
            of: junctionPoint.magnetPoint)

        if visualTesting { print("### Junction Point: \(junctionPoint.magnetPoint.point)), count: \(directionCount)") }
        return (junctionPoint.magnetPoint, false, inDirectionIndex, directionCount)
    }

    private func closestConnectedMagnetPoint(forPoint point: CGPoint, andLast last: CGPoint) -> (point: MagnetPoint?, distance: CGFloat) {
        var shortestDistancePow2: CGFloat = 244
        var matchedMagnetPoint: MagnetPoint? = nil
        for p in magnetPoints {
            let distance = point.distancePow2To(p.point)

            // point with shorter distance, not lying behind, connected.
            if distance <= shortestDistancePow2
            && !(MXNFreeVector(start: last, end: point) • MXNFreeVector(start: point, end: p.point)).isSignMinus
            && checkIfConnected(forPoint: point, and: p.point) {
                shortestDistancePow2 = distance
                matchedMagnetPoint = p
            }
        }
        return (matchedMagnetPoint, sqrt(shortestDistancePow2))
    }

    private func checkIfConnected(forPoint point: CGPoint, and anotherPoint: CGPoint) -> Bool {
        let points = straightlyTrackToPointFrom(point, to: anotherPoint)
        for p in points {
            if rawData.isBackgroudAtPoint(p) { return false }
        }
        return true
    }

    private func fetchLuminanceDistributionForCandidates(candidates: [JunctionPointCandidate]) {
        let circCount = 72
        let distance = 40
        let stepScaleFactor: CGFloat = 0.8

        for c in candidates {
            var lumi = [CGFloat]()
            for i in 0..<circCount {
                var sum: CGFloat = 0
                let direction = (360 / circCount * i).normalizedVector
                var current = c.point
                var continuouslyMetWhiteCounter = 0
                var shouldIgnoreTheRest = false
                var counter = 0
                for _ in 1...distance {
                    counter += 1
                    current = current.interpolateTowards(direction * stepScaleFactor, forward: true)
                    if rawData.isBackgroudAtPoint(current) && !shouldIgnoreTheRest {
                        sum += 255
                        continuouslyMetWhiteCounter += 1
                    } else {
                        continuouslyMetWhiteCounter = 0
                    }
                    if continuouslyMetWhiteCounter > 2 { shouldIgnoreTheRest = true }
                    if shouldIgnoreTheRest {
                        sum += 255 * CGFloat(distance - counter)
                        break
                    }
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
        var maxIndex: Int? = nil
        var maxAngle: CGFloat = 0
        for (n, direction) in point.directions.enumerate() {
            let angle = directionVector.angleWith(direction.poleValue)
            if angle > 140 && angle > maxAngle {
                maxAngle = angle
                maxIndex = n
            }
        }
        
        return maxIndex
    }
    
    ///  Find the indirection for given direction vector, if a angle is small enough than return it, if not, return nil.
    private func inDirectionIndexFor(inDirection: MXNFreeVector, of point: MagnetPoint, shouldGuard: Bool = false) -> Int? {
        var maxAngle: CGFloat = 0
        var maxIndex: Int? = nil
        for (n, direction) in point.directions.enumerate() {
            let angle = inDirection.angleWith(direction.poleValue)
            if angle > maxAngle {
                maxAngle = angle
                maxIndex = n
            }
        }
        return shouldGuard ? (maxAngle > 150 ? maxIndex : nil) : maxIndex
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
        var line = [CGPoint]()
        var point = current
        let direction = MXNFreeVector(start: current, end: target).normalized
        let distance = Int(current.distanceTo(target))
        if distance > 0 {
            for _ in 1..<distance {
                point = point + direction
                line.append(point)
            }
        }
        line.append(target)
        return line
    }
    
    private func freelyTrackToDirectionFrom(current: CGPoint, to direction: MXNFreeVector, steps: Int) -> [CGPoint] {
        if visualTesting { print("=== free tracking") }
        var line = [CGPoint]()
        var trackingPoint = current
        var last = current
        var creadability = 0
        var tanLast = direction
        for _ in 1...steps {
            if creadability > 7 {
                let tanCurrent = tangentialDirectionOf(trackingPoint)
                tanLast = MXNFreeVector(start: last, end: trackingPoint)
                last = trackingPoint
                trackingPoint = rkInterpolate(from: trackingPoint, to: tanCurrent, lastDirection: tanLast)
                (trackingPoint, _, _) = correctedPositionMidPointFor(trackingPoint, last: last)
            } else {
                last = trackingPoint
                trackingPoint = trackingPoint + direction
            }

            if rawData.isBackgroudAtPoint(trackingPoint) { break }
            line.append(trackingPoint)

            if line.count > 1 {
                let currentDirection = MXNFreeVector(start: last, end: trackingPoint)
                if currentDirection.angleWith(direction) < 30 {
                    creadability += 1
                } else {
                    creadability -= 1
                }
            }
        }
        if visualTesting { print("~~~ free tracking end") }
        return line
    }
    
    /// Correcting by moving a tracking position 0.2 pixel towards its center point.
    private func correctedPositionMidPointFor(point: CGPoint, last: CGPoint)
    -> (start: CGPoint, left: CGPoint, right: CGPoint) {
        let edges = edgePointsOf(point)
        let midPoint = CGPoint.centerPointOf(edges.left, and: edges.right)
        let v = MXNFreeVector(start: point, end: midPoint)
        if rawData.isBackgroudAtPoint(midPoint) {
            return (point, edges.left, edges.right)
        }
        let new = point.interpolateTowards(v*CGFloat(0.5), forward: true)
        if rawData.isBackgroudAtPoint(new) {
            return (point, edges.left, edges.right)
        }
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
        let attractZoneRadiusPow2: CGFloat = 50
        
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
        var newLuminance = [CGFloat]()
        
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
            newLuminance = Array<CGFloat>.smoothingWithStandardGaussianBlurOn(luminance)
            newLuminance = Array<CGFloat>.smoothingWithStandardGaussianBlurOn(newLuminance)
            
            // fetch every minimum value from f(angle) = luminance
            for var i in 0..<newLuminance.count {
                let previousIndex = i - 1 >= 0 ? i-1 : newLuminance.endIndex-1
                let nextIndex = i + 1 >= newLuminance.endIndex ? 0 : i+1
                if newLuminance[i] < 80 && newLuminance[previousIndex] > newLuminance[i] && newLuminance[nextIndex] > newLuminance[i] {
                    angleIndexes.append(i)
                } else if newLuminance[i] < 80 && newLuminance[previousIndex] > newLuminance[i] && newLuminance[nextIndex] == newLuminance[i] {
                    var count = 0
                    var next = i + 1 >= newLuminance.endIndex ? 0 : i+1
                    while next != i {
                        count += 1
                        if newLuminance[next] > newLuminance[i] {
                            if i+count/2 < newLuminance.count { angleIndexes.append(i+count/2) }
                            else { angleIndexes.append(i+count/2 - newLuminance.count) }
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
            } / CGFloat(angleIndexes.count)
            
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
                $0 + luminance[$1]
            }) / CGFloat(deviationIndexes.count)
            
            deviation = deviationIndexes.reduce(CGFloat(0), combine: {
                $0 + abs(luminance[$1] - average)
            }) / CGFloat(deviationIndexes.count)
        }
    }
}






