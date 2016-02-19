//
//  SPRefineView.swift
//  Sharpener
//
//  Created by Inti Guo on 2/1/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import UIKit

protocol SPRefineViewDelegate: class {
    func didTouchShapeAtIndex(index: Int)
}

class SPRefineView: UIView {

    weak var delegate: SPRefineViewDelegate?
    var shapes = [CAShapeLayer]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func drawLayers() {
        shapes.forEach { s in
            layer.addSublayer(s)
        }
    }
    
    func updateShapeLayerAtIndex(index: Int, to layer: CAShapeLayer) {
        let oldLayer = shapes[index]
        oldLayer.path = layer.path
        oldLayer.opacity = layer.opacity
        oldLayer.fillColor = layer.fillColor
        oldLayer.strokeColor = layer.strokeColor
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch = touches.first where touches.count == 1 {
            let location = touch.locationInView(self)
            for (i, shape) in shapes.enumerate() {
                if CGPathContainsPoint(shape.path, nil, location, true) {
                    delegate?.didTouchShapeAtIndex(i)
                    break
                }
            }
        }
    }
}