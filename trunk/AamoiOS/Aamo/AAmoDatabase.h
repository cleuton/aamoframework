//
//  AAmoDatabase.h
//  
//
//  Created by Cleuton Sampaio on 08/08/12.
//  Copyright (c) 2012 Cleuton Sampaio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AAmoDatabase : NSObject
@property (strong, nonatomic) NSString * name;
@property int version;
@property (strong, nonatomic) NSMutableArray * tablesList;
@end
