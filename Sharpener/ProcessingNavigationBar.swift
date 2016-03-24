//
//  ProcessingNavigationBar.swift
//  Sharpener
//
//  Created by Inti Guo on 12/29/15.
//  Copyright © 2015 Inti Guo. All rights reserved.
//

import UIKit

protocol ProcessingNavigationBarDelegate: class {
    func didTapOnNavigationBarButton(index: Int)
    var processingNavigationBarRightButtonText: String { get }
}

class ProcessingNavigationBar: UINavigationBar {
    
    var lowerBorder = UIView() {
        didSet {
            addSubview(lowerBorder)
            lowerBorder.translatesAutoresizingMaskIntoConstraints = false
            lowerBorder.snp_makeConstraints { make in
                make.bottom.equalTo(self)
                make.centerX.equalTo(self)
                make.width.equalTo(self)
                make.height.equalTo(1)
            }
            lowerBorder.backgroundColor = UIColor.spLightBorderColor()
        }
    }
    
    var backButton: SPBackButton! {
        didSet {
            let tap = UITapGestureRecognizer(target: self, action: #selector(ProcessingNavigationBar.tappedOnBackButton))
            backButton.addGestureRecognizer(tap)
            
            addSubview(backButton)
            backButton.translatesAutoresizingMaskIntoConstraints = false
            backButton.snp_makeConstraints { make in
                make.left.equalTo(12)
                make.centerY.equalTo(self)
                make.size.equalTo(backButton.defaultSize)
            }
        }
    }
    var actionButton: UIButton! {
        didSet {
            actionButton.enabled = false
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(ProcessingNavigationBar.tappedOnActionButton))
            actionButton.addGestureRecognizer(tap)
            
            addSubview(actionButton)
            actionButton.translatesAutoresizingMaskIntoConstraints = false
            actionButton.snp_makeConstraints { make in
                make.right.equalTo(-12)
                make.centerY.equalTo(self)
            }
            
            actionButton.setTitleColor(UIColor.spOutlineColor(), forState: .Normal)
            actionButton.setTitleColor(UIColor.spOutlineColor().colorWithAlphaComponent(0.5), forState: .Disabled)
        }
    }
    weak var buttonDelegate: ProcessingNavigationBarDelegate? {
        didSet {
            self.actionButton.setTitle(buttonDelegate?.processingNavigationBarRightButtonText,
                              forState: UIControlState.Normal)
        }
    }
    
    var actionButtonEnabled: Bool {
        get { return actionButton.enabled }
        set { actionButton.enabled = newValue }
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
        backButton = SPBackButton(frame: CGRectZero)
        actionButton = UIButton(frame: CGRectZero)
    }
    
    func tappedOnBackButton() {
        buttonDelegate?.didTapOnNavigationBarButton(0)
    }
    
    func tappedOnActionButton() {
        buttonDelegate?.didTapOnNavigationBarButton(1)
    }
}

class SPBackButton: UIView {
    
    var defaultSize: CGSize { return CGSize(width: 32, height: 23) }
    var scaleFactor: CGFloat {
        return bounds.height / defaultSize.height
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clearColor()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = UIColor.clearColor()
    }
    
    override func drawRect(rect: CGRect) {
        let p = UIBezierPath()
        
        p ==> CGPoint(x: 5, y: 11.5).scaled(scaleFactor)
        p --> CGPoint(x: 15, y: 4).scaled(scaleFactor)
        p --> CGPoint(x: 15, y: 19).scaled(scaleFactor)
        p-->|
        
        p.lineWidth = 1
        p.lineCapStyle = .Round
        
        let p2 = UIBezierPath()
        
        p2.lineWidth = 1
        p2.lineCapStyle = .Round
        
        p2 ==> CGPoint(x: 5, y: 11.5).scaled(scaleFactor)
        p2 --> CGPoint(x: 27, y: 11.5).scaled(scaleFactor)
        
        UIColor.spOutlineColor().setStroke()
        UIColor.spRedColor().setFill()
        
        p.fill()
        p.stroke()
        p2.stroke()
    }
}

class SPEditButton: UIView {
    var defaultSize: CGSize { return CGSize(width: 50, height: 50) }
    var scaleFactor: CGFloat {
        return bounds.height / defaultSize.height
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clearColor()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = UIColor.clearColor()
    }
    
    override func drawRect(rect: CGRect) {
        let p = UIBezierPath()
        
        p ==> CGPoint(x: 5, y: 11.5).scaled(scaleFactor)
        p --> CGPoint(x: 15, y: 4).scaled(scaleFactor)
        p --> CGPoint(x: 15, y: 19).scaled(scaleFactor)
        p-->|
        
        p.lineWidth = 1
        p.lineCapStyle = .Round
        
        let p2 = UIBezierPath()
        
        p2.lineWidth = 1
        p2.lineCapStyle = .Round
        
        p2 ==> CGPoint(x: 5, y: 11.5).scaled(scaleFactor)
        p2 --> CGPoint(x: 27, y: 11.5).scaled(scaleFactor)
        
        UIColor.spOutlineColor().setStroke()
        UIColor.spRedColor().setFill()
        
        p.fill()
        p.stroke()
        p2.stroke()
    }
}
