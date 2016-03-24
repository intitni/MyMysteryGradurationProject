//
//  FileToDetailTransitioningAnimation.swift
//  Sharpener
//
//  Created by Inti Guo on 2/24/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import UIKit

class FileToDetailTransitioningAnimation: UIPercentDrivenInteractiveTransition {
    enum Mode { case Presentation, Dismissal }
    
    weak var destinationViewController: UIViewController? {
        didSet {
            self.quitPanGesture = UIPanGestureRecognizer()
            self.quitPanGesture!.addTarget(self, action:#selector(FileToDetailTransitioningAnimation.handleOnstagePan(_:)))
            self.quitPanGesture?.delegate = self
            self.destinationViewController!.view.addGestureRecognizer(self.quitPanGesture!)
        }
    }
    
    private var mode: Mode = .Presentation
    private var interactive = false
    private let animationDuration = 0.3
    private let fromVCOffset: CGFloat = -100.0
    private let dimLevel: CGFloat = 0.6
    private var quitPanGesture: UIPanGestureRecognizer?
    
    private var fromView: UIView!
    private var toView: UIView!
    private var dim: UIView!
    private var currentContext: UIViewControllerContextTransitioning?
    
    func animatePresentation(transitionContext: UIViewControllerContextTransitioning) {
        let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)! as! FilesViewController
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)! as! DetailViewController
        fromView = fromViewController.view
        toView = toViewController.view
        
        if let container = transitionContext.containerView() {
            let offScreenRight = CGAffineTransformMakeTranslation(container.frame.width, 0)
            let offScreenLeft = CGAffineTransformMakeTranslation(fromVCOffset, 0.0)
            toView.transform = offScreenRight
            dim = UIView(frame: container.frame)
            dim.backgroundColor = UIColor.blackColor()
            dim.alpha = 0
            container.addSubview(fromView)
            container.addSubview(dim)
            container.addSubview(toView)
            
            UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0,
                options: UIViewAnimationOptions.CurveEaseInOut,
                animations: {
                    self.fromView.transform = offScreenLeft
                    self.toView.transform = CGAffineTransformIdentity
                    self.dim.alpha = self.dimLevel
                },
                completion: { finished in
                    transitionContext.completeTransition(true)
            })
            
        }
    }
    
    private func animateDismissal(transitionContext: UIViewControllerContextTransitioning) {
        if let container = transitionContext.containerView() {
            let offScreenRight = CGAffineTransformMakeTranslation(container.frame.width, 0)
            dim.alpha = dimLevel
            
            container.addSubview(fromView)
            container.addSubview(dim)
            container.addSubview(toView)
            
            let duration = transitionDuration(transitionContext)
            
            UIView.animateWithDuration(duration, delay: 0, options: UIViewAnimationOptions.CurveLinear,
                animations: {
                    self.fromView.transform = CGAffineTransformIdentity
                    self.toView.transform = offScreenRight
                    self.dim.alpha = 0
                },
                completion: { _ in
                    if transitionContext.transitionWasCancelled() {
                        transitionContext.completeTransition(false)
                    } else {
                        transitionContext.completeTransition(true)
                    }
            })
        }
    }
    
    
    func handleOnstagePan(pan: UIPanGestureRecognizer){
        let translation = pan.translationInView(pan.view!)
        let p = translation.x / pan.view!.bounds.width
        switch pan.state {
        case .Began:
            interactive = true
            destinationViewController?.dismissViewControllerAnimated(true, completion: nil)
        case .Changed:
            updateInteractiveTransition(p)
        case .Ended:
            interactive = false
            if p > 0.2 {
                finishInteractiveTransition()
            } else {
                cancelInteractiveTransition()
            }
        default:
            break
        }
    }
}

extension FileToDetailTransitioningAnimation: UIViewControllerAnimatedTransitioning {
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        switch mode {
        case .Presentation:
            animatePresentation(transitionContext)
        case .Dismissal:
            animateDismissal(transitionContext)
        }
    }
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        switch mode {
        case .Presentation:
            return animationDuration
        case .Dismissal:
            return animationDuration
        }
    }
}

extension FileToDetailTransitioningAnimation: UIViewControllerTransitioningDelegate {
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        mode = .Dismissal
        return self
    }
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        mode = .Presentation
        return self
    }
    
    func interactionControllerForPresentation(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }
    
    func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return self.interactive ? self : nil
    }
}

extension FileToDetailTransitioningAnimation: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let translate = (gestureRecognizer as? UIPanGestureRecognizer)?.translationInView(gestureRecognizer.view) {
            let x = translate.x
            let y = translate.y
            return abs(x/y) > 4 && x > 0 ? true : false
        }
        return false
    }
}
