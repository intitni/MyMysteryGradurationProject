//
//  SPDisplayView.swift
//  Sharpener
//
//  Created by Inti Guo on 2/21/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import UIKit

class SPDisplayView: UIView {

    var geometricLayer: CALayer! {
        didSet {
            layer.addSublayer(geometricLayer)
        }
    }
    
    var highlightLayer: CALayer! {
        didSet {
            layer.addSublayer(highlightLayer)
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
    
    func showGeometric(geometric: SPGeometrics, andHighlightCurve curve: SPCurve) {
        geometricLayer.sublayers?.removeAll()
        highlightLayer.sublayers?.removeAll()
        
        if let x = geometric as? SPShape {
            showShapeLayer(x.shapeLayerPure, andHighlightCurve: curve.shapeLayer)
        } else if let x = geometric as? SPLineGroup {
            showShapeLayer(x.shapeLayerPure, andHighlightCurve: curve.shapeLayer)
        }
    }
    
    func showShapeLayer(shapeLayer: CAShapeLayer, andHighlightCurve curveLayer: CAShapeLayer) {
        let box = CGPathGetPathBoundingBox(shapeLayer.path)
        shapeLayer.bounds = box
        shapeLayer.position = CGPointZero
        shapeLayer.transform = centralTransformForPath(shapeLayer.path!)
        curveLayer.bounds = box
        curveLayer.position = CGPointZero
        curveLayer.transform = centralTransformForPath(shapeLayer.path!)
        
        geometricLayer.addSublayer(shapeLayer)
        highlightLayer.addSublayer(curveLayer)
    }
    
    private func centralTransformForPath(path: CGPathRef) -> CATransform3D {
        return CATransform3DMakeTranslation(bounds.width/2, bounds.height/2, 0)
    }
    
    private func setup() {
        geometricLayer = CALayer()
        highlightLayer = CALayer()
    }
}
