//
//  GuessTableViewCell.swift
//  Sharpener
//
//  Created by Inti Guo on 2/21/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import UIKit

protocol GuessTableViewCellDelegate: class {
    func shouldPerformActionForCell(cell: GuessTableViewCell, revoke: Bool)
    func shouldShowPreviewForCurrentCurveWithGuess(guess: SPGuess)
    func shouldStopShowingPreviewForCurrentCurve()
}

class GuessTableViewCell: UITableViewCell {
    
    weak var delegate: GuessTableViewCellDelegate?
    
    var guess: SPGuess? {
        didSet {
            if frontView != nil {
                frontView.title = guess?.description
            }
        }
    }
    
    var applied: Bool {
        get {
            return frontView.applied
        }
        set {
            frontView.applied = newValue
        }
    }
    
    var frontView: GuessTableViewCellFrontView! {
        didSet {
            addSubview(frontView)
            frontView.snp_makeConstraints { make in
                make.edges.equalTo(self)
            }
            let pan = UIPanGestureRecognizer(target: self, action: #selector(GuessTableViewCell.panningOnFrontView(_:)))
            pan.delegate = self
            frontView.addGestureRecognizer(pan)
        }
    }
    
    var backView: GuessTableViewCellBackView! {
        didSet {
            addSubview(backView)
            backView.snp_makeConstraints { make in
                make.edges.equalTo(self)
            }
        }
    }
    
    var bottomBorder: UIView! {
        didSet {
            bottomBorder.backgroundColor = UIColor.spOutlineColor()
            addSubview(bottomBorder)
            bottomBorder.snp_makeConstraints { make in
                make.bottom.equalTo(self)
                make.width.equalTo(self)
                make.centerX.equalTo(self)
                make.height.equalTo(1)
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        backView = GuessTableViewCellBackView()
        frontView = GuessTableViewCellFrontView()
        bottomBorder = UIView()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

    func panningOnFrontView(recognizer: UIPanGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Began {
            delegate?.shouldShowPreviewForCurrentCurveWithGuess(guess!)
        } else if recognizer.state == UIGestureRecognizerState.Changed {
            let t = recognizer.translationInView(recognizer.view?.superview).x
            
            frontView.transform.tx += t
            if applied && frontView.transform.tx > 0 {
                frontView.transform.tx = 0
            }
            if !applied && frontView.transform.tx < 0 {
                frontView.transform.tx = 0
            }
            if abs(frontView.transform.tx) >= 100 && abs(frontView.transform.tx - t) < 100 {
                UIView.animateWithDuration(0.1) {
                    self.backView.backgroundColor = self.applied ? UIColor.spRedColor() : UIColor.spGreenColor()
                }
            } else if abs(frontView.transform.tx) <= 100 && abs(frontView.transform.tx - t) > 100 {
                UIView.animateWithDuration(0.1) {
                    self.backView.backgroundColor = UIColor.spOutlineColor()
                }
            }
            recognizer.setTranslation(CGPointZero, inView: recognizer.view?.superview)
            
        } else if recognizer.state == UIGestureRecognizerState.Ended {
            delegate?.shouldStopShowingPreviewForCurrentCurve()
            if frontView.transform.tx > 100 || frontView.transform.tx < -100 {
                delegate?.shouldPerformActionForCell(self, revoke: applied ? true : false)
            }
            
            UIView.animateWithDuration(0.15, delay: 0,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0.8,
                options: [],
                animations: {
                    self.frontView.transform.tx = 0
                    self.backView.backgroundColor = UIColor.spOutlineColor()
                },
                completion: nil)
        }
    }
}

extension GuessTableViewCell {
    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let translate = (gestureRecognizer as? UIPanGestureRecognizer)?.translationInView(gestureRecognizer.view) {
            let x = translate.x
            let y = translate.y
            return abs(x/y) > 4 ? true : false
        }
        return false
    }
}

class GuessTableViewCellFrontView: UIView {
    
    var title: String? {
        get { return guessTitle.text }
        set { guessTitle.text = newValue }
    }
    
    var applied: Bool = false {
        didSet {
            if applied { backgroundColor = UIColor.spGreenColor() }
            else { backgroundColor = UIColor.spGrayishWhiteColor() }
        }
    }
    
    var guessTitle: UILabel! {
        didSet {
            addSubview(guessTitle)
            guessTitle.snp_makeConstraints { make in
                make.center.equalTo(self)
            }
            guessTitle.textAlignment = .Center
            guessTitle.font = UIFont.systemFontOfSize(20)
            guessTitle.textColor = UIColor.spOutlineColor()
        }
    }
    
    init() {
        super.init(frame: CGRectZero)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        guessTitle = UILabel()
    }
}

class GuessTableViewCellBackView: UIView {
    
    func highLightColor(applied: Bool) -> UIColor {
        return applied ? UIColor.spRedColor() : UIColor.spGreenColor()
    }
    
    init() {
        super.init(frame: CGRectZero)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        backgroundColor = UIColor.spOutlineColor()
    }
}