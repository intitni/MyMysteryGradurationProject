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
    
    var done: Bool = false
    
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.delegate = self
            scrollView.contentSize = Preference.vectorizeSize
            scrollView.zoomScale = 0.6
            scrollView.minimumZoomScale = 0.6
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
    var countingView: SPGeometricCountingView! {
        didSet {
            countingView.alpha = 0
            countingView.backgroundColor = UIColor.clearColor()
            controlPanel.addSubview(countingView)
            countingView.snp_makeConstraints { make in
                make.edges.equalTo(self.controlPanel)
            }
        }
    }
    
    var vectorizer: SPGeometricsVectorizor!
    
    var vectorizingOperation: NSBlockOperation!
    
    var refineView: SPRefineView! {
        didSet {
            refineView.backgroundColor = UIColor.whiteColor()
            scrollView.addSubview(refineView)
            refineView.delegate = self
            refineView.frame.size = Preference.vectorizeSize
        }
    }
    
    var editingGeometric: SPGeometrics?
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        progressBar.labelText = "Vectorizing"
        refineView = SPRefineView(frame: CGRectZero)
        countingView = SPGeometricCountingView()
    }
    
    override func viewDidAppear(animated: Bool) {
        if !done { performVectorizing() }
    }
    
    private func performVectorizing() {
        let raws = SPGeometricsStore.universalStore
        vectorizer = SPGeometricsVectorizor()
        vectorizer.delegate = self
        
        vectorizingOperation = NSBlockOperation {
            self.vectorizer.vectorize(raws)
        }
        
        let queue = NSOperationQueue()
        queue.qualityOfService = .Utility
        queue.addOperation(vectorizingOperation)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else { return }
        switch identifier {
        case "VectorizeToEdit":
            guard let toVC = segue.destinationViewController as? SingleGeometricEditViewController else { break }
            toVC.geometric = editingGeometric
        default: break
        }
    }
    
    @IBAction func unwindFromEdit(sender: UIStoryboardSegue) {
        guard editingGeometric != nil else { return }
        refineView.updateShapeLayerFor(editingGeometric!)
    }
    
}

extension VectorizeViewController: SPGeometricsVectorizorDelegate {
    func didFinishVectorizing(store: SPGeometricsStore) {
        NSOperationQueue.mainQueue().addOperationWithBlock { [unowned self] in
            self.progressBar.labelText = "Done"
            self.navigationBar.actionButtonEnabled = true
            self.done = true
            // Hide progressBar and show countings
            self.countingView.shapeCount = SPGeometricsStore.universalStore.shapeCount
            self.countingView.lineGroupCount = SPGeometricsStore.universalStore.lineCount
            UIView.animateWithDuration(0.1, delay: 0.2, options: .CurveLinear, animations: {
                self.progressBar.alpha = 0
                self.countingView.alpha = 1
            }, completion: nil)
            self.refineView.enabled = true
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
        editingGeometric = geometric
        performSegueWithIdentifier("VectorizeToEdit", sender: self)
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
            vectorizer.isCanceled = true
            SPGeometricsStore.universalStore.shapeStore.removeAll()
            SPGeometricsStore.universalStore.lineStore.removeAll()
            dismissViewControllerAnimated(true, completion: nil)
        case 1:
            // here we save the file
            let fileHandler = SPSharpenerFileHandler()
            fileHandler.saveGeometricStore(SPGeometricsStore.universalStore) { succeed in
                self.performSegueWithIdentifier("NewFileCreated", sender: self)
                SPGeometricsStore.universalStore.removeAll()
            }
            
        default: break
        }
    }
    
    var processingNavigationBarRightButtonText: String { return "Save" }
}
