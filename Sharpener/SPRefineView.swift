//
//  SPRefineView.swift
//  Sharpener
//
//  Created by Inti Guo on 2/1/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import UIKit

protocol SPRefineViewDelegate: class {
    func didTouchShape(shape: CAShapeLayer)
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
    
    func appendShapeLayerForGeometric(geometric: SPGeometrics) {
        if let s = geometric as? SPShape {
            let l = s.shapeLayer
            shapes.append(l)
            l.setValue(s, forKey: "geometric")
            layer.addSublayer(l)
        } else if let s = geometric as? SPLineGroup {
            let l = s.shapeLayer
            shapes.append(l)
            l.setValue(s, forKey: "geometric")
            layer.addSublayer(l)
        }
    }
    
    func appendShapeLayerForRawGeometric(raw: SPRawGeometric) {
        let l = raw.shapeLayer
        shapes.append(l)
        l.setValue(raw, forKey: "rawGeometric")
        layer.addSublayer(l)
    }
    
    func updateShapeLayer(shapLayer: CAShapeLayer, to layer: CAShapeLayer) {
        shapLayer.path = layer.path
        shapLayer.opacity = layer.opacity
        shapLayer.fillColor = layer.fillColor
        shapLayer.strokeColor = layer.strokeColor
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch = touches.first where touches.count == 1 {
            let location = touch.locationInView(self)
            for shape in shapes {
                if CGPathContainsPoint(shape.path, nil, location, true) {
                    delegate?.didTouchShape(shape)
                    break
                }
            }
        }
    }
}