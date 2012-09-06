//
//  AAmoGlobalParameter.h
//  Aamo
//
//  Created by Cleuton Sampaio on 23/07/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AAmoGlobalParameter : NSObject
@property (strong, nonatomic) NSString * name;
@property (strong, nonatomic) NSObject * object;
@property int type; // 1: STRING, 2: NUMBER (DOUBLE), 3: BOOL
- (BOOL) isEqual:(id)outro;
@end
