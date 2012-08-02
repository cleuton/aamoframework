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

@interface AAmoViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    lua_State *L;
}
@property BOOL execOnLeaveOnBack;
@property (strong, nonatomic) NSMutableArray * globalParameters;

- (const char *) getTextFieldContent: (double) number;
- (const char *) getLabelContent: (double) number;
- (void) setLabelContent: (double) number text: (NSString *) content;
- (void) setTextContent: (double) number text: (NSString *) content;
- (int) getGlobalErrorCode;
- (void) loadUi: (double) screenId;
- (void) formatSubviews;
- (void) execOnLeave;
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
- (NSString *) checkL10N: (NSString *) key;
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
- (UITableViewCell *)tableView:(UITableView *)tableView 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView 
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
- (void) setListBox:(double)d text:(NSString*)textoMsg;
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (void) clearListBoxControl: (double) idl;
- (void) showScreenMenu;
@end
