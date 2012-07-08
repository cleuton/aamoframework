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
- (const char *) getTextFieldContent: (double) number;
- (void) loadUi: (double) screenId;
- (void) formatSubviews;
- (void) hideViews;
- (void) showViews;
- (void) exitScreenProc;
-(void) sendAlert:(NSString *) msg;
- (IBAction)dismissKeyboard:(id)sender;
@end
