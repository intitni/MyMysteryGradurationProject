//
//  SPDetailToolBar.swift
//  Sharpener
//
//  Created by Inti Guo on 2/23/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import UIKit

class SPDetailToolBar: UIView {

    var upperBorder: UIView! {
        didSet {
            addSubview(upperBorder)
            upperBorder.translatesAutoresizingMaskIntoConstraints = false
            upperBorder.snp_makeConstraints { make in
                make.top.equalTo(self)
                make.centerX.equalTo(self)
                make.width.equalTo(self)
                make.height.equalTo(1)
            }
            upperBorder.backgroundColor = UIColor.spLightBorderColor()
        }
    }
    
    var leftPart: UIView! {
        didSet {
            addSubview(leftPart)
            leftPart.snp_makeConstraints { make in
                make.left.equalTo(self)
                make.top.equalTo(self)
                make.bottom.equalTo(self)
                make.width.equalTo(self).dividedBy(2)
            }
        }
    }
    
    var rightPart: UIView! {
        didSet {
            addSubview(rightPart)
            rightPart.snp_makeConstraints { make in
                make.right.equalTo(self)
                make.top.equalTo(self)
                make.bottom.equalTo(self)
                make.width.equalTo(self).dividedBy(2)
            }
        }
    }
    
    var deleteButton: SPVectorIcon! {
        didSet {
            leftPart.addSubview(deleteButton)
            deleteButton.snp_makeConstraints { make in
                make.center.equalTo(leftPart)
                make.size.equalTo(50)
            }
        }
    }
    
    var shareButton: SPVectorIcon! {
        didSet {
            rightPart.addSubview(shareButton)
            shareButton.snp_makeConstraints { make in
                make.center.equalTo(rightPart)
                make.size.equalTo(50)
            }
        }
    }

    
    init() {
        super.init(frame: CGRectZero)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        backgroundColor = UIColor.spGrayishWhiteColor()
        upperBorder = UIView()
        leftPart = UIView()
        rightPart = UIView()
        deleteButton = SPVectorIcon(frame: CGRectZero, type: .TrashBin, fill: nil, stroke: UIColor.spOutlineColor())
        shareButton = SPVectorIcon(frame: CGRectZero, type: .Share, fill: nil, stroke: UIColor.spOutlineColor())
    }
}
