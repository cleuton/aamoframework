//
//  AAmoMapaQuery.h
//  Aamo
//
//  Created by Francisco Rodrigues on 15/08/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AAmoMapaQuery : NSObject
@property (strong, nonatomic) NSString * name;
@property (strong, nonatomic) NSObject * object;

- (BOOL) isEqual:(id)outro;
@end
