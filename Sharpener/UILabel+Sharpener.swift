//
//  UILabel+Sharpener.swift
//  Sharpener
//
//  Created by Inti Guo on 12/23/15.
//  Copyright © 2015 Inti Guo. All rights reserved.
//

import Foundation
import UIKit

extension UILabel {
    
    static var textChangeAnimation = CATransition() {
        didSet {
            textChangeAnimation.duration = 0.15;
            textChangeAnimation.type = kCATransitionFade;
        }
    }
    
    func setText(text: String, withAnimation: Bool) {
        if withAnimation {
            layer.addAnimation(UILabel.textChangeAnimation, forKey: "changeTextTransition")
            self.text = text
        } else {
            self.text = text
        }
    }
}