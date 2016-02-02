//
//  CVWrapper.m
//  Sharpener
//
//  Created by Inti Guo on 1/26/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//


#import "CVWrapper.h"
#import "UIImage+OpenCV.h"
#import <opencv2/opencv.hpp>

@implementation CVWrapper

+ (NSArray<SPCVLine *> *)findContoursFromImage:(UIImage *)image {
    cv::Mat cvMat = [image cvMat];
    cv::Mat greyMat;
    cv::threshold(cvMat, greyMat, 0, 1, CV_THRESH_BINARY);
    std::vector<std::vector<cv::Point>> contours;
    std::vector<cv::Vec4i> hierarchy;
    NSMutableArray<SPCVLine *> *linegroup = [[NSMutableArray alloc] init];

    cv::findContours(greyMat, contours, hierarchy, CV_RETR_LIST, CV_CHAIN_APPROX_NONE);
    
    for(int i= 0; i < contours.size(); i++) {
        SPCVLine *line;
        NSMutableArray *raw;
        for(int j= 0; j < contours[i].size();j++) {
            CvPoint pt = contours[i][j];
            CGPoint p = CGPointMake(pt.x, pt.y);
            [raw addObject:[NSValue valueWithCGPoint:p]];
        }
        line.raw = raw;
    }
    
    return linegroup;
}

+ (NSArray<SPCVLine *> *)findContoursFromBytes:(NSArray *)bytes width:(NSInteger)width height:(NSInteger)height {
    cv::Mat cvMat = [CVWrapper cvMatFromBytesArray:bytes width:width height:height];
    std::vector<std::vector<cv::Point>> contours;
    std::vector<cv::Vec4i> hierarchy;
    NSMutableArray<SPCVLine *> *linegroup = [[NSMutableArray alloc] init];
    
    cv::findContours(cvMat, contours, hierarchy, CV_RETR_LIST, CV_CHAIN_APPROX_NONE);
    
    for(int i= 0; i < contours.size(); i++) {
        SPCVLine *line = [[SPCVLine alloc] init];
        NSMutableArray *raw = [[NSMutableArray alloc] init];
        for(int j= 0; j < contours[i].size();j++) {
            CvPoint pt = contours[i][j];
            CGPoint p = CGPointMake(pt.x, pt.y);
            [raw addObject:[NSValue valueWithCGPoint:p]];
        }
        line.raw = raw;
        [linegroup addObject:line];
    }
    
    return linegroup;
}


+ (cv::Mat)cvMatFromBytesArray:(NSArray *)bytes width:(NSInteger)width height:(NSInteger)height {
    CGFloat cols = width;
    CGFloat rows = height;
    cv::Mat cvMat = cv::Mat(rows, cols, CV_8UC1);
    
    for (int i = 0; i < width * height; i++) {
        uchar value = (uchar)((NSNumber *)[bytes objectAtIndex:i]).unsignedCharValue;
        cvMat.data[i] = value;
    }
    
    return cvMat;
}


@end