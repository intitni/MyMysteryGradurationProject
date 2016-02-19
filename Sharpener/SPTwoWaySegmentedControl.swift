//
//  SPTwoWaySegmentedControl.swift
//  Sharpener
//
//  Created by Inti Guo on 2/19/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import UIKit

protocol SPTwoWaySegmentedControlDelegate: class {
    func twoWaySegmentedControlDidTapOnButtonWithIndex(index: Int)
    func performDragOutActionForButtonWithIndex(index: Int)
    var twoWaySegmentedControlButtonNames: (String, String) { get }
}

class SPTwoWaySegmentedControl: UIControl {
    
    enum Selection { case Left, Right }
    
    var selection: Selection = .Left {
        didSet {
            leftPart.selected = selection == .Left ? true : false
            rightPart.selected = selection == .Right ? true : false
        }
    }
    
    weak var buttonDelegate: SPTwoWaySegmentedControlDelegate? {
        didSet {
            if let b = buttonDelegate {
                leftPart.label.text = b.twoWaySegmentedControlButtonNames.0
                rightPart.label.text = b.twoWaySegmentedControlButtonNames.1
            }
        }
    }

    var leftPart: LeftPart! {
        didSet {
            addSubview(leftPart)
            let tap = UITapGestureRecognizer(target: self, action: "tappedOnLeftPart")
            leftPart.addGestureRecognizer(tap)
            
            leftPart.snp_makeConstraints { make in
                make.height.equalTo(self)
                make.width.equalTo(self).dividedBy(2)
                make.centerY.equalTo(self)
                make.left.equalTo(self)
            }
        }
    }
    var rightPart: RightPart! {
        didSet {
            addSubview(rightPart)
            let tap = UITapGestureRecognizer(target: self, action: "tappedOnRightPart")
            rightPart.addGestureRecognizer(tap)
            
            rightPart.snp_makeConstraints { make in
                make.height.equalTo(self)
                make.width.equalTo(self).dividedBy(2)
                make.centerY.equalTo(self)
                make.right.equalTo(self)
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
        leftPart = LeftPart()
        rightPart = RightPart()
    }
    
    func tappedOnLeftPart() {
        selection = .Left
        buttonDelegate?.twoWaySegmentedControlDidTapOnButtonWithIndex(0)
    }
    
    func tappedOnRightPart() {
        selection = .Right
        buttonDelegate?.twoWaySegmentedControlDidTapOnButtonWithIndex(1)
    }
}

extension SPTwoWaySegmentedControl {
    class LeftPart: UIView {
        
        var selected: Bool = true {
            didSet {
                innerPart.fillColor = selected ? UIColor.spRedColor().CGColor : UIColor.clearColor().CGColor
            }
        }
        
        var label: UILabel! {
            didSet {
                addSubview(label)
                label.snp_makeConstraints { make in
                    make.center.equalTo(self)
                }
                label.text = "NOT SET"
                label.textColor = UIColor.spOutlineColor()
                label.textAlignment = .Center
                label.font = UIFont.systemFontOfSize(17)
            }
        }
        
        var outline: CAShapeLayer! {
            didSet {
                outline.lineWidth = 2
                outline.strokeColor = UIColor.spOutlineColor().CGColor
                outline.fillColor = UIColor.clearColor().CGColor
                outline.backgroundColor = UIColor.clearColor().CGColor
                layer.addSublayer(outline)
            }
        }
        var innerPart: CAShapeLayer! {
            didSet {
                innerPart.lineWidth = 1
                innerPart.strokeColor = UIColor.spOutlineColor().CGColor
                innerPart.fillColor = UIColor.spRedColor().CGColor
                innerPart.backgroundColor = UIColor.clearColor().CGColor
                layer.addSublayer(innerPart)
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            prepareLayers()
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
            outline = CAShapeLayer()
            innerPart = CAShapeLayer()
            label = UILabel()
        }
        
        private func prepareLayers() {
            let d = 70
            let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: [.TopLeft, .BottomLeft], cornerRadii: CGSize(width: d/2, height: d/2))
            outline.path = path.CGPath
            
            
            let od: CGFloat = 60
            let path2 = UIBezierPath(roundedRect: CGRect(x: 5, y: 5, width: bounds.size.width-5, height: od), byRoundingCorners: [.TopLeft, .BottomLeft], cornerRadii: CGSize(width: od/2, height: od/2))
            
            innerPart.path = path2.CGPath
        }


    }
    
    class RightPart: UIView {
        
        var selected: Bool = false {
            didSet {
                innerPart.fillColor = selected ? UIColor.spGreenColor().CGColor : UIColor.clearColor().CGColor
            }
        }
        
        var label: UILabel! {
            didSet {
                addSubview(label)
                label.snp_makeConstraints { make in
                    make.center.equalTo(self)
                }
                label.text = "NOT SET"
                label.textColor = UIColor.spOutlineColor()
                label.textAlignment = .Center
                label.font = UIFont.systemFontOfSize(17)
            }
        }
        
        var outline: CAShapeLayer! {
            didSet {
                outline.lineWidth = 2
                outline.strokeColor = UIColor.spOutlineColor().CGColor
                outline.fillColor = UIColor.clearColor().CGColor
                outline.backgroundColor = UIColor.clearColor().CGColor
                layer.addSublayer(outline)
            }
        }
        var innerPart: CAShapeLayer! {
            didSet {
                innerPart.lineWidth = 1
                innerPart.strokeColor = UIColor.spOutlineColor().CGColor
                innerPart.fillColor = UIColor.clearColor().CGColor
                innerPart.backgroundColor = UIColor.clearColor().CGColor
                layer.addSublayer(innerPart)
            }
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            prepareLayers()
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
            outline = CAShapeLayer()
            innerPart = CAShapeLayer()
            label = UILabel()
        }
        
        private func prepareLayers() {
            let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: [.TopRight, .BottomRight], cornerRadii: CGSize(width: bounds.size.height/2, height: bounds.size.height/2))
            outline.path = path.CGPath
            
            let d: CGFloat = 60
            let path2 = UIBezierPath(roundedRect: CGRect(x: 0, y: 5, width: bounds.size.width-5, height: d), byRoundingCorners: [.TopRight, .BottomRight], cornerRadii: CGSize(width: d/2, height: d/2))
            
            innerPart.path = path2.CGPath
        }
    }
}

