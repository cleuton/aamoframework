//
//  AAmoGlobalParameter.m
//  Aamo
//
//  Created by Cleuton Sampaio on 23/07/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AAmoGlobalParameter.h"

@implementation AAmoGlobalParameter
@synthesize name;
@synthesize object;
@synthesize type;

- (BOOL)isEqual:(id)outro
{
    AAmoGlobalParameter * obj = (AAmoGlobalParameter *) outro;
    return [self.name isEqualToString:obj.name];
}

@end
