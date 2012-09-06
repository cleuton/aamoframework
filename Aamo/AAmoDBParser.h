//
//  AAmoDBParser.h
//  
//
//  Created by Cleuton Sampaio on 08/08/12.
//  Copyright (c) 2012 Cleuton Sampaio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AAmoDatabase.h"

@interface AAmoDBParser : NSObject <NSXMLParserDelegate>


- (AAmoDatabase * ) readXMLDatabase;

@end
