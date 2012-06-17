//
//  AAmoDynaView.h
//  Aamo
//
//  Copyright (c) 2011 __The Code Bakers__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AAmoDynaView : NSObject
@property int id;
@property int type;
    /*
     1 - Textbox
     2 - Label
     3 - Button
     4 - Checkbox
     */
@property float percentTop;
@property float percentLeft;
@property float percentHeight;
@property float percentWidth;
@property BOOL  checked;
@property (strong, nonatomic) NSString * text;
@property (strong, nonatomic) NSString * onCompleteScript;
@property (strong, nonatomic) NSString * onChangeScript;
@property (strong, nonatomic) NSString * onClickScript;
@property (weak, nonatomic) UIView * view;
@end
