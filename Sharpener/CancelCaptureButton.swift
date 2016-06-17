//
//  CancelCaptureButton.swift
//  Sharpener
//
//  Created by Inti Guo on 2/23/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import UIKit

class CancelCaptureButton: UIView {

    override func drawRect(rect: CGRect) {
        let path = UIBezierPath()
        path ==> CGPoint(x: 34, y: 34)
        path --> CGPoint(x: 17, y: 17)
        
        path ==> CGPoint(x: 34, y: 17)
        path --> CGPoint(x: 17, y: 34)
        
        UIColor.spOutlineColor().setStroke()
        
        path.lineWidth = 1
        path.lineCapStyle = .Round
        
        path.stroke()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    func setup() {
        backgroundColor = UIColor.clearColor()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
}
