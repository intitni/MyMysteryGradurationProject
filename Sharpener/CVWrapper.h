//
//  CVWrapper.h
//  Sharpener
//
//  Created by Inti Guo on 1/26/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CVWrapper : NSObject

+ (NSArray *)findContoursFromImage:(UIImage *)image;

@end