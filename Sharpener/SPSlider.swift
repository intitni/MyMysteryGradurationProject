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
    var sliderTag = "default"
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
            delegate?.sliderValueDidChangedTo(currentValue, forTag: sliderTag)
        }
    }
    var valueBoundHeight: Double = 0
    var animate: Bool = false
    var topIcon: Icon? {
        didSet {
            guard let i = topIcon else { return }
            addSubview(i)
            i.translatesAutoresizingMaskIntoConstraints = false
            i.snp_makeConstraints { make in
                make.centerX.equalTo(self)
                make.size.equalTo(i.defaultSize)
                make.top.equalTo(10)
            }
        }
    }
    var bottomIcon: Icon? {
        didSet {
            guard let i = bottomIcon else { return }
            addSubview(i)
            i.translatesAutoresizingMaskIntoConstraints = false
            i.snp_makeConstraints { make in
                make.centerX.equalTo(self)
                make.size.equalTo(i.defaultSize)
                make.bottom.equalTo(-10)
            }
        }
    }
    
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
        layoutIcons()
    }
    
    func layoutIcons() {
        // do nothing
    }

    func setupGestures() {
        fatalError("Did not implement setupGesture() for SPSlider sub class.")
    }
    
    class Icon: UIView {
        enum IconType { case ContrastHigh, ContrastLow, LineWidthHigh, LineWidthLow }
        var iconType: IconType
        let defaultSize: CGFloat = 18
        var scaleFactor: CGFloat {
            return frame.width / defaultSize
        }
        func sc(value: CGFloat) -> CGFloat { return value * scaleFactor }
        
        init(iconType: IconType) {
            self.iconType = iconType
            super.init(frame: CGRectZero)
            self.backgroundColor = UIColor.clearColor()
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func drawRect(rect: CGRect) {
            UIColor.spLightBorderColor().setStroke()
            switch iconType {
            case .ContrastLow:
                let path = UIBezierPath(roundedRect: CGRectMake(sc(1), sc(3), sc(16), sc(12)), cornerRadius: sc(2))
                let path2 = UIBezierPath(roundedRect: CGRectMake(sc(1), sc(3), sc(8), sc(12)),
                                         byRoundingCorners: [.TopLeft, .BottomLeft],
                                         cornerRadii: CGSizeMake(sc(2), sc(2)))
                path.lineWidth = 2
                path2.lineWidth = 2
                path.stroke()
                path2.stroke()
                UIColor.spLightBorderColor().colorWithAlphaComponent(0.3).setFill()
                path2.fill()
            case .ContrastHigh:
                let path = UIBezierPath(roundedRect: CGRectMake(sc(1), sc(3), sc(16), sc(12)), cornerRadius: sc(2))
                let path2 = UIBezierPath(roundedRect: CGRectMake(sc(1), sc(3), sc(8), sc(12)),
                    byRoundingCorners: [.TopLeft, .BottomLeft],
                    cornerRadii: CGSizeMake(sc(2), sc(2)))
                path.lineWidth = 2
                path2.lineWidth = 2
                path.stroke()
                path2.stroke()
                UIColor.spLightBorderColor().setFill()
                path2.fill()
            case .LineWidthHigh:
                let path = UIBezierPath(ovalInRect: CGRectMake(sc(1), sc(1), sc(16), sc(16)))
                path.lineWidth = 2
                path.stroke()
            case .LineWidthLow:
                let path = UIBezierPath(roundedRect: CGRectMake(sc(1), sc(7), sc(16), sc(4)), cornerRadius: sc(2))
                path.lineWidth = 2
                path.stroke()
            }
        }
    }
}



protocol SPSliderDelegate: class {
    func sliderValueDidChangedTo(value: Double, forTag tag: String)
}



class SPSliderValueIndicator: UIView {
    var indicator: CAShapeLayer! {
        didSet {
            let path = UIBezierPath(ovalInRect: self.bounds)
            indicator.path = path.CGPath
            indicator.fillColor = UIColor.spOutlineColor().CGColor
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


