//
//  FilterControlView.swift
//  Sharpener
//
//  Created by Inti Guo on 12/27/15.
//  Copyright © 2015 Inti Guo. All rights reserved.
//

import UIKit

class FilterControlView: UIView {
    var thresholdSlider: SPContinuousSlider! {
        didSet {
            addSubview(thresholdSlider)
            thresholdSlider.snp_makeConstraints { make in
                make.bottom.equalTo(self)
                make.width.equalTo(18)
                make.left.equalTo(4)
                make.top.equalTo(self)
            }
        }
    }
    var lineWidthSlilder: SPStepSlider! {
        didSet {
            addSubview(lineWidthSlilder)
            lineWidthSlilder.snp_makeConstraints { make in
                make.bottom.equalTo(self)
                make.width.equalTo(18)
                make.right.equalTo(-4)
                make.top.equalTo(self)
            }
        }
    }
    
    init(frame: CGRect, threshold: Double, lineWidth: Int, gearCount: Int) {
        super.init(frame: frame)
        setup(threshold: threshold, lineWidth: lineWidth, gearCount: gearCount)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup(threshold: 0.5, lineWidth: 1, gearCount: 5)
    }
    
    func setup(threshold threshold: Double, lineWidth: Int, gearCount: Int) {
        backgroundColor = UIColor.clearColor()
        thresholdSlider = SPContinuousSlider(currentValue: threshold)
        lineWidthSlilder = SPStepSlider(currentGear: lineWidth, gearCount: gearCount)
        thresholdSlider.gestureHandleView = self
        lineWidthSlilder.gestureHandleView = self
    }
    
    override func drawRect(rect: CGRect) {
        let topBorder = UIBezierPath()
        topBorder.moveToPoint(CGPointMake(0, 0))
        topBorder.addLineToPoint(CGPointMake(bounds.width, 0))
        let bottomBorder = UIBezierPath()
        bottomBorder.moveToPoint(CGPointMake(0, bounds.height))
        bottomBorder.addLineToPoint(CGPointMake(bounds.width, bounds.height))
        topBorder.lineWidth = 1
        bottomBorder.lineWidth = 1
        
        UIColor.spLightBorderColor().setStroke()
        topBorder.stroke()
        bottomBorder.stroke()
    }
}
