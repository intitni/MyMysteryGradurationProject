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
        case TrashBin, Share
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
        case .Share:
            drawShare()
        }
    }
    
    func drawTrashBin() {
        fillColor?.setFill()
        strokeColor?.setStroke()
        let pathA = UIBezierPath()
        let pathB = UIBezierPath()
        let pathC = UIBezierPath()
        
        pathA.moveToPoint(CGPointMake(16*2*scaleFactor, 16*2*scaleFactor))
        pathA.addLineToPoint(CGPointMake(34*2*scaleFactor, 16*2*scaleFactor))
        pathA.moveToPoint(CGPointMake(23*2*scaleFactor, 16*2*scaleFactor))
        pathA.addLineToPoint(CGPointMake(23*2*scaleFactor, 14*2*scaleFactor))
        pathA.addLineToPoint(CGPointMake(27*2*scaleFactor,14*2*scaleFactor))
        pathA.addLineToPoint(CGPointMake(27*2*scaleFactor,16*2*scaleFactor))
        pathB.moveToPoint(CGPointMake(25*2*scaleFactor, 21*2*scaleFactor))
        pathB.addLineToPoint(CGPointMake(25*2*scaleFactor, 31*2*scaleFactor))
        pathB.moveToPoint(CGPointMake(22*2*scaleFactor, 21*2*scaleFactor))
        pathB.addLineToPoint(CGPointMake(22*2*scaleFactor, 31*2*scaleFactor))
        pathB.moveToPoint(CGPointMake(28*2*scaleFactor, 21*2*scaleFactor))
        pathB.addLineToPoint(CGPointMake(28*2*scaleFactor, 31*2*scaleFactor))
        pathC.moveToPoint(CGPointMake(18*2*scaleFactor, 16*2*scaleFactor))
        pathC.addLineToPoint(CGPointMake(18*2*scaleFactor, 36*2*scaleFactor))
        pathC.addLineToPoint(CGPointMake(32*2*scaleFactor, 36*2*scaleFactor))
        pathC.addLineToPoint(CGPointMake(32*2*scaleFactor, 16*2*scaleFactor))
        
        pathA.lineWidth = 1
        pathA.lineCapStyle = .Round
        pathA.lineJoinStyle = .Round
        pathB.lineWidth = 1
        pathB.lineCapStyle = .Round
        pathB.lineJoinStyle = .Round
        pathC.lineWidth = 1
        pathC.lineCapStyle = .Round
        pathC.lineJoinStyle = .Round
        
        pathA.stroke()
        pathB.stroke()
        pathC.stroke()
    }
    
    func drawShare() {
        strokeColor?.setStroke()
        
        let path = UIBezierPath()
        path ==> CGPoint(x: 16, y: 24).scaled(scaleFactor*2)
        path --> CGPoint(x: 16, y: 34).scaled(scaleFactor*2)
        path --> CGPoint(x: 34, y: 34).scaled(scaleFactor*2)
        path --> CGPoint(x: 34, y: 24).scaled(scaleFactor*2)
        
        path ==> CGPoint(x: 19, y: 19).scaled(scaleFactor*2)
        path --> CGPoint(x: 25, y: 16).scaled(scaleFactor*2)
        path --> CGPoint(x: 31, y: 19).scaled(scaleFactor*2)
        
        path ==> CGPoint(x: 25, y: 16).scaled(scaleFactor*2)
        path --> CGPoint(x: 25, y: 28).scaled(scaleFactor*2)
        
        path.lineWidth = 1
        path.lineCapStyle = .Round
        path.lineJoinStyle = .Round
        
        path.stroke()
    }
}







