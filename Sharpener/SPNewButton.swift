//
//  SPNewButton.swift
//  Sharpener
//
//  Created by Inti Guo on 2/22/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import UIKit

class SPNewButton: UIControl {

    var backgroundCircle: CAShapeLayer! {
        didSet {
            layer.addSublayer(backgroundCircle)
            let path = UIBezierPath(ovalInRect: CGRect(x: 0, y: 0, width: 70, height: 70))
            backgroundCircle.path = path.CGPath
            backgroundCircle.fillColor = UIColor.spOutlineColor().CGColor
            backgroundCircle.strokeColor = UIColor.spOutlineColor().CGColor
        }
    }

    var plus: CAShapeLayer! {
        didSet {
            layer.addSublayer(plus)
            let path = UIBezierPath()
            path ==> CGPoint(x: 25.5, y: 35.5)
            path --> CGPoint(x: 43.5, y: 35.5)
            path ==> CGPoint(x: 34.5, y: 26.5)
            path --> CGPoint(x: 34.5, y: 44.5)
            plus.path = path.CGPath
            plus.strokeColor = UIColor.spGreenColor().CGColor
            plus.lineWidth = 1
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
        backgroundColor = UIColor.clearColor()
        backgroundCircle = CAShapeLayer()
        plus = CAShapeLayer()
    }
    
    // MARK: Touch Behaviour
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        // shrink button a little bit while holding
        UIView.animateWithDuration(0.02, animations: {
            self.transform = CGAffineTransformMakeScale(0.9, 0.9)
        })
        super.touchesBegan(touches, withEvent: event)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        UIView.animateWithDuration(0.1, animations: {
            self.transform = CGAffineTransformIdentity
        }, completion: { finished in
            
        })
        super.touchesEnded(touches, withEvent: event)
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        UIView.animateWithDuration(0.1, animations: {
            self.transform = CGAffineTransformIdentity
        }, completion: { finished in
            super.touchesCancelled(touches, withEvent: event)
        })
    }
}
