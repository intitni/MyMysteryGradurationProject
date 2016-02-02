//
//  RefineViewController.swift
//  Sharpener
//
//  Created by Inti Guo on 12/29/15.
//  Copyright © 2015 Inti Guo. All rights reserved.
//

import UIKit

class RefineViewController: UIViewController {
    
    var imageTest: Bool { return true }
    
    var incomeImage: UIImage!
    var finder: SPRawGeometricsFinder!
    var shapes = [CAShapeLayer]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        if imageTest { incomeImage = UIImage(named: "TestImage") }
        let newSize = CGSize(width: 200, height: 300) // Actually 400 * 600 in @2x devices. Maybe 600 * 1200 in @3x devices.
        let newImage = incomeImage.resizedImageToSize(newSize)

        // FIXME: calculated attributes for filter
        finder = SPRawGeometricsFinder(medianFilterRadius: 1, thresholdingFilterThreshold: 0.2, lineShapeFilteringFilterAttributes: (5, 4), extractorSize: newSize)
        finder.delegate = self
        finder.process(newImage)
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension RefineViewController: SPRawGeometricsFinderDelegate {
    func succefullyFoundRawGeometrics() {
        // put results on screen.
        for raw in SPGeometricsStore.universalStore.rawStore {
            view.layer.addSublayer(raw.shapeLayer)
        }
    }
}
