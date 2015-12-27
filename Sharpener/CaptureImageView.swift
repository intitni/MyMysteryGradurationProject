//
//  CaptureImageView.swift
//  Sharpener
//
//  Created by Inti Guo on 12/22/15.
//  Copyright © 2015 Inti Guo. All rights reserved.
//

import UIKit

class CaptureImageView: UIView {

    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
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
