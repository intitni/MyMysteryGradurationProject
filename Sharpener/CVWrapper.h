//
//  CVWrapper.h
//  Sharpener
//
//  Created by Inti Guo on 1/26/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPCVLine.h"
#import <opencv2/opencv.hpp>

@interface CVWrapper : NSObject


///@brief Fetches Contours of a given image, the image should be thresholded.
///@param image The UIImage to be processed, it should be thresholded, shape in white, background in black.
///@return Returns an NSArray containing SPCVLines
+ (NSArray<SPCVLine *> *)findContoursFromImage:(UIImage *)image;
+ (cv::Mat)cvMatFromBytesArray:(NSArray *)bytes width:(NSInteger)width height:(NSInteger)height;
+ (NSArray<SPCVLine *> *)findContoursFromBytes:(NSArray *)bytes width:(NSInteger)width height:(NSInteger)height;

@end

