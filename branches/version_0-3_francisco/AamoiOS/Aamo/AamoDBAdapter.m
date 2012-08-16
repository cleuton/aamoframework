//
//  AamoDBAdapter.m
//  Aamo
//
//  Created by Francisco  Rodrigues on 06/08/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AamoDBAdapter.h"
#import "AAmoDBParser.h"
#import "AAmoDatabase.h"
#import "AAmoTable.h"
#import "AAmoColumn.h"

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
    
    AAmoDBParser * parser = [[AAmoDBParser alloc] init];
    AAmoDatabase * db = parser.readXMLDatabase;
    NSLog(@"DB Name: %@ Version: %d", db.name, db.version);
    /*
    for (AAmoTable * table in db.tablesList) {
        NSLog(@"Table: %@", table.name);
        for (AAmoColumn * column in table.columnsList) {
            NSLog(@"Column Name: %@, Type: %@, PK: %d, NOTNULL: %d",
                 column.name, column.type, column.primaryKey, column.notNull);
        }
    }
    */
    
    const char *dbpath = [[self getDatabasePath: db.name] UTF8String];
    ///sqlite3 * db;
    if (sqlite3_open(dbpath, &_db) == SQLITE_OK)
    {
        NSLog(@"banco de dados aberto com com sucesso %@" , name);
    }
    else {
        NSLog(@"Erro ao abrir o banco %@", name);
        _db = nil;
    }
    return _db;
    
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
        NSLog(@"Erro no Comando sql: %@ ", sql);
    }
    else {
        resultado = YES;
        NSLog(@"Comando sql executado com sucesso: %@ ", sql);
    }    
    sqlite3_finalize(statement);
    return resultado;
}

- (sqlite3_stmt *) query:(NSString *)sql paramQuery:(NSMutableArray *)params
{
    
    NSLog(@"Comando sql executado %@ ", sql);
    const char *query_stmt = [sql UTF8String];
      
    if (sqlite3_prepare_v2(_db, query_stmt, -1, &statement, NULL) == SQLITE_OK)
    {
       //carrega os parametros
       for (int i=0; i < [params count]; i++){
           const char * param = [[params objectAtIndex:i] UTF8String];
	       sqlite3_bind_text(statement, i,param ,-1,SQLITE_TRANSIENT);      
           //strLastName UTF8String
       }
       //retorna o statement com os dados da consulta
       if (sqlite3_step(statement) == SQLITE_ROW)
       {
           return statement;
       } 
     
    }
    else {
       NSString *msg = [NSString stringWithCString:sqlite3_errmsg(_db)];
	   NSLog(msg);
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

- (BOOL) eof: (sqlite3_stmt *) statement
{
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        return YES;
    }
    else {
        return NO;
    }
}

- (void) close:(sqlite3_stmt *) statement
{
    sqlite3_finalize(statement);
    sqlite3_reset(statement);
}


- (void) closeDatabase: (NSString *) name
{
            
    NSLog(@"entrou no close database");
    if (_db != nil)
    {
       sqlite3_close(_db);
       _db = nil;
    }
    
}

@end
