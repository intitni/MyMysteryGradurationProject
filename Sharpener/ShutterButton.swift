//
//  ShutterButton.swift
//  Sharpener
//
//  Created by Inti Guo on 12/22/15.
//  Copyright © 2015 Inti Guo. All rights reserved.
//

import UIKit

@IBDesignable
class ShutterButton: UIControl {
    var outline: CAShapeLayer! {
        didSet {
            let d: CGFloat = 70
            let path = UIBezierPath(ovalInRect: CGRectMake(0, 0, d, d))
            outline.path = path.CGPath
            outline.lineWidth = 2
            outline.strokeColor = UIColor.spOutlineColor().CGColor
            outline.fillColor = UIColor.clearColor().CGColor
            layer.addSublayer(outline)
        }
    }
    var innerPart: CAShapeLayer! {
        didSet {
            let od: CGFloat = 70
            let d: CGFloat = 60
            let path = UIBezierPath(ovalInRect: CGRectMake((od-d)/2, (od-d)/2, d, d))
            
            innerPart.path = path.CGPath
            innerPart.lineWidth = 1
            innerPart.strokeColor = UIColor.spOutlineColor().CGColor
            innerPart.fillColor = UIColor.spGreenColor().CGColor
            layer.addSublayer(innerPart)
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        outline.frame = bounds
        innerPart.frame = bounds
    }
    
    func setup() {
        outline = CAShapeLayer()
        innerPart = CAShapeLayer()
    }
}
