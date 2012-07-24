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

- (BOOL)isEqual:(id)object
{
    AAmoGlobalParameter * obj = (AAmoGlobalParameter *) object;
    return [self.name isEqualToString:obj.name];
}

@end
