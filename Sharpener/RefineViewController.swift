//
//  RefineViewController.swift
//  Sharpener
//
//  Created by Inti Guo on 12/29/15.
//  Copyright © 2015 Inti Guo. All rights reserved.
//

import UIKit

class RefineViewController: UIViewController {
    
    enum Mode { case Catch, Erase }
    var finished: Bool = false
    
    // MARK: UI Elements
    
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.delegate = self
            scrollView.contentSize = CGSize(width: Preference.vectorizeSize.height, height: Preference.vectorizeSize.height)
            scrollView.zoomScale = 0.8
            scrollView.minimumZoomScale = 0.8
            scrollView.maximumZoomScale = 2
        }
    }
    @IBOutlet weak var navigationBar: ProcessingNavigationBar! {
        didSet {
            navigationBar.buttonDelegate = self
            navigationBar.backgroundColor = UIColor.spGrayishWhiteColor()
        }
    }
    @IBOutlet weak var controlPanel: SPControlPanel! {
        didSet {
            controlPanel.backgroundColor = UIColor.spGrayishWhiteColor()
        }
    }
    
    @IBOutlet weak var segmentedControl: SPTwoWaySegmentedControl!
    
    var refineView: SPRefineView! {
        didSet {
            scrollView.addSubview(refineView)
            refineView.delegate = self
            refineView.frame.size = Preference.vectorizeSize
        }
    }
    var mode: Mode = .Erase
    
    // MARK: Constants
    
    let shouldUseTestImage = false

    // MARK: Properties
    
    var incomeImage: UIImage!
    var finder: SPRawGeometricsFinder!
    var shapes = [CAShapeLayer]()

    var geometricsFindingOperation: NSBlockOperation!
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareViews()
    }
    
    override func viewDidAppear(animated: Bool) {
        if shouldUseTestImage { incomeImage = UIImage(named: "TestImage") }
        
        // FIXME: calculated attributes for filter
        if !finished { performGeometricsFinding() }
        let screenSize = UIScreen.mainScreen().bounds.size
        scrollView.minimumZoomScale = screenSize.width / Preference.vectorizeSize.width
        scrollView.zoomScale = screenSize.width / Preference.vectorizeSize.width
    }
    
    private func performGeometricsFinding() {
        var newImage = incomeImage.resizedImageToSize(Preference.vectorizeSize.scaled(1/incomeImage.scale))
        newImage = newImage.resizedImageToSize(Preference.vectorizeSize.scaled(1/newImage.scale))
        
        finder = SPRawGeometricsFinder(medianFilterRadius: 1, thresholdingFilterThreshold: 0.2, lineShapeFilteringFilterAttributes: (5, 0 ), extractorSize: Preference.vectorizeSize)
        finder.delegate = self
        
        geometricsFindingOperation = NSBlockOperation { [unowned self] in
            self.finder.process(newImage)
        }
        
        let queue = NSOperationQueue()
        queue.qualityOfService = .Utility
        queue.addOperation(geometricsFindingOperation)
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func unwindToRefine(sender: UIStoryboardSegue) {}
}

// MARK: - UI
extension RefineViewController {
    private func prepareViews() {
        refineView = SPRefineView(frame: CGRectZero)
        segmentedControl.buttonDelegate = self
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}

// MARK: - UIScrollViewDelegate
extension RefineViewController: UIScrollViewDelegate {
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return refineView
    }
}

// MARK: - SPRawGeometricsFinderDelegate
extension RefineViewController: SPRawGeometricsFinderDelegate {
    func succefullyFoundRawGeometrics() {
        NSOperationQueue.mainQueue().addOperationWithBlock { [unowned self] in
            for raw in SPGeometricsStore.universalStore.rawStore {
                self.refineView.appendShapeLayerForRawGeometric(raw)
            }
            self.navigationBar.actionButtonEnabled = true
            self.finished = true
            self.refineView.enabled = true
        }
    }
}

// MARK: - SPRefineViewDelegate
extension RefineViewController: SPRefineViewDelegate {
    func didTouchShape(shape: CAShapeLayer) {
        guard let raw = shape.valueForKey("rawGeometric") as? SPRawGeometric else { return }
        raw.isHidden = mode == .Catch ? false : true
        refineView.updateShapeLayer(shape, to: raw.shapeLayer)
    }
}

extension RefineViewController: ProcessingNavigationBarDelegate {
    func didTapOnNavigationBarButton(index: Int) {
        switch index {
        case 0:
            if geometricsFindingOperation != nil && geometricsFindingOperation.executing {
                geometricsFindingOperation.cancel()
            }
            finder.isCanceled = true
            SPGeometricsStore.universalStore.removeAll()
            dismissViewControllerAnimated(true, completion: nil)
        case 1:
            performSegueWithIdentifier("RefineToVectorize", sender: self)
        default: break
        }
    }
    
    var processingNavigationBarRightButtonText: String { return "Vectorize" }
}

extension RefineViewController: SPTwoWaySegmentedControlDelegate {
    func twoWaySegmentedControlDidTapOnButtonWithIndex(index: Int) {
        switch index {
        case 0:
            mode = .Erase
        default:
            mode = .Catch
        }
    }
    
    func performDragOutActionForButtonWithIndex(index: Int) {
        
    }
    
    var twoWaySegmentedControlButtonNames: (String, String) {
        return ("Erase", "Catch")
    }
}
