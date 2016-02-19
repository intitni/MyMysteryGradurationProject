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
    
    // MARK: UI Elements
    
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.delegate = self
            scrollView.contentSize = processSize
            scrollView.zoomScale = 1.0
            scrollView.minimumZoomScale = 0.8
            scrollView.maximumZoomScale = 2
        }
    }
    @IBOutlet weak var navigationBar: ProcessingNavigationBar! {
        didSet {
            navigationBar.buttonDelegate = self
        }
    }
    @IBOutlet weak var controlPanel: UIView! {
        didSet {
            controlPanel.backgroundColor = UIColor.whiteColor()
        }
    }
    
    @IBOutlet weak var segmentedControl: SPTwoWaySegmentedControl!
    
    var refineView: SPRefineView! {
        didSet {
            scrollView.addSubview(refineView)
            refineView.delegate = self
        }
    }
    var mode: Mode = .Erase
    
    // MARK: Constants
    
    /// Actually 600 * 800 in @2x devices. Maybe 900 * 1200 in @3x devices.
    let processSize = CGSize(width: 300, height: 400)
    let shouldUseTestImage = true

    // MARK: Properties
    
    var incomeImage: UIImage!
    var finder: SPRawGeometricsFinder!
    var shapes = [CAShapeLayer]()
    var imageSize = CGSizeZero {
        didSet {
            scrollView.contentSize = imageSize
            refineView.frame.size = imageSize
        }
    }
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareViews()
    }
    
    override func viewDidAppear(animated: Bool) {
        if shouldUseTestImage { incomeImage = UIImage(named: "TestImage") }
        
        let newImage = incomeImage.resizedImageToSize(processSize)
        imageSize = newImage.size.scaled(newImage.scale)

        // FIXME: calculated attributes for filter
        finder = SPRawGeometricsFinder(medianFilterRadius: 1, thresholdingFilterThreshold: 0.2, lineShapeFilteringFilterAttributes: (5, 4), extractorSize: processSize)
        finder.delegate = self
        finder.process(newImage)
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
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
        // put results on screen.
        for raw in SPGeometricsStore.universalStore.rawStore {
            refineView.shapes.append(raw.shapeLayer)
        }
        refineView.drawLayers()
    }
}

// MARK: - SPRefineViewDelegate
extension RefineViewController: SPRefineViewDelegate {
    func didTouchShapeAtIndex(index: Int) {
        let shape = SPGeometricsStore.universalStore.rawStore[index]
        shape.isHidden = mode == .Catch ? false : true
        refineView.updateShapeLayerAtIndex(index, to: shape.shapeLayer)
    }
}

extension RefineViewController: ProcessingNavigationBarDelegate {
    func didTapOnNavigationBarButton(index: Int) {
        switch index {
        case 0:
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
