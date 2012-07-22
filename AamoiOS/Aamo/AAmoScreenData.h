//
//  AAmoScreenData.h
//  Aamo
//
//  Created by Cleuton Sampaio on 08/07/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AAmoScreenData : NSObject

@property int uiid;
@property (strong, nonatomic) NSString * title;
@property (strong, nonatomic) NSString * onLoadScript;
@property (strong, nonatomic) NSString * onEndScript;
@property (strong, nonatomic) NSString * onLeaveScript;
@property (strong, nonatomic) NSString * onBackScript;
@end
