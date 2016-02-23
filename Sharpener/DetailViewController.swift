//
//  DetailViewController.swift
//  Sharpener
//
//  Created by Inti Guo on 2/23/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    
    var docRef: SPSharpenerDocumentRef?
    var document: SPSharpenerDocument? {
        didSet {
            if document?.dataJson != nil {
                store = SPGeometricsStore(json: document!.dataJson!)
            }
        }
    }
    var store: SPGeometricsStore? {
        didSet {
            guard store != nil else { return }
            for s in store!.shapeStore {
                refineView.appendShapeLayerForGeometric(s)
            }
            for l in store!.lineStore {
                refineView.appendShapeLayerForGeometric(l)
            }
        }
    }
    
    @IBOutlet weak var navigationBar: SPDetailNavigationBar! {
        didSet {
            navigationBar.buttonDelegate = self
        }
    }
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.delegate = self
            scrollView.contentSize = CGSize(width: Preference.vectorizeSize.height, height: Preference.vectorizeSize.height)
            scrollView.zoomScale = 0.8
            scrollView.minimumZoomScale = 0.8
            scrollView.maximumZoomScale = 2
        }
    }
    @IBOutlet weak var toolBar: SPDetailToolBar!
    var refineView: SPRefineView! {
        didSet {
            scrollView.addSubview(refineView)
            refineView.frame.size = Preference.vectorizeSize
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        refineView = SPRefineView()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        guard docRef != nil else {
            dismissViewControllerAnimated(true, completion: nil)
            return
        }
        let fileHandler = SPSharpenerFileHandler()
        fileHandler.fetchDocumentForRef(docRef!) { d in
            self.document = d
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension DetailViewController: UIScrollViewDelegate {
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return refineView
    }
}

extension DetailViewController: SPNavigationBarDelegate {
    func navigationBarButtonTapped() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
