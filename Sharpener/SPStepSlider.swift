//
//  SPStepSlider.swift
//  Sharpener
//
//  Created by Inti Guo on 12/27/15.
//  Copyright © 2015 Inti Guo. All rights reserved.
//

import UIKit

class SPStepSlider: SPSlider {

    enum Direction { case Up, Down }
    
    var gearCount: Int = 2 {
        didSet {
            if gearCount < 2 { gearCount = 2 }
        }
    }
    var step: Double {
        return 1 / Double(gearCount - 1)
    }
    
    init(currentGear: Int, gearCount: Int) {
        self.gearCount = gearCount
        super.init(currentValue: Double(currentGear) / Double(gearCount - 1))
        animate = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupGestures() {
        let swipeUp = UISwipeGestureRecognizer(target: self, action: "swipeOnHandleViewUp:")
        swipeUp.delegate = self
        swipeUp.direction = .Up
        let swipeDown = UISwipeGestureRecognizer(target: self, action: "swipeOnHandleViewDown:")
        swipeDown.delegate = self
        swipeDown.direction = .Down
        gestureHandleView?.addGestureRecognizer(swipeUp)
        gestureHandleView?.addGestureRecognizer(swipeDown)
    }

    func swipeOnHandleViewUp(recognizer: UISwipeGestureRecognizer) {
        if recognizer.state == .Ended { didSwpipe(.Up) }
    }
    
    func swipeOnHandleViewDown(recognizer: UISwipeGestureRecognizer) {
        if recognizer.state == .Ended { didSwpipe(.Down) }
    }
    
    func didSwpipe(direction: Direction) {
        currentValue += direction == .Up ? step : -step
    }
}

extension SPStepSlider: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureHandleView != nil else { return false }
        let width = gestureHandleView!.frame.width
        if gestureRecognizer.locationInView(gestureHandleView!).x > width / 2 {
            return true
        }
        return false
    }

}
