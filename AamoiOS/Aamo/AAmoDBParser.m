//
//  AAmoDBParser.m
//  
//
//  Created by Cleuton Sampaio on 08/08/12.
//  Copyright (c) 2012 Cleuton Sampaio. All rights reserved.
//

#import "AAmoDBParser.h"
#import "AAmoDatabase.h"
#import "AAmoTable.h"
#import "AAmoColumn.h"

#define  PATH_XML  @"app/bd/bd.xml"
#define  MACRO_BD 1         //aamo-bd
#define  MACRO_TABLES 2      //table
#define  MACRO_COLUMNS 3    //columns
#define  MACRO_COLUMN 4     //column

@interface AAmoDBParser () {
    @private
    NSMutableString * currentStringValue;
    NSString * currentElementName;
    int currentMacro;

    AAmoTable * tableElement;
    AAmoColumn * column;
    AAmoDatabase * db;
    
    NSMutableArray * tables;
    NSMutableArray * columns;
}
//- (int) getBoolean: (NSString *) stretch;
@end

@implementation AAmoDBParser

- (id) init
{
    if ( self = [super init] ) {
        tables = [[NSMutableArray alloc] init];
        columns = [[NSMutableArray alloc] init];
    }
    return self;
}

- (AAmoDatabase * ) readXMLDatabase
{
    NSString * appPath = [[NSBundle mainBundle] pathForResource:@"bd" ofType:@"xml"];
    if (appPath == nil) {
        return nil;        // EM caso de erro: db = nil
    }
    
    BOOL success;
    NSURL *xmlURL = [NSURL fileURLWithPath:appPath];
    NSXMLParser *uiParser = [[NSXMLParser alloc] initWithContentsOfURL:xmlURL];
    [uiParser setDelegate:self];
    [uiParser setShouldResolveExternalEntities:YES];
    db = [[AAmoDatabase alloc] init];
    success = [uiParser parse];
    if (success) {
        db.tablesList = tables;
    }
    return db;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    currentElementName = [NSString stringWithString:elementName];
    if ([elementName isEqualToString:@"aamo-bd"]) {
        currentMacro = MACRO_BD;
    }
    else if ([elementName isEqualToString: @"table"]){
        tableElement = [[AAmoTable alloc] init];
        [tables addObject:tableElement];
        currentMacro = MACRO_TABLES;
    }
    else if ([elementName isEqualToString:@"columns"]) {
        tableElement.columnsList = columns;
        currentMacro = MACRO_COLUMNS;
    }
    else if ([elementName isEqualToString:@"column"]) {
        column = [[AAmoColumn alloc] init];
        [columns addObject:column];
        currentMacro = MACRO_COLUMN;
    }
    
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (currentStringValue == nil) {
        // currentStringValue is an NSMutableString instance variable
        currentStringValue = [[NSMutableString alloc] init];
    }
    [currentStringValue appendString:string];
}


- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{    
    
    if ([elementName isEqualToString:@"aamo-bd"] ||
        [elementName isEqualToString:@"table"]   ||
        [elementName isEqualToString:@"columns"]) {
        return;
    }

    if (currentMacro == MACRO_BD) {
        
        if ([currentElementName isEqualToString: @"version"]) {
            // version
            int version = [[currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] intValue];
            db.version = version;
        }
        else if ([currentElementName isEqualToString: @"name"]) {
            db.name = [currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
    }
    else if (currentMacro == MACRO_TABLES) {
        
        if ([currentElementName isEqualToString: @"name"]) {
            tableElement.name = [currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
        }
        
    }
    else if (currentMacro == MACRO_COLUMNS) {
        NSLog(@"COLUMNS");
        
    }
    else if (currentMacro == MACRO_COLUMN) {
        if ([currentElementName isEqualToString:@"name"]) {
            column.name = [currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
        else if ([currentElementName isEqualToString:@"type"]) {
            column.type = [currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
        else if ([currentElementName isEqualToString:@"primarykey"]) {
            column.primaryKey = YES;
        }
        else if ([currentElementName isEqualToString:@"notnull"]) {
            column.notNull = YES;
        }

    }
    
    currentStringValue = nil;
    currentElementName = nil;
}
/*
- (int) getBoolean: (NSString *) stretch
{
    int resultado = 0;
    if (stretch != nil && [stretch length] == 1) {
        if ([stretch isEqualToString:@"1"]) {
            resultado = 1;
        }
    }
    return resultado;
}*/

@end
