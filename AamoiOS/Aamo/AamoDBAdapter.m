//
//  AamoDBAdapter.m
//  Aamo
//
//  Created by Francisco  Rodrigues on 06/08/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AamoDBAdapter.h"

@implementation AamoDBAdapter
 sqlite3_stmt    *statement;
@synthesize database = _db;

- (NSString *) getDatabasePath: (NSString *) name
{
    NSString *docsDir;
    NSArray *dirPaths;
    NSString *databasePath;
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = [dirPaths objectAtIndex:0];
    databasePath = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent:@".db"]];
    docsDir = nil;
    dirPaths = nil;
    return databasePath;
}


- (sqlite3 *) openDatabase: (NSString *) name
{
    const char *dbpath = [[self getDatabasePath: name] UTF8String];
    sqlite3 * db;
    if (sqlite3_open(dbpath, &db) == SQLITE_OK)
    {
        char *errMsg;
        const char *sql_stmt = "CREATE TABLE IF NOT EXISTS elemento  (uid TEXT PRIMARY KEY, textoSecreto BLOB)";
        if (sqlite3_exec(db, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
        {
            //[self showMsgDialog:@"Problem para criar a tabela."];
            db = nil;
        }
        
    }
    else {
        NSLog(@"Erro ao abrir o banco");
        db = nil;
    }
    return db;
    
}


- (BOOL) execSQL: (NSString *) sql paramQuery: (NSMutableArray *) params
{
    BOOL resultado = YES;
    sqlite3_stmt *statement;
    const char *chrComando = [sql UTF8String];
    sqlite3_prepare_v2(_db, chrComando, -1, &statement, NULL);
    if (sqlite3_step(statement) != SQLITE_DONE)
    {
        resultado = NO;
    }
    sqlite3_finalize(statement);
    return resultado;
}

- (sqlite3_stmt *) query:(NSString *)sql paramQuery:(NSMutableArray *)params
{
    
    //@"SELECT address, phone FROM contacts WHERE name=\"%@\"",
    NSString *querySQL = [NSString stringWithFormat: @"SELECT address, phone FROM contacts WHERE name=name"];
        
    const char *query_stmt = [querySQL UTF8String];
      
    if (sqlite3_prepare_v2(_db, query_stmt, -1, &statement, NULL) == SQLITE_OK)
    {
       if (sqlite3_step(statement) == SQLITE_ROW)
       {
           //NSString *addressField = [[NSString alloc] initWithUTF8String:(const char *) 
           //sqlite3_column_text(statement, 0)];
           //address.text = addressField;
           return statement;
                                               
           //[addressField release];
                
        } 
            
     }
    return nil;
       
}

- (sqlite3_stmt *) next:(NSString *) cursor
{
   if (sqlite3_step(statement) == SQLITE_ROW)
   {
            
      return statement;
          
   } else {
       return nil;
   }
   
}

- (BOOL) eof: (NSString *) cursor 
{
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        return YES;
    }
    else {
        return NO;
    }
}

- (void) close:(NSString *) cursor
{
    sqlite3_finalize(statement);
}


- (void) closeDatabase: (NSString *) name
{
            
    NSLog(@"entrou no close database");
    if (_db != nil)
    {
       sqlite3_close(_db);
    }
    
}

@end
