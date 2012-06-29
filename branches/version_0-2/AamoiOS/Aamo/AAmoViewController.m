//
//  AAmoViewController.m
//  Aamo
//
//  Copyright (c) 2011 __The Code Bakers__. All rights reserved.
//

#import "AAmoViewController.h"
#import "AAmoDynaView.h"

#define VERSION 0.1
#define MACRO_UI 1
#define MACRO_ELEMENT 2

@interface AAmoViewController ()
{
    @private
    NSMutableArray * dynaViews;
    int uiid;
    NSString * title;
    NSString * onLoadScript;
    NSString * onEndScript;
    NSMutableString * currentStringValue;
    NSString * currentElementName;
    int currentMacro;
    AAmoDynaView * currentElement;
    
}
@end

static AAmoViewController * ponteiro;

@implementation AAmoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    ponteiro = self;
    
    // initialize Lua and our load our lua file
    L = luaL_newstate(); // create a new state structure for the interpreter
    luaL_openlibs(L); // load all the basic libraries into the interpreter
    
    lua_settop(L, 0);
    
    
    dynaViews = [[NSMutableArray alloc] init];
    [self loadUi];
    [self formatSubviews];
}

- (void) execLua: (NSString *) script
{
    NSString *luaFilePath = [[NSBundle mainBundle] pathForResource:script ofType:@"lua"];
    int err = luaL_loadfile(L, [luaFilePath cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    //lua_getglobal(L,"aamoProcess");
    err = lua_pcall(L, 0, 0, 0);
}

// Lua Callbacks! Parte da API AAMO:

static int showMessage(lua_State *L){
    const char *msg = lua_tostring(L, -1);
    size_t l = lua_strlen(L, -1); 
    NSString *textoMsg = [NSString stringWithCString:msg encoding:[NSString defaultCStringEncoding]];
    [ponteiro sendAlert:textoMsg];
}

static int getTextField(lua_State *L){

    double d = lua_tonumber(L, 1);  /* get argument */
    const char * texto = [ponteiro getTextFieldContent:d];
    lua_pushstring(L, texto);
    return 1;  /* number of results */
}

static const struct luaL_Reg aamo_f [] = {
    {"getTextField", getTextField},
    {"showMessage", showMessage},
    {NULL, NULL}
};

int luaopen_mylib (lua_State *L){
    
    luaL_register(L, "aamo", aamo_f);
    
    return 1;
}



//***********************************

- (void) formatSubviews
{
    AAmoDynaView *dv = nil;
    CGSize screenSize = self.view.bounds.size;
    for(id el in dynaViews) {
        dv = el;
        float height = (dv.percentHeight / 100) * screenSize.height;
        float width = (dv.percentWidth / 100) * screenSize.width;
        float top = (dv.percentTop / 100) * screenSize.height;
        float left = (dv.percentLeft / 100) * screenSize.width;
        switch (dv.type) {
            case 1: {
                // Textbox
                UITextField * tv = [[UITextField alloc] 
                        initWithFrame:CGRectMake(left, top, width, height)];
                tv.borderStyle = UITextBorderStyleRoundedRect;
                dv.view = tv;
                tv.tag = dv.id; 
                [self.view addSubview:tv];
                break;
            }
            case 2: {
                // Label
                UILabel * lv = [[UILabel alloc]
                                initWithFrame:CGRectMake(left, top, width, height)];
                dv.view = lv;
                lv.tag = dv.id;
                [self.view addSubview:lv];
                if (dv.text != nil) {
                    lv.text = dv.text;
                    
                }
                break;
            }
            case 3: {
                // Button
                UIButton *bv = [UIButton buttonWithType:UIButtonTypeRoundedRect];
                bv.frame = CGRectMake(left, top, width, height);
                dv.view = bv;
                bv.tag = dv.id;
                [self.view addSubview:bv];
                [bv addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchDown];
                if (dv.text != nil) {
                    [bv setTitle:dv.text 
                             forState:(UIControlState)UIControlStateNormal];
                }
                break;
            }
            case 4: {
                // Checkbox
                UISwitch * sv = [[UISwitch alloc] initWithFrame:CGRectMake(left, top, width, height)];
                dv.view = sv;
                sv.tag = dv.id;
                [self.view addSubview:sv];
                [sv setOn:dv.checked];
                break;
            }
                
        }
        
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}

- (void) loadUi
{
    NSString* appPath = [[NSBundle mainBundle] pathForResource:@"ui" ofType:@"xml"];
    BOOL success;
    NSURL *xmlURL = [NSURL fileURLWithPath:appPath];
    NSXMLParser *uiParser = [[NSXMLParser alloc] initWithContentsOfURL:xmlURL];
    [uiParser setDelegate:self];
    [uiParser setShouldResolveExternalEntities:YES];
    success = [uiParser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict 
{
    
    currentElementName = [NSString stringWithString:elementName];
    if ([elementName isEqualToString:@"element"]) {
        currentElement = [[AAmoDynaView alloc] init];
        [dynaViews addObject:currentElement];
        currentElement.id = 0;
        currentElement.type = 0;
        currentElement.percentTop = 0;
        currentElement.percentLeft = 0;
        currentElement.percentHeight = 0;
        currentElement.percentWidth = 0;
        currentElement.checked = NO;
        currentElement.text = nil;
        currentElement.onCompleteScript = nil;
        currentElement.onChangeScript = nil;
        currentElement.onClickScript = nil;
        currentMacro = MACRO_ELEMENT;
    }
    else if ([elementName isEqualToString: @"ui"]){
        uiid = 1;
        title = [NSString stringWithFormat:@"AAMO v. %i",VERSION];
        onLoadScript = nil;
        onEndScript = nil;
        currentMacro = MACRO_UI;
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (!currentStringValue) {
        // currentStringValue is an NSMutableString instance variable
        currentStringValue = [[NSMutableString alloc] init];
    }
    [currentStringValue appendString:string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName 
{
    if ([elementName isEqualToString:@"ui"] ||
        [elementName isEqualToString:@"element"]) {
        return;
    }
    if (currentMacro == MACRO_UI) {
        if ([currentElementName isEqualToString: @"ui"]) {
            if ([currentElementName isEqualToString: @"version"]) {
                // version
                float version = [[currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] floatValue];
                if (version > VERSION) {
                    NSString * mensagem = [NSString stringWithFormat:@"WRONG XML VERSION. MUST BE 1.0"];
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid XML" 
                                                                    message:mensagem delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
                    [alert show];
                }
            }
        }
        else if ([currentElementName isEqualToString: @"uiid"]) {
            uiid = [[currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] intValue];
        }
        else if ([currentElementName isEqualToString: @"title"]) {
            title = [currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
        else if ([currentElementName isEqualToString: @"onLoadScript"]) {
            onLoadScript = [currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
        else if ([currentElementName isEqualToString: @"onEndScript"]) {
            onEndScript = [currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
    }
    else if (currentMacro == MACRO_ELEMENT) {
        
        if ([currentElementName isEqualToString: @"id"]) {
            currentElement.id = [[currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] intValue];
        }
        else if ([currentElementName isEqualToString: @"type"]) {
            currentElement.type = [[currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] intValue];
        }
        else if ([currentElementName isEqualToString: @"percentTop"]) {
            currentElement.percentTop = [[currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] floatValue];
            
        }
        else if ([currentElementName isEqualToString: @"percentLeft"]) {
            currentElement.percentLeft = [[currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] floatValue];
        }
        else if ([currentElementName isEqualToString: @"percentHeight"]) {
            currentElement.percentHeight = [[currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] floatValue];
        }
        else if ([currentElementName isEqualToString: @"percentWidth"]) {
            currentElement.percentWidth = [[currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] floatValue];
        }
        else if ([currentElementName isEqualToString: @"checked"]) {
            currentElement.checked = [[currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] boolValue];
        }
        else if ([currentElementName isEqualToString: @"text"]) {
            currentElement.text = [currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
           
        }
        else if ([currentElementName isEqualToString: @"onCompleteScript"]) {
            currentElement.onCompleteScript = [currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
        else if ([currentElementName isEqualToString: @"onClickScript"]) {
            currentElement.onClickScript = [currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
        else if ([currentElementName isEqualToString: @"onChangeScript"]) {
            currentElement.onChangeScript = [currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }

    }

    currentStringValue = nil;
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError 
{
    NSString * mensagem = [NSString stringWithFormat:@"%@ line: %i Column: %i", 
    [[parser parserError] localizedDescription], [parser lineNumber],
    [parser columnNumber]];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ui.xml" 
                message:mensagem delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
    [alert show];
}

- (IBAction)dismissKeyboard:(id)sender {
    NSArray *subviews = [self.view subviews];
    for (id objects in subviews) {
        if ([objects isKindOfClass:[UITextField class]]) {
            UITextField *theTextField = objects;
            if ([objects isFirstResponder]) {
                [theTextField resignFirstResponder];
            }
        } 
    }
}

- (const char *) getTextFieldContent: (double) number
{
    AAmoDynaView *dv = nil;

    for(id el in dynaViews) {
        dv = el;
        if (dv.type == 1) {
            if (dv.id == number) {
                UITextField *theTextField = (UITextField *) dv.view;
                return [theTextField.text cStringUsingEncoding:[NSString defaultCStringEncoding]];
            }
        }
    }
}

-(void) sendAlert:(NSString *) msg
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"MSG" 
                                                    message:msg delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];}

-(void) buttonClick:(id)sender 
{
    AAmoDynaView *dv = nil;
    for(id el in dynaViews) {
        dv = el;
        if (dv.type == 3) {
            if (dv.id == ((UIView *)sender).tag) {
                [self execLua: dv.onClickScript];
                return;
            }
        }
    }


}

@end
