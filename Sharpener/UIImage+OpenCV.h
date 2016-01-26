//
//  UIImage+OpenCV.h
//  Sharpener
//
//  Created by Inti Guo on 1/26/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/opencv.hpp>

@interface UIImage (OpenCV)

- (cv::Mat)cvMat;
+ (UIImage *)UIImageFromCVMat:(cv::Mat)mat;

@end
