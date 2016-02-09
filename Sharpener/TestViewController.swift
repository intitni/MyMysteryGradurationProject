//
//  TestViewController.swift
//  Sharpener
//
//  Created by Inti Guo on 2/9/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import UIKit

class TestViewController: UIViewController {
    
    let processSize = CGSize(width: 50, height: 50)
    
    override func viewDidLoad() {
        let incomeImage = UIImage(named: "LineTrackingTestImage")
        
        let newImage = incomeImage!.resizedImageToSize(processSize)

        
        // FIXME: calculated attributes for filter
        let finder = SPRawGeometricsFinder(medianFilterRadius: 1, thresholdingFilterThreshold: 0.2, lineShapeFilteringFilterAttributes: (5, 4), extractorSize: processSize)
        finder.delegate = self
        finder.process(newImage)
        
    }
    
}

extension TestViewController: SPRawGeometricsFinderDelegate {
    func succefullyFoundRawGeometrics() {
        // put results on screen.
        
        let v = SPLineGroupVectorizor(width: 100, height: 100)
        v.vectorize(SPGeometricsStore.universalStore.rawStore[0])

    }
}