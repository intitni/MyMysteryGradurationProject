//
//  XNUsefuls.swift
//  Sharpener
//
//  Created by Inti Guo on 1/17/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation
import UIKit

// MARK: - AppConfigurations

/// Please firstly set it in Target ~> Build Settings ~> Swift Compiler - Custom Flags ~> Other Swift Flags, by adding strings like `"-DDEBUG", "-DRELEASE"` to relating app configurations.
/// - DEBUG: Dev or Debug build.
/// - RELEASE: Release build that will be submitted to the App Store
/// - ALPHA: Privately test release.
/// - BETA: Public test release. 
enum AppConfigurations {
    case DEBUG,RELEASE,ALPHA,BETA
}

/// Returns true when DEBUG
var IS_DEBUG: Bool {
    #if DEBUG
    return true
    #else
    return false
    #endif
}

/// Returns true when RELEASE
var IS_RELEASE: Bool {
    #if RELEASE
        return true
    #else
        return false
    #endif
}

/// Returns true when ALPHA
var IS_ALPHA: Bool {
    #if ALPHA
        return true
    #else
        return false
    #endif
}

/// Returns true when BETA
var IS_BETA: Bool {
    #if BETA
        return true
    #else
        return false
    #endif
}

/// Perform a block only when DEBUG
func performWhenDebug(block: ()->Void) { if IS_DEBUG { block() } }
/// Perform a block only when RELEASE
func performWhenRelease(block: ()->Void) { if IS_RELEASE { block() } }
/// Perform blocks according to app configuration
func performAccordingToAppConfiguration(debug blockDebug: ()->Void, release blockRelease: ()->Void) {
    performWhenDebug(blockDebug)
    performWhenRelease(blockRelease)
}

func delay(delay:Double, closure:()->Void) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}


// MARK: - Debug Syntax Candy

infix operator <!> { associativity left precedence 200 }
infix operator <?> { associativity left precedence 200 }

/// Force unwrap with custom fatalError message
func <!><T>(wrapped: T?, @autoclosure failureText: ()->String) -> T {
    if let x = wrapped { return x }
    fatalError(failureText())
}

/// Safely force unwrap with assertion
func <?><T>(wrapped: T?, @autoclosure failure: ()->(value: T, text: String)) -> T {
    assert(wrapped != nil, failure().text)
    return wrapped ?? failure().value
}

// MARK: - Random Number Generating

extension Int {
    /// Generate random Int between given range
    static func random(range: Range<Int>) -> Int {
        guard let first = range.first, let last = range.last else { return 0 }
        return Int(arc4random() % UInt32(last - first) + 1) + first
    }
}

// MARK: - Percentage

postfix operator % {}

/// Percentage
postfix func %(num: Int) -> Double {
    return Double(num) / 100.0
}
/// Percentage
postfix func %(num: Float) -> Double {
    return Double(num) / 100.0
}
/// Percentage
postfix func %(num: Double) -> Double {
    return num / 100.0
}

// MARK: - Simpler Comparison Condition

infix operator <*> {}
func <*><T: SignedNumberType>(elem: T, range: HalfOpenInterval<T>) -> Bool {
    if elem < range.start || elem > range.end {
        return false
    }
    return true
}
func <*><T: SignedNumberType>(elem: T, range: ClosedInterval<T>) -> Bool {
    if elem < range.start || elem > range.end {
        return false
    }
    return true
}

//  MARK: - UILabel Text Change Animation

extension UILabel {
    
    /// The text changing animation of UILabel
    static var textChangeAnimation = CATransition() {
        didSet {
            textChangeAnimation.duration = 0.10;
            textChangeAnimation.type = kCATransitionFade;
        }
    }
    
    /// Changing the text of a UILabel, with or without animation.
    func setText(text: String, withAnimation: Bool) {
        if withAnimation {
            layer.addAnimation(UILabel.textChangeAnimation, forKey: "changeTextTransition")
            self.text = text
        } else {
            self.text = text
        }
    }
}

// MARK: - UIView Snapshot

extension UIView {
    
    /// Getting a snapshot in UIImage of this UIView cropped in a given rect.
    func snapshotInRect(rect: CGRect) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(frame.size, false, 0)
        self.drawViewHierarchyInRect(frame, afterScreenUpdates: true)
        let im = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let rectTransform = CGAffineTransformMakeScale(im.scale, im.scale)
        let cropim = CGImageCreateWithImageInRect(im.CGImage, CGRectApplyAffineTransform(rect, rectTransform))
        let crop = UIImage(CGImage: cropim!, scale: im.scale, orientation: im.imageOrientation)
        
        return crop
    }
}

// MARK: - UIImage Resizing

extension UIImage {
    
    func scaledImageToSize(scaleFactor: CGFloat) -> UIImage {
        let newSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)
        return resizedImageToSize(newSize)
    }
    
    func resizedImageToSize(newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        
        self.drawInRect(CGRectMake(0, 0, newSize.width, newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return newImage
    }
}

// MARK: - CGPoint CGRect CGSize  Scaled Property

extension CGPoint {
    /// Returns a scaed CGPoint.
    func scaled(scale: CGFloat) -> CGPoint {
        return CGPoint(x: x * scale, y: y * scale)
    }

    static var zero: CGPoint { return CGPointZero }
}

extension CGRect {
    /// Returns a scaed CGRect.
    func scaled(scale: CGFloat) -> CGRect {
        return CGRect(x: origin.x * scale, y: origin.y * scale, width: width * scale, height: height * scale)
    }

    static var zero: CGRect { return CGRectZero }
}

extension CGSize {
    /// Returns a scaed CGSize.
    func scaled(scale: CGFloat) -> CGSize {
        return CGSize(width: width * scale, height: height * scale)
    }

    static var zero: CGSize { return CGSizeZero }
}

// MARK: - Bool

extension Bool {
    /// Toggling a Bool.
    mutating func toggle() {
        self = !self
    }
}

// MARK: - CGFloat

extension CGFloat {
    var isInteger: Bool {
        return floor(self) == self
    }
}

// MARK: - UIColor

extension UIColor {
    class func randomColor() -> UIColor {
        return UIColor(red: CGFloat(drand48()), green: CGFloat(drand48()), blue: CGFloat(drand48()), alpha: 1.0)
    }
}

// MARK: - UIBezierPath

infix operator ==> { associativity left precedence 130 }
infix operator --> { associativity left precedence 130 }
infix operator ~~> { associativity left precedence 130 }
infix operator ==% { associativity left precedence 130 }
postfix operator -->| {}

/// Close path
postfix func -->|(path: UIBezierPath) {
    path.closePath()
}

/// Move to point
func ==>(path: UIBezierPath, point: CGPoint) -> UIBezierPath {
    path.moveToPoint(point)
    return path
}

/// Add line to point
func -->(path: UIBezierPath, point: CGPoint) -> UIBezierPath {
    path.addLineToPoint(point)
    return path
}

/// Add curve to UIBezierPath
func ~~>(path: UIBezierPath, curve: CubicBezierCurveAppendee) -> UIBezierPath {
    path.add(curve: curve)
    return path
}

/// Scaling a UIBezierPath
func ==%(path: UIBezierPath, scaleFactor: CGFloat) -> UIBezierPath {
    path.applyTransform(CGAffineTransformMakeScale(scaleFactor, scaleFactor))
    return path
}

extension UIBezierPath {
    func add(curve curve: CubicBezierCurveAppendee) {
        addCurveToPoint(curve.endPoint, controlPoint1: curve.controlPoint1, controlPoint2: curve.controlPoint2)
    }
}

/// The appendee for addCurve()
struct CubicBezierCurveAppendee {
    var endPoint: CGPoint
    var controlPoint1: CGPoint
    var controlPoint2: CGPoint

    func scaled(scaleFactor: CGFloat) -> CubicBezierCurveAppendee {
        return CubicBezierCurveAppendee(endPoint: endPoint.scaled(scaleFactor), controlPoint1: controlPoint1.scaled(scaleFactor), controlPoint2: controlPoint2.scaled(scaleFactor))
    }
}

// MARK: - Array

extension Array {
    func removedLast(n: Int) -> [Element] {
        var array = self
        for _ in 0..<n where array.count > 0 {
            array.removeLast()
        }
        return array
    }
}

extension SequenceType {
    /// Perform some actions on a SequenceType without mutating it.
    @warn_unused_result
    public func performed(@noescape performing: (Self) -> Void) -> Self {
        performing(self)
        return self
    }

    /// Returns an mutated SequenceType on it.
    @warn_unused_result
    public func mutated(@noescape mutatingWith mutating: (Self) -> Self) -> Self {
        return mutating(self)
    }
}
