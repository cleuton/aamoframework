//
//  AAmoResourceBundle.m
//  Aamo
//
//  Created by Cleuton Sampaio on 17/07/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AAmoResourceBundle.h"

@interface AAmoResourceBundle ()
{
    @private
    NSString * userLanguage;
    NSString * userCountry;
    NSString * preferredName;
    NSString * languageName;
    NSString * defaultName;
    NSArray * arrNames;
    NSMutableDictionary * dict;
}
@end

@implementation AAmoResourceBundle

- (id)init
{
    self = [super init];
    if (self) {
        // Init code
        [self initVars];
        [self loadDict];
    }
    return self;
}

- (NSString *)getString:(NSString *)key
{
    if (dict != nil) {
        return [dict objectForKey:key];
    }
    else {
        return key;
    }
}

- (void) initVars
{
    userLanguage = [[NSLocale preferredLanguages] objectAtIndex:0];
    userCountry = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
    defaultName = [NSString stringWithFormat:@"aamol10n"];
    languageName = [NSString stringWithFormat:@"%@_%@", defaultName, userLanguage];
    preferredName = [NSString stringWithFormat:@"%@_%@", languageName, userCountry];
    dict = [[NSMutableDictionary alloc] init];
    arrNames = [NSArray arrayWithObjects:preferredName, languageName, defaultName, nil];
}

- (void) loadDict
{
    NSString *path = nil;
    int x = 0;
    do {
        NSString * nome = [arrNames objectAtIndex:(x++)];
        NSLog(@"%@", nome);
        path =  [[NSBundle mainBundle] pathForResource: nome
                                                      ofType:@"properties"];
        if (x == 3) {
            break;
        }
    } while (path == nil);

    if (path != nil) {
        NSString* content = [NSString stringWithContentsOfFile:path
                                                      encoding:NSUTF8StringEncoding
                                                         error:NULL];
        content = [content stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
        NSArray* linhas = [content componentsSeparatedByString: @"\n"];
        for (NSString * linha in linhas) {
            NSRange range = [linha rangeOfString: @"="];
            if (range.location != NSNotFound) {
                NSString * chave = [[linha substringToIndex:range.location] 
                                    stringByTrimmingCharactersInSet:
                                    [NSCharacterSet whitespaceCharacterSet]];
                NSString * texto = [[linha substringFromIndex:(range.location + 1)]
                                    stringByTrimmingCharactersInSet:
                                    [NSCharacterSet whitespaceCharacterSet]];
                [dict setObject:texto forKey:chave];
            }
            
        }
    }
}


@end
