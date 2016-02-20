//
//  VectorizeViewController.swift
//  Sharpener
//
//  Created by Inti Guo on 2/18/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import UIKit

class VectorizeViewController: UIViewController {

    // MARK: UI Elements
    
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.delegate = self
            scrollView.contentSize = Preference.vectorizeSize
            scrollView.zoomScale = 0.8
            scrollView.minimumZoomScale = 0.8
            scrollView.maximumZoomScale = 2
        }
    }
    @IBOutlet weak var navigationBar: ProcessingNavigationBar! {
        didSet {
            navigationBar.buttonDelegate = self
        }
    }
    
    @IBOutlet weak var controlPanel: SPControlPanel! {
        didSet {
            controlPanel.backgroundColor = UIColor.whiteColor()
        }
    }
    @IBOutlet weak var progressBar: SPBigProgressBar!
    
    var vectorizingOperation: NSBlockOperation!
    
    var refineView: SPRefineView! {
        didSet {
            refineView.backgroundColor = UIColor.whiteColor()
            scrollView.addSubview(refineView)
            refineView.delegate = self
            refineView.frame.size = Preference.vectorizeSize
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        progressBar.labelText = "Vectorizing"
        refineView = SPRefineView(frame: CGRectZero)
    }
    
    override func viewDidAppear(animated: Bool) {
        let raws = SPGeometricsStore.universalStore
        let vectorizer = SPGeometricsVectorizor()
        vectorizer.delegate = self
        
        vectorizingOperation = NSBlockOperation {
            vectorizer.vectorize(raws)
        }
        
        let queue = NSOperationQueue()
        queue.qualityOfService = .Utility
        queue.addOperation(vectorizingOperation)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension VectorizeViewController: SPGeometricsVectorizorDelegate {
    func didFinishVectorizing(store: SPGeometricsStore) {
        NSOperationQueue.mainQueue().addOperationWithBlock { [unowned self] in
            self.progressBar.labelText = "Done"
            self.navigationBar.actionButtonEnabled = true
            // Hide progressBar and show countings
        }
    }
    
    func didFinishAnIndividualVectorizingFor(geometric: SPGeometrics, withIndex index: Int, countOfTotal count: Int) {
        NSOperationQueue.mainQueue().addOperationWithBlock { [unowned self] in
            let progress = CGFloat(index + 1) / CGFloat(count)
            self.progressBar.currentProgress = progress
            self.refineView.appendShapeLayerForGeometric(geometric)
        }
    }
}

// MARK: - UIScrollViewDelegate
extension VectorizeViewController: UIScrollViewDelegate {
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return refineView
    }
}

// MARK: - SPRefineViewDelegate
extension VectorizeViewController: SPRefineViewDelegate {
    func didTouchShape(shape: CAShapeLayer) {
        // Show edit view
        guard let geometric = shape.valueForKey("geometric") as? SPGeometrics else { return }
    }
}

//  MARK: - ProcessingNavigationBarDelegate
extension VectorizeViewController: ProcessingNavigationBarDelegate {
    func didTapOnNavigationBarButton(index: Int) {
        switch index {
        case 0:
            if vectorizingOperation != nil && vectorizingOperation.executing {
                vectorizingOperation.cancel()
            }
            SPGeometricsStore.universalStore.shapeStore.removeAll()
            SPGeometricsStore.universalStore.shapeStore.removeAll()
            dismissViewControllerAnimated(true, completion: nil)
        case 1:
            break
        default: break
        }
    }
    
    var processingNavigationBarRightButtonText: String { return "Save" }
}
