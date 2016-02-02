//
//  UIImage+Resizing.swift
//  Sharpener
//
//  Created by Inti Guo on 2/1/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import UIKit

extension UIImage {
    
    func scaledImageToSize(scaleFactor: CGFloat) -> UIImage {
        let newSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)
        return resizedImageToSize(newSize)
    }
    
    func resizedImageToSize(newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        
        self.drawInRect(CGRectMake(0, 0, newSize.width, newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
