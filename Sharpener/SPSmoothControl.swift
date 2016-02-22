//
//  SPSmoothControl.swift
//  Sharpener
//
//  Created by Inti Guo on 2/21/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import UIKit

class SPSmoothControl: UIControl {
    
    var smoothness: CGFloat = 0 {
        didSet {
            smoothness = floor(smoothness * CGFloat(100.0) + CGFloat(0.5)) / CGFloat(100.0)
            if smoothness > 1 { smoothness = 1 }
            if smoothness < 0 { smoothness = 0 }
            percentageIndicator.text = "\(smoothness)%"
        }
    }

    var curl: CAShapeLayer! {
        didSet {
            curlView.layer.addSublayer(curl)
        }
    }

    var indicator: CAShapeLayer! {
        didSet {
            curlView.layer.addSublayer(indicator)
        }
    }
    
    var curlView = UIView() {
        didSet {
            addSubview(curlView)
            curlView.translatesAutoresizingMaskIntoConstraints = false
            curlView.snp_makeConstraints { make in
                make.height.equalTo(self)
                make.left.equalTo(24)
                make.width.equalTo(260)
                make.centerY.equalTo(self)
            }
        }
    }
    
    var percentageIndicator = UILabel() {
        didSet {
            addSubview(percentageIndicator)
            percentageIndicator.translatesAutoresizingMaskIntoConstraints = false
            percentageIndicator.snp_makeConstraints { make in
                make.right.equalTo(-24)
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
        curl = CAShapeLayer()
        indicator = CAShapeLayer()
        bottomBorder = UIView()
        topBorder = UIView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutLayers()
    }
    
    private func layoutLayers() {
        
    }
}
