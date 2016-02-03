//
//  SPRefineView.swift
//  Sharpener
//
//  Created by Inti Guo on 2/1/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import UIKit

protocol SPRefineViewDelegate {
    func didTouchShapeAtIndex(index: Int)
}

class SPRefineView: UIView {

    var delegate: SPRefineViewDelegate?
    var shapes = [CAShapeLayer]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        prepareGestures()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func drawLayers() {
        shapes.forEach { s in
            layer.addSublayer(s)
        }
    }
    
    func prepareGestures() {
        let tap = UITapGestureRecognizer(target: self, action: "tap:")
        addGestureRecognizer(tap)
    }
    
    func tap(recognizer: UITapGestureRecognizer) {
        let location = recognizer.locationInView(self)
        for (i, _) in shapes.enumerate() {
            if SPGeometricsStore.universalStore.rawStore[i].raw.contains(CGPoint(x: Int(location.x), y: Int(location.y))) {
                delegate?.didTouchShapeAtIndex(i)
                shapes[i].opacity = shapes[i].opacity == 0.5 ? 1 : 0.5
                return
            }
        }
    }
}