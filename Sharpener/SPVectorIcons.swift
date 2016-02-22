//
//  SPVectorIcons.swift
//  Sharpener
//
//  Created by Inti Guo on 2/20/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import UIKit

class SPVectorIcon: UIView {
    
    enum Type: Int {
        case TrashBin, Gear, Category
    }
    
    var type: Type
    var fillColor: UIColor?
    var strokeColor: UIColor?
    var active: Bool = true {
        didSet {
            let alphaValue: CGFloat = active ? 1.0 : 0.7
            alpha = alphaValue
        }
    }
    private let defaultSize: CGFloat = 100
    
    var scaleFactor: CGFloat {
        return min(bounds.width, bounds.height) / defaultSize
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.type = .TrashBin
        fillColor = UIColor.blackColor()
        strokeColor = UIColor.blackColor()
        super.init(coder: aDecoder)
    }
    
    init(frame: CGRect, type: Type, fill: UIColor?, stroke: UIColor?) {
        self.type = type
        fillColor = fill
        strokeColor = stroke
        super.init(frame: frame)
        backgroundColor = UIColor.clearColor()
    }
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
        switch type {
        case .TrashBin:
            drawTrashBin()
        case .Gear:
            drawGear()
        case .Category:
            drawCategory()
        }
    }
    
    func drawTrashBin() {
        fillColor?.setFill()
        strokeColor?.setStroke()
        
    }
    
    func drawGear() {
        fillColor?.setFill()
        strokeColor?.setStroke()
        
        
    }
    
    func drawCategory() {
        fillColor?.setFill()
        strokeColor?.setStroke()
        
    }
}