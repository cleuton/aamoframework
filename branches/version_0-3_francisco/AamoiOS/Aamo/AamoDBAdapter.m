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

sqlite3_stmt *statement;
AAmoDatabase *aamoDB; 
NSString *databasePath;

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
    
    return databasePath;
}


- (Database) readXML()
 {
               
	 AAmoDBParser * parser = [[AAmoDBParser alloc] init];
     AAmoDatabase * base = parser.readXMLDatabase;     
     
     //dbHelper = new DBHelper(ctx, database);          
     
     return base;
}


- (NSString *) createTables() {
	
	 NSMutableString *buffer = [[NSMutableString alloc] init];
	 NSString *name;
     NSString *separador = [NSString stringWithCString:@","];     
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
               columnName = [NSString stringWithCString:column.name];
               [buffer appendString:columnName]; 
               [buffer appendString:@ " "];
               type = [NSString stringWithCString:column.type]; 
               [buffer appendString:@ " "];

               //PK
               if (column.primaryKey){
                   [buffer appendString:@ " PRIMARY KEY "];
               }      
               //not null
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
    return 	buffer;
                                 
}                         

- (sqlite3 *) openDatabase: (NSString *) name
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
            const char *sql_stmt = [self createTables];

            if (sqlite3_exec(_db, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
            {
                 NSLog(@"Falha na criação da tabela", errMsg);
            }
            else {
            }    NSLog(@"Tabela criada com sucesso");
		}
		else {
			_db = nil;
		}	
	    
    }
    else {
        if (sqlite3_open(dbpath, &_db) == SQLITE_OK)
   		{
		    NSLog(@"banco de dados aberto com sucesso %@", name);
		}
		else {
			_db = nil;
		}
    }    
    return _db;
    
}

- (BOOL) execSQL: (NSString *) sql paramQuery: (NSMutableArray *) params
{
    BOOL resultado = YES;
    sqlite3_stmt *statement;
    const char *chrComando = [sql UTF8String];
    sqlite3_prepare_v2(_db, chrComando, -1, &statement, NULL);
    
    if (params != nil){
     	//carrega os parametros
        for (int i=0; i < [params count]; i++){
           const char * param = [[params objectAtIndex:i] UTF8String];
	       sqlite3_bind_text(statement, i,param ,-1,SQLITE_TRANSIENT);      
        }
    }
    
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
