//
//  AAmoColumn.h
//  
//
//  Created by Cleuton Sampaio on 08/08/12.
//  Copyright (c) 2012 Cleuton Sampaio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AAmoColumn : NSObject
@property (strong, nonatomic) NSString * type;
@property BOOL primaryKey;
@property (strong, nonatomic) NSString * name;
@property BOOL notNull;
@end
