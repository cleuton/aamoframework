//
//  AAmoDynaView.m
//  Aamo
//
//  Copyright (c) 2011 __The Code Bakers__. All rights reserved.
//

#import "AAmoDynaView.h"

@implementation AAmoDynaView
@synthesize id;
@synthesize type;
@synthesize percentTop;
@synthesize percentLeft;
@synthesize percentWidth;
@synthesize percentHeight;
@synthesize checked;
@synthesize text;
@synthesize onChangeScript;
@synthesize onCompleteScript;
@synthesize onClickScript;
@synthesize onElementSelected;
@synthesize view;
@synthesize listBoxElements;

- (id)init
{
    self = [super init];
    if (self) {
        self.listBoxElements = [[NSMutableArray alloc] init];
    }
    return self;
}
@end
