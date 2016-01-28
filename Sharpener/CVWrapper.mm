//
//  CVWrapper.m
//  Sharpener
//
//  Created by Inti Guo on 1/26/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//


#import "CVWrapper.h"
#import <opencv2/opencv.hpp>
#import "UIImage+OpenCV.h"
#import "SPCVLine.h"

@implementation CVWrapper

+ (NSArray *)findContoursFromImage:(UIImage *)image {
    CvMat cvMat = image.cvMat;
    CvMemStorage * storage = cvCreateMemStorage();
    CvSeq *contours = NULL;
    NSMutableArray *linegroup;
    
    cvFindContours(&cvMat, storage, &contours, CV_RETR_LIST, CV_CHAIN_APPROX_NONE);
    
    for (CvSeq * c = contours; c != NULL; c = c->h_next) {
        SPCVLine *line;
        
        NSMutableArray *raw;
        for (int i = 0; i < c->total; i++) {
            CvPoint *pt = (CvPoint *)cvGetSeqElem(c, i);
            CGPoint p = CGPointMake(pt->x, pt->y);
            [raw addObject:[NSValue valueWithCGPoint:p]];
        }
        line.raw = raw;
    }

    cvReleaseMemStorage(&storage);
    
    return linegroup;
}



@end