//
//  SPNavigationBar.swift
//  Sharpener
//
//  Created by Inti Guo on 2/22/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import UIKit

protocol SPNavigationBarDelegate: class {
    func navigationBarButtonTapped()
}

class SPNavigationBar: UIView {
    var title = UILabel() {
        didSet {
            title.text = "Sharpener"
            title.font = UIFont.systemFontOfSize(17)
            title.textColor = UIColor.spOutlineColor()
            title.textAlignment = .Center
            addSubview(title)
            title.snp_makeConstraints { make in
                make.center.equalTo(self).offset(UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0))
            }
        }
    }
    
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
    
    var actionButton: UIButton! {
        didSet {
            actionButton.enabled = false
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(SPNavigationBar.tappedOnActionButton))
            actionButton.addGestureRecognizer(tap)
            
            addSubview(actionButton)
            actionButton.translatesAutoresizingMaskIntoConstraints = false
            actionButton.snp_makeConstraints { make in
                make.right.equalTo(-12)
                make.centerY.equalTo(self).offset(UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0))
            }
            
            actionButton.setTitleColor(UIColor.spOutlineColor(), forState: .Normal)
            actionButton.setTitleColor(UIColor.spOutlineColor().colorWithAlphaComponent(0.5), forState: .Disabled)
        }
    }
    weak var buttonDelegate: SPNavigationBarDelegate?
    
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
        lowerBorder = UIView()
        title = UILabel()
        backgroundColor = UIColor.spGrayishWhiteColor()
        actionButton = UIButton(frame: CGRectZero)
    }

    
    func tappedOnActionButton() {
        buttonDelegate?.navigationBarButtonTapped()
    }

}
