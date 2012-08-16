//
//  AamoDBAdapter.h
//  Aamo
//
//  Created by Francisco  Rodrigues on 06/08/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "/usr/include/sqlite3.h"


@interface AamoDBAdapter : NSObject

@property (nonatomic) sqlite3 *database;

- (sqlite3_stmt *) query:(NSString *)sql paramQuery:(NSMutableArray *)params;
- (void) closeDatabase: (NSString *) name;
- (sqlite3 *) openDatabase: (NSString *) name;
- (BOOL) execSQL: (NSString *) sql paramQuery: (NSMutableArray *) params;
- (NSString *) getDatabasePath: (NSString *) name;
- (BOOL) eof: (sqlite3_stmt *) statement;
- (sqlite3_stmt *) next:(NSString *) cursor;
- (void) closeCursor:(sqlite3_stmt *) statement;

@end
