//
//  TestViewController.swift
//  Sharpener
//
//  Created by Inti Guo on 2/9/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import UIKit

class TestViewController: UIViewController {
    
    let processSize = CGSize(width: 300, height: 400)
    let testView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
    
    override func viewDidLoad() {
        let incomeImage = UIImage(named: "LineTrackingTestImage")
        
        let newImage = incomeImage!.resizedImageToSize(processSize)

        
        // FIXME: calculated attributes for filter
        let finder = SPRawGeometricsFinder(medianFilterRadius: 1, thresholdingFilterThreshold: 0.2, lineShapeFilteringFilterAttributes: (5, 4), extractorSize: processSize)
        finder.delegate = self
        finder.process(newImage)
    }
    
}

extension TestViewController: SPRawGeometricsFinderDelegate, SPLineGroupVectorizorDelegate {
    func succefullyFoundRawGeometrics() {
        // put results on screen.
        
        let v = SPLineGroupVectorizor(width: 300, height: 400)
        v.delegate = self
        print(SPGeometricsStore.universalStore.rawStore.count)
        let layer = SPGeometricsStore.universalStore.rawStore[0].shapeLayer
        view.layer.addSublayer(layer)
        testView.backgroundColor = UIColor.blackColor()
        view.addSubview(testView)
        dispatch_async(GCD.utilityQueue) {
            v.vectorize(SPGeometricsStore.universalStore.rawStore[0])
        }

    }
    
    func trackingToPoint(point: CGPoint) {
        testView.frame.origin = point
    }
}