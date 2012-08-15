//
//  AAmoMapaQuery.m
//  Aamo
//
//  Created by Francisco Rodrigues Sampaio on 15/08/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AAmoMapaQuery.h"

@implementation AAmoMapaQuery
@synthesize name;
@synthesize object;

- (BOOL)isEqual:(id)outro
{
    AAmoMapaQuery * obj = (AAmoMapaQuery *) outro;
    return [self.name isEqualToString:obj.name];
}

@end