//
//  SPBigProgressBar.swift
//  Sharpener
//
//  Created by Inti Guo on 2/20/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import UIKit

class SPBigProgressBar: UIView {
    
    var labelText: String? {
        get { return label.text }
        set { label.text = newValue }
    }
    
    var currentProgress: CGFloat = 0 {
        didSet {
            if progressBar != nil {
                progressBar.path =
                    UIBezierPath(rect: CGRect(x: 0, y: 0, width: currentProgress * bounds.width, height: bounds.height)).CGPath
            }
        }
    }
    
    var outline: CAShapeLayer! {
        didSet {
            layer.addSublayer(outline)
        }
    }
    var progressBar: CAShapeLayer! {
        didSet {
            layer.addSublayer(progressBar)
        }
    }
    
    var label: UILabel! {
        didSet {
            addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.snp_makeConstraints { make in
                make.center.equalTo(self)
            }
            
            label.text = "Not Set"
            label.font = UIFont.systemFontOfSize(17)
            
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        prepareLayers()
    }
    
    private func setup() {
        progressBar = CAShapeLayer()
        outline = CAShapeLayer()
        label = UILabel()
    }
    
    private func prepareLayers() {
        // outline 
        let opath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: bounds.width, height: 1))
        let opath2 = UIBezierPath(rect: CGRect(x: 0, y: bounds.height-1, width: bounds.width, height: 1))
        opath.appendPath(opath2)
        outline.path = opath.CGPath
        outline.fillColor = UIColor.spOutlineColor().CGColor
        
        // progressBar
        let ppath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: currentProgress * bounds.width, height: bounds.height))
        progressBar.path = ppath.CGPath
        progressBar.fillColor = UIColor.spGreenColor().CGColor
    }
}
