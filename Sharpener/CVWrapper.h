//
//  CVWrapper.h
//  Sharpener
//
//  Created by Inti Guo on 1/26/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPCVLine.h"

@interface CVWrapper : NSObject

///@brief Fetches Contours of a given byte buffer(NSArray storing NSNumber from byte), the bytes should be thresholded. <b>It's very slow in DEBUG mode for too many assertions.</b>
///@param bytes The given byte buffer.
///@param width The width of buffer.
///@param height The height of buffer.
///@return Returns an NSArray containing SPCVLines.
+ (NSArray<SPCVLine *> *)findContoursFromBytes:(NSArray *)bytes
                                         width:(NSInteger)width
                                        height:(NSInteger)height;

@end

