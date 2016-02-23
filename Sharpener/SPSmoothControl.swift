//
//  SPSmoothControl.swift
//  Sharpener
//
//  Created by Inti Guo on 2/21/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import UIKit

protocol SPSmoothControlDelegate: class {
    func smoothnessChangedTo(smoothness: CGFloat)
}

class SPSmoothControl: UIControl {
    
    var smoothDelegate: SPSmoothControlDelegate?
    
    var smoothness: CGFloat = 0 {
        didSet {
            smoothness = floor(smoothness * CGFloat(100.0) + CGFloat(0.5)) / CGFloat(100.0)
            if smoothness > 1 { smoothness = 1 }
            if smoothness < 0 { smoothness = 0 }
            percentageIndicator.text = "\(Int(smoothness*100))%"
            let translation = 245 * smoothness
            let indicatorTransform = CATransform3DMakeTranslation(translation, 0, 0)
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            indicator?.transform = indicatorTransform
            CATransaction.commit()
        }
    }

    var curl: CAShapeLayer! {
        didSet {
            curlView.layer.addSublayer(curl)
            let path = UIBezierPath()
            path ==> CGPoint(x: 1, y: 13)
            path ~~> SPAnchorPoint(point: CGPoint(x: 15, y: 37), controlPointA: CGPoint(x: 11, y: 13), controlPointB: CGPoint(x: 10, y: 37))
            path ~~> SPAnchorPoint(point: CGPoint(x: 29, y: 13), controlPointA: CGPoint(x: 20, y: 37), controlPointB: CGPoint(x: 22, y: 13))
            path ~~> SPAnchorPoint(point: CGPoint(x: 41, y: 34), controlPointA: CGPoint(x: 36, y: 13), controlPointB: CGPoint(x: 37, y: 34))
            path ~~> SPAnchorPoint(point: CGPoint(x: 62, y: 17), controlPointA: CGPoint(x: 46, y: 34), controlPointB: CGPoint(x: 55, y: 17))
            path ~~> SPAnchorPoint(point: CGPoint(x: 89, y: 32), controlPointA: CGPoint(x: 69, y: 17), controlPointB: CGPoint(x: 77, y: 32))
            path ~~> SPAnchorPoint(point: CGPoint(x: 135, y: 21), controlPointA: CGPoint(x: 102, y: 32), controlPointB: CGPoint(x: 120, y: 21))
            path ~~> SPAnchorPoint(point: CGPoint(x: 180, y: 28), controlPointA: CGPoint(x: 150, y: 21), controlPointB: CGPoint(x: 162, y: 28))
            path ~~> SPAnchorPoint(point: CGPoint(x: 245, y: 26), controlPointA: CGPoint(x: 196, y: 28), controlPointB: CGPoint(x: 235, y: 26))
            
            curl.path = path.CGPath
            curl.strokeColor = UIColor.spOutlineColor().CGColor
            curl.lineWidth = 2
            curl.fillColor = UIColor.clearColor().CGColor
            curl.lineCap = kCALineCapRound
        }
    }

    var indicator: CAShapeLayer! {
        didSet {
            curlView.layer.addSublayer(indicator)
            let path = UIBezierPath()
            path ==> CGPoint(x: -8, y: 0)
            path --> CGPoint(x: 8, y: 0)
            path --> CGPoint(x: 0, y: 11)
            path-->|
            
            path ==> CGPoint(x: 0, y: 9)
            path --> CGPoint(x: 0, y: 50)
            
            indicator.path = path.CGPath
            indicator.strokeColor = UIColor.spOutlineColor().CGColor
            indicator.lineWidth = 1
            indicator.fillColor = UIColor.spOutlineColor().CGColor
        }
    }
    
    var curlView: UIView! {
        didSet {
            addSubview(curlView)
            curlView.translatesAutoresizingMaskIntoConstraints = false
            curlView.snp_makeConstraints { make in
                make.height.equalTo(self)
                make.left.equalTo(30)
                make.width.equalTo(246)
                make.centerY.equalTo(self)
            }
        }
    }
    
    var percentageIndicator: UILabel! {
        didSet {
            addSubview(percentageIndicator)
            percentageIndicator.translatesAutoresizingMaskIntoConstraints = false
            percentageIndicator.snp_makeConstraints { make in
                make.right.equalTo(-30)
                make.centerY.equalTo(self)
            }
            percentageIndicator.font = UIFont.systemFontOfSize(20)
            percentageIndicator.textAlignment = .Right
            percentageIndicator.text = "0%"
        }
    }
    
    var bottomBorder: UIView! {
        didSet {
            bottomBorder.backgroundColor = UIColor.spOutlineColor()
            addSubview(bottomBorder)
            bottomBorder.snp_makeConstraints { make in
                make.bottom.equalTo(self)
                make.width.equalTo(self)
                make.centerX.equalTo(self)
                make.height.equalTo(1)
            }
        }
    }
    
    var topBorder: UIView! {
        didSet {
            topBorder.backgroundColor = UIColor.spLightBorderColor()
            addSubview(topBorder)
            topBorder.snp_makeConstraints { make in
                make.top.equalTo(self)
                make.width.equalTo(self)
                make.centerX.equalTo(self)
                make.height.equalTo(1)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        curlView = UIView()
        curl = CAShapeLayer()
        indicator = CAShapeLayer()
        bottomBorder = UIView()
        topBorder = UIView()
        percentageIndicator = UILabel()
        clipsToBounds = true
        
        backgroundColor = UIColor.spGrayishWhiteColor()
        let pan = UIPanGestureRecognizer(target: self, action: "pan:")
        addGestureRecognizer(pan)
    }
    
    func pan(recognizer: UIPanGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Changed {
            let t = recognizer.translationInView(recognizer.view?.superview).x
            let percentage = t / bounds.width
            smoothness += percentage
            recognizer.setTranslation(CGPointZero, inView: recognizer.view?.superview)
        } else if recognizer.state == UIGestureRecognizerState.Ended {
            smoothDelegate?.smoothnessChangedTo(smoothness)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutLayers()
    }
    
    private func layoutLayers() {
        
    }
}
