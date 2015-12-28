//
//  SPSlider.swift
//  Sharpener
//
//  Created by Inti Guo on 12/27/15.
//  Copyright © 2015 Inti Guo. All rights reserved.
//

import UIKit
import SnapKit

class SPSlider: UIControl {

    weak var delegate: SPSliderDelegate?
    weak var gestureHandleView: UIView? {
        didSet {
            if gestureHandleView != nil { setupGestures() }
        }
    }
    var valueBound: UIView! {
        didSet {
            addSubview(valueBound)
            valueBound.translatesAutoresizingMaskIntoConstraints = false
            valueBound.snp_makeConstraints { make in
                make.height.equalTo(self).multipliedBy(0.7)
                make.center.equalTo(self)
                make.width.equalTo(self)
            }
        }
    }
    var sliderValueIndicator: SPSliderValueIndicator! {
        didSet {
            guard valueBound != nil else { return }
            valueBound.addSubview(sliderValueIndicator)
            sliderValueIndicator.translatesAutoresizingMaskIntoConstraints = false
            sliderValueIndicator.snp_makeConstraints { make in
                make.centerX.equalTo(valueBound)
                make.size.equalTo(8)
                make.top.equalTo(0).offset(-4)
            }
        }
    }
    var pole: SPSliderPole! {
        didSet {
            addSubview(pole)
            pole.snp_makeConstraints { make in
                make.height.equalTo(self)
                make.width.equalTo(2)
                make.center.equalTo(self)
            }
        }
    }
    let maxValue: Double = 1
    let minValue: Double = 0
    var currentValue: Double = 0.5 {
        didSet {
            if currentValue < 0 { currentValue = 0 }
            if currentValue > 1 { currentValue = 1 }
            if animate {
                UIView.animateWithDuration(0.1, animations: {
                    self.sliderValueIndicator.transform.ty = CGFloat((1.0-self.currentValue) * self.valueBoundHeight)
                })
            } else {
                sliderValueIndicator.transform.ty = CGFloat((1.0-currentValue) * valueBoundHeight)
            }
        }
    }
    var valueBoundHeight: Double = 0
    var animate: Bool = false
    
    init(currentValue: Double) {
        self.currentValue = currentValue
        super.init(frame: CGRectZero)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        pole = SPSliderPole()
        valueBound = UIView()
        sliderValueIndicator = SPSliderValueIndicator()
        valueBoundHeight = Double(bounds.height) * 0.7
        sliderValueIndicator.transform.ty = CGFloat((1.0-self.currentValue) * self.valueBoundHeight)
    }

    func setupGestures() {
        fatalError("Did not implement setupGesture() for SPSlider sub class.")
    }
}



protocol SPSliderDelegate: class {
    func sliderValueDidChangedTo(value: Float)
}



class SPSliderValueIndicator: UIView {
    var indicator: CAShapeLayer! {
        didSet {
            let path = UIBezierPath(ovalInRect: self.bounds)
            indicator.path = path.CGPath
            indicator.fillColor = UIColor.spLightBorderColor().CGColor
            layer.addSublayer(indicator)
        }
    }
    
    override func layoutSubviews() {
        indicator = CAShapeLayer()
    }
}

class SPSliderPole: UIView {
    var pole: CAShapeLayer! {
        didSet {
            let path = UIBezierPath(rect: self.bounds)
            pole.path = path.CGPath
            pole.fillColor = UIColor.spLightBorderColor().CGColor
            layer.addSublayer(pole)
        }
    }
    
    override func layoutSubviews() {
        pole = CAShapeLayer()
    }
}


