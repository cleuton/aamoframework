//
//  AAmoViewController.h
//  Aamo
//
//  Copyright (c) 2011 __The Code Bakers__. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

@interface AAmoViewController : UIViewController {
    lua_State *L;
}

@property (strong, nonatomic) NSMutableDictionary * mapaConsultas;;

- (const char *) getTextFieldContent: (double) number;
- (const char *) getLabelContent: (double) number;
- (void) setLabelContent: (double) number text: (NSString *) content;
- (void) setTextContent: (double) number text: (NSString *) content;
- (int) getGlobalErrorCode;
- (void) loadUi: (double) screenId;
- (void) formatSubviews;
- (void) hideViews;
- (void) showViews;
- (void) exitScreenProc;
- (void) sendAlert:(NSString *) msg;
- (int) getCheckBox: (double) idc;
- (void) setCheckBoxValue:(double) d value:(double) e;
- (int) getCurrentScreenId;
- (IBAction)dismissKeyboard:(id)sender;
@end
