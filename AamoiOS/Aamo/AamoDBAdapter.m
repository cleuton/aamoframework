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

static sqlite3_stmt *statement;
static AAmoDatabase *aamoDB;
static NSString *databaseName;  

@synthesize databasePath;

@synthesize database = _db;

- (NSString *) getDatabasePath: (NSString *) name
{
    NSString *docsDir;
    NSArray *dirPaths;
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = [dirPaths objectAtIndex:0];
    databasePath = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent:name]];
    docsDir = nil;
    dirPaths = nil;
    databaseName = name;
    return databasePath;
}


- (NSString *) createTables: (AAmoDatabase *) db
{
	
     NSMutableString *buffer = [[NSMutableString alloc] init];
     NSString *name;
     NSString *separador = @",";     
     NSString *columnName;           
     NSString *type;
     
     for (AAmoTable * table in db.tablesList) {                                  
          name   = table.name;
          [buffer appendString:@ "CREATE TABLE IF NOT EXISTS "];           
          [buffer appendString:name];           
          [buffer appendString:@"( "];           

          int numberOfColumns = [table.columnsList count];
          int count = 1;
          for (AAmoColumn * column in table.columnsList) {
               columnName = column.name;
               [buffer appendString:columnName]; 
               [buffer appendString:@ " "];
               type = column.type; 
               [buffer appendString:type];
               [buffer appendString:@ " "];
              
               //PK
               if (column.primaryKey){
                   [buffer appendString:@ " PRIMARY KEY AUTOINCREMENT "];
               } 
               
              if (column.notNull){
                  [buffer appendString:@ " Not Null "];
                       
              }else {
                   [buffer appendString:@ " Null "];
              }
              //comma ","
              if (count < numberOfColumns){
                  [buffer appendString:separador];
              }
              count ++;
          }
          
          [buffer appendString:@ " )"];
          
          
	}
    
    NSLog(@"tabela ser criada %@", buffer);
    
    return 	buffer;
                                 
}                         

- (int) openDatabase: (NSString *) name
{

    const char *dbpath = [[self getDatabasePath: name] UTF8String];
    NSFileManager *filemgr = [NSFileManager defaultManager];

    if ([filemgr fileExistsAtPath: databasePath ] == NO)
    {
        
        NSLog(@"BD não existe, ler xml e criar o Banco %@", name);
        AAmoDBParser * parser = [[AAmoDBParser alloc] init];
        aamoDB = parser.readXMLDatabase;
		NSLog(@"DB Name: %@ Version: %d", aamoDB.name, aamoDB.version);
    	
    	if (sqlite3_open(dbpath, &_db) == SQLITE_OK)
        {
            NSLog(@"banco de dados criado com sucesso %@" , name);
            char *errMsg;
            const char *sql_stmt = [[self createTables: aamoDB] UTF8String];

            if (sqlite3_exec(_db, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
            {
                // NSLog(@"Falha na criação da tabela '%s'", errMsg);
                NSAssert1(0, @"Falha na criação da tabela '%s'", errMsg);
	        return 1;    
            }
            else {
            }    NSLog(@"Tabela criada com sucesso");
	}
	else {
	    _db = nil;
        return 1;
	}	
	    
    }
    else {
        if (sqlite3_open(dbpath, &_db) == SQLITE_OK)
   	{
	    NSLog(@"banco de dados aberto com sucesso %@", name);
	}
	else {
	    _db = nil;
        return 1;

	}
    }    
    return 0;
    
}

- (BOOL) execSQL: (NSString *) sql paramQuery: (NSMutableArray *) params
{
    BOOL resultado = YES;
    sqlite3_stmt *execStmt;
    const char *chrComando = [sql UTF8String];
    
    //if ([self openDatabase:databasePath] == SQLITE_OK)
    if ([self openDatabase:databaseName] == SQLITE_OK)
    {
    
        sqlite3_prepare_v2(_db, chrComando, -1, &execStmt, NULL);
        int contador = 2;
        
        if (params != nil){
            //carrega os parametros
            for (int i=0; i < [params count];i++){
                const char * param = [[params objectAtIndex:i] UTF8String];
                sqlite3_bind_text(execStmt, contador ,param ,-1,SQLITE_TRANSIENT); 
                contador++;
            }
        }
               
        if (sqlite3_step(execStmt) != SQLITE_DONE)
        {
            resultado = NO;
            NSLog(@"Erro no comando sql: %@ ", sql);
            NSAssert1(0, @"Error ao criar o statement '%s'", sqlite3_errmsg(_db));
        }
        else {
            resultado = YES;
            NSLog(@"Comando sql executado com sucesso: %@ ", sql);
        }   
    }
    
    sqlite3_finalize(execStmt);
    
    return resultado;
}

- (NSMutableArray *) query:(NSString *)sql paramQuery:(NSMutableArray *)params
{
    
    NSLog(@"Comando sql executado %@ ", sql);
    const char *query_stmt = [sql UTF8String];
      
    if (sqlite3_prepare_v2(_db, query_stmt, -1, &statement, NULL) == SQLITE_OK)
    {
        NSLog(@"total parametros %d ", [params count]);
        
        //carrega os parametros
        for (int i=0; i < [params count]; i++){
           const char * param = [[params objectAtIndex:i] UTF8String];
	       sqlite3_bind_text(statement, i,param ,-1,SQLITE_TRANSIENT);      
        }
        
        NSMutableArray *result = [NSMutableArray array];
        
        while (sqlite3_step(statement) == SQLITE_ROW) {
           NSMutableArray *row = [NSMutableArray array];
           for (int i=0; i<sqlite3_column_count(statement); i++) {
               char *coluna = (char *)sqlite3_column_text(statement, i);
               NSString *strColuna = [NSString stringWithCString:coluna encoding:[NSString defaultCStringEncoding]];
               [row addObject:strColuna];
           }
            
           [result addObject:row];
            
        } 

        return result;

    }
    else {
       NSString *msg = [NSString stringWithCString:sqlite3_errmsg(_db) encoding:[NSString defaultCStringEncoding]];
       NSLog(@"Error na query %@ ", msg);
    }
    return nil;
       
}


- (void) closeCursor:(sqlite3_stmt *) statement
{
    sqlite3_finalize(statement);
    statement = nil;
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
