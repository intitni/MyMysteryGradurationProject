//
//  SPCVLine.h
//  Sharpener
//
//  Created by Inti Guo on 1/26/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPCVLine : NSObject

/** 
Storing NSValues created from CGPoints that make up this line. Cast it back to CGPoints for use.
 */
@property (nonatomic, strong) NSArray * raw;

@end
