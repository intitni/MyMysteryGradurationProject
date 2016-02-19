//
//  VectorizeViewController.swift
//  Sharpener
//
//  Created by Inti Guo on 2/18/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import UIKit

class VectorizeViewController: UIViewController, SPGeometricsVectorizorDelegate {

    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.delegate = self
            scrollView.contentSize = CGSize(width: 300, height: 400)
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
    
    var refineView: SPRefineView! {
        didSet {
            refineView.backgroundColor = UIColor.whiteColor()
            scrollView.addSubview(refineView)
            refineView.delegate = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let raws = SPGeometricsStore.universalStore
        let vectorizer = SPGeometricsVectorizor()
        vectorizer.delegate = self
        refineView = SPRefineView(frame: CGRectZero)
        dispatch_async(GCD.utilityQueue) {
            vectorizer.vectorize(raws)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func finishVectorizing(store: SPGeometricsStore) {
        let s = store
        for v in s.lineStore {
            let shape = v.shapeLayer
            refineView.shapes.append(shape)
        }
        for v in s.shapeStore {
            refineView.shapes.append(v.shapeLayer)
        }
        refineView.drawLayers()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
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
    func didTouchShapeAtIndex(index: Int) {
        
    }
}

//  MARK: - ProcessingNavigationBarDelegate
extension VectorizeViewController: ProcessingNavigationBarDelegate {
    func didTapOnNavigationBarButton(index: Int) {
        switch index {
        case 0:
            dismissViewControllerAnimated(true, completion: nil)
        case 1:
            break
        default: break
        }
    }
    
    var processingNavigationBarRightButtonText: String { return "Save" }
}
