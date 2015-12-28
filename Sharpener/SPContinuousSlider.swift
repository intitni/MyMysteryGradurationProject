//
//  SPContinuousSlider.swift
//  Sharpener
//
//  Created by Inti Guo on 12/27/15.
//  Copyright © 2015 Inti Guo. All rights reserved.
//

import UIKit

class SPContinuousSlider: SPSlider {
    
    override init(currentValue: Double) {
        super.init(currentValue: currentValue)
        sliderTag = "threshold"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupGestures() {
        let pan = UIPanGestureRecognizer(target: self, action: "panOnHandleView:")
        pan.delegate = self
        gestureHandleView?.addGestureRecognizer(pan)
    }
    
    func panOnHandleView(recognizer: UIPanGestureRecognizer) {
        guard gestureHandleView != nil else { return }
        switch recognizer.state {
        case .Changed:
            let translate = recognizer.translationInView(gestureHandleView).y
            recognizer.setTranslation(CGPointZero, inView: gestureHandleView)
            currentValue -= Double(translate) / valueBoundHeight
        default: break
        }
    }
}

extension SPContinuousSlider: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureHandleView != nil else { return false }
        let width = gestureHandleView!.frame.width
        if gestureRecognizer.locationInView(gestureHandleView!).x < width / 2 {
            return true
        }
        return false
    }
}
