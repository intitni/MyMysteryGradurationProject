//
//  TorchSwitcher.swift
//  Sharpener
//
//  Created by Inti Guo on 12/22/15.
//  Copyright © 2015 Inti Guo. All rights reserved.
//

import UIKit
import SnapKit

class TorchSwitcher: UIControl {
    enum State { case On, Off }
    var onOffState: State = .Off {
        didSet {
            stateLabel.text = onOffState == .On ? "ON" : "OFF"
            icon.state = onOffState == .On ? .On : .Off
        }
    }
    
    var icon: LightningIcon! {
        didSet {
            self.addSubview(icon)
            icon.snp_makeConstraints { make in
                make.size.equalTo(CGSize(width: 50, height: 50))
                make.left.equalTo(5)
                make.centerY.equalTo(self)
            }
        }
    }
    var stateLabel: UILabel! {
        didSet {
            self.addSubview(stateLabel)
            stateLabel.text = "OFF"
            stateLabel.snp_makeConstraints { make in
                make.centerY.equalTo(self)
                make.left.equalTo(self.icon.snp_right).offset(5)
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
    
    func setup() {
        icon = LightningIcon()
        stateLabel = UILabel()
    }
}

class LightningIcon: UIView {
    enum State { case On, Off }
    let defaultSize: CGSize = CGSize(width: 50, height: 50)
    var scaleFactor: CGFloat {
        return frame.width / defaultSize.width
    }
    
    var state: State = .Off {
        didSet {
            lightning.fillColor = fillColor.CGColor
            lightning.strokeColor = borderColor.CGColor
        }
    }
    
    var borderColor: UIColor {
        return state == .On ?
        UIColor(colorLiteralRed: 163/255, green: 139/255, blue: 78/255, alpha: 1) :
        UIColor.spOutlineColor()
    }
    var fillColor: UIColor {
        return state == .On ?
        UIColor.spYellowColor() :
        UIColor.spYellowColor().colorWithAlphaComponent(0.5)
    }
    
    var lightning: CAShapeLayer! {
        didSet {
            let path = UIBezierPath()
            path.moveToPoint(CGPoint(x: 25*scaleFactor, y: 16*scaleFactor))
            path.addLineToPoint(CGPoint(x: 25*scaleFactor, y: 23*scaleFactor))
            path.addLineToPoint(CGPoint(x: 31*scaleFactor, y: 23*scaleFactor))
            path.addLineToPoint(CGPoint(x: 25*scaleFactor, y: 27*scaleFactor))
            path.addLineToPoint(CGPoint(x: 19*scaleFactor, y: 27*scaleFactor))
            path.closePath()
            lightning.path = path.CGPath
            lightning.lineWidth = 1
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
    
    func setup() {
        lightning = CAShapeLayer()
        self.state = .Off
    }
}
