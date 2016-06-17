//
//  SPDetailNavigationBar.swift
//  Sharpener
//
//  Created by Inti Guo on 2/23/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import UIKit

class SPDetailNavigationBar: UIView {

    var title = UILabel() {
        didSet {
            title.text = "Detail"
            title.font = UIFont.systemFontOfSize(17)
            title.textColor = UIColor.spOutlineColor()
            title.textAlignment = .Center
            addSubview(title)
            title.snp_makeConstraints { make in
                make.center.equalTo(self).offset(UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0))
            }
        }
    }
    
    var lowerBorder: UIView! {
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
            let tap = UITapGestureRecognizer(target: self, action: #selector(SPDetailNavigationBar.tappedOnBackButton))
            backButton.addGestureRecognizer(tap)
            
            addSubview(backButton)
            backButton.translatesAutoresizingMaskIntoConstraints = false
            backButton.snp_makeConstraints { make in
                make.left.equalTo(12)
                make.centerY.equalTo(self).offset(UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0))
                make.size.equalTo(backButton.defaultSize)
            }
        }
    }
    
    weak var buttonDelegate: SPNavigationBarDelegate?
    
    
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
        backButton = SPBackButton(frame: CGRectZero)
    }
    
    func tappedOnBackButton() {
        buttonDelegate?.navigationBarButtonTapped()
    }
}
