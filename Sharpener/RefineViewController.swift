//
//  RefineViewController.swift
//  Sharpener
//
//  Created by Inti Guo on 12/29/15.
//  Copyright © 2015 Inti Guo. All rights reserved.
//

import UIKit

class RefineViewController: UIViewController, SPRawGeometricsFinderDelegate {
    
    var incomeImage: UIImage!
    var finder: SPRawGeometricsFinder!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let size = incomeImage.size
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
        
        finder = SPRawGeometricsFinder(medianFilterRadius: 1, thresholdingFilterThreshold: 0.2, lineShapeFilteringFilterAttributes: (5, 4), extractorSize: size)
        finder.delegate = self
        finder.extractTextureFrom(newImage)
    }
    
    func succefullyExtractedSeperatedTexture() {
        let t = finder.geometricsFilteringFilter.texture
        var rawData = [UInt8](count: t.width*t.height*4, repeatedValue: 0)
        t.getBytes(&rawData, bytesPerRow: t.width * 4, fromRegion: MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0), size: MTLSize(width: t.width, height: t.height, depth: 1)), mipmapLevel: 0)
        
        let providerRef = CGDataProviderCreateWithCFData(
            NSData(bytes: &rawData, length: rawData.count * sizeof(UInt8))
        )
        
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.ByteOrder32Big.rawValue | CGImageAlphaInfo.PremultipliedLast.rawValue)

        let renderingIntent = CGColorRenderingIntent.RenderingIntentDefault
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = t.width * bytesPerPixel
        
        let imageRef = CGImageCreate(Int(t.width), Int(t.height), 8, 8 * 4, bytesPerRow, colorSpace, bitmapInfo, providerRef, nil, false, renderingIntent)
        
        let v = UIImageView(image: UIImage(CGImage: imageRef!))
        v.alpha = 0.4
        view.addSubview(v)
        v.snp_makeConstraints { make in
            make.center.equalTo(self.view)
            make.width.equalTo(200)
            make.height.equalTo(300)
            
        }
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
