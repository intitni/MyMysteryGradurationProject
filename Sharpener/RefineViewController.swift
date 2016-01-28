//
//  RefineViewController.swift
//  Sharpener
//
//  Created by Inti Guo on 12/29/15.
//  Copyright © 2015 Inti Guo. All rights reserved.
//

import UIKit

class RefineViewController: UIViewController {
    
    var incomeImage: UIImage!
    var finder: SPRawGeometricsFinder!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
    }
    
    override func viewDidAppear(animated: Bool) {
        let newSize = CGSize(width: 200, height: 300)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        incomeImage.drawInRect(CGRectMake(0, 0, newSize.width, newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let v = UIImageView(image: newImage)
        view.addSubview(v)
        v.snp_makeConstraints { make in
            make.center.equalTo(self.view)
            make.width.equalTo(200)
            make.height.equalTo(300)
            
        }
        finder = SPRawGeometricsFinder(medianFilterRadius: 1, thresholdingFilterThreshold: 0.2, lineShapeFilteringFilterAttributes: (5, 4), extractorSize: newSize)
        finder.process(newImage)
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension RefineViewController: SPRawGeometricsFinderDelegate {
    func succefullyFoundRawGeometrics() {
        print(SPGeometricsStore.universalStore.rawStore.count)
    }
}
