//
//  TorchSwitcher.swift
//  Sharpener
//
//  Created by Inti Guo on 12/22/15.
//  Copyright © 2015 Inti Guo. All rights reserved.
//

import UIKit

class TorchSwitcher: UIControl {
    var onOffState: OnOff = .Off {
        didSet {
            stateLabel.setText(onOffState.descriptionUpperCased, withAnimation: true)
            icon.state = onOffState
        }
    }
    
    var icon: LightningIcon! {
        didSet {
            self.addSubview(icon)
            icon.snp_makeConstraints { make in
                make.size.equalTo(CGSize(width: 20, height: 50))
                make.left.equalTo(10)
                make.centerY.equalTo(self)
            }
        }
    }
    var stateLabel: UILabel! {
        didSet {
            self.addSubview(stateLabel)
            stateLabel.text = OnOff.Off.descriptionUpperCased
            stateLabel.font = UIFont.systemFontOfSize(12)
            stateLabel.textColor = UIColor.spOutlineColor()
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
        backgroundColor = UIColor.clearColor()
        icon = LightningIcon()
        stateLabel = UILabel()
    }
}

class LightningIcon: UIView {
    let defaultSize: CGSize = CGSize(width: 20, height: 50)
    var scaleFactor: CGFloat {
        return bounds.width / defaultSize.width
    }
    
    var state: OnOff = .Off {
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
            path ==> CGPoint(x: 10*scaleFactor, y: 15*scaleFactor)
            path --> CGPoint(x: 10*scaleFactor, y: 23*scaleFactor)
                 --> CGPoint(x: 16*scaleFactor, y: 23*scaleFactor)
                 --> CGPoint(x: 10*scaleFactor, y: 35*scaleFactor)
                 --> CGPoint(x: 10*scaleFactor, y: 27*scaleFactor)
                 --> CGPoint(x: 4*scaleFactor, y: 27*scaleFactor)
            path=>!
            lightning.path = path.CGPath
            lightning.lineWidth = 1
            layer.addSublayer(lightning)
        }
    }
    
    override func layoutSubviews() {
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setup() {
        lightning = CAShapeLayer()
        self.state = .Off
    }
}
