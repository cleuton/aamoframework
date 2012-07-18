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
#import "AAmoResourceBundle.h"

@interface AAmoViewController : UIViewController {
    lua_State *L;
}
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
-(void) sendAlert:(NSString *) msg;
- (int) getCheckBox: (double) idc;
- (void) setCheckBoxValue:(double) d value:(double) e;
- (int) getCurrentScreenId;
- (BOOL) showScreen: (double) screenNumber;
- (IBAction)dismissKeyboard:(id)sender;
- (void) loadBundle;
@end
