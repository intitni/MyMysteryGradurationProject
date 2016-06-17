//
//  SPGeometricCountingView.swift
//  Sharpener
//
//  Created by Inti Guo on 2/22/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import UIKit

class SPGeometricCountingView: UIView {
    
    var shapeCount: Int = 0 {
        didSet {
            shapeCountLabel?.text = "\(shapeCount)"
        }
    }
    var lineGroupCount: Int = 0 {
        didSet {
            lineGroupCountLabel?.text = "\(lineGroupCount)"
        }
    }

    var leftView: UIView! {
        didSet {
            addSubview(leftView)
            leftView.snp_makeConstraints { make in
                make.left.equalTo(self)
                make.top.equalTo(self)
                make.bottom.equalTo(self)
                make.width.equalTo(self).dividedBy(2)
            }
        }
    }
    
    var rightView: UIView! {
        didSet {
            addSubview(rightView)
            rightView.snp_makeConstraints { make in
                make.right.equalTo(self)
                make.top.equalTo(self)
                make.bottom.equalTo(self)
                make.width.equalTo(self).dividedBy(2)
            }
        }
    }
    
    var shapeTypeLabel: UILabel! {
        didSet {
            leftView.addSubview(shapeTypeLabel)
            shapeTypeLabel.snp_makeConstraints { make in
                make.centerX.equalTo(self.leftView)
                make.bottom.equalTo(-30)
            }
            shapeTypeLabel.text = "Shapes"
            shapeTypeLabel.font = UIFont.systemFontOfSize(20)
            shapeTypeLabel.textAlignment = .Center
            shapeTypeLabel.textColor = UIColor.spOutlineColor()
        }
    }
    
    var shapeCountLabel: UILabel! {
        didSet {
            leftView.addSubview(shapeCountLabel)
            shapeCountLabel.snp_makeConstraints { make in
                make.top.equalTo(30)
                make.centerX.equalTo(self.leftView)
            }
            shapeCountLabel.text = "0"
            shapeCountLabel.font = UIFont.systemFontOfSize(20)
            shapeCountLabel.textAlignment = .Center
            shapeCountLabel.textColor = UIColor.spOutlineColor()
        }
    }
    
    var lineGroupTypeLabel: UILabel! {
        didSet {
            rightView.addSubview(lineGroupTypeLabel)
            lineGroupTypeLabel.snp_makeConstraints { make in
                make.centerX.equalTo(self.rightView)
                make.bottom.equalTo(-30)
            }
            lineGroupTypeLabel.text = "Line Groups"
            lineGroupTypeLabel.font = UIFont.systemFontOfSize(20)
            lineGroupTypeLabel.textAlignment = .Center
            lineGroupTypeLabel.textColor = UIColor.spOutlineColor()
        }
    }
    
    var lineGroupCountLabel: UILabel! {
        didSet {
            rightView.addSubview(lineGroupCountLabel)
            lineGroupCountLabel.snp_makeConstraints { make in
                make.top.equalTo(30)
                make.centerX.equalTo(self.rightView)
            }
            lineGroupCountLabel.text = "0"
            lineGroupCountLabel.font = UIFont.systemFontOfSize(20)
            lineGroupCountLabel.textAlignment = .Center
            lineGroupCountLabel.textColor = UIColor.spOutlineColor()
        }
    }

    init() {
        super.init(frame: CGRectZero)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        leftView = UIView()
        rightView = UIView()
        shapeTypeLabel = UILabel()
        shapeCountLabel = UILabel()
        lineGroupCountLabel = UILabel()
        lineGroupTypeLabel = UILabel()
    }
}
