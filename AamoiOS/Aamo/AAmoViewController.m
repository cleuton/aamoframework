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
    NSMutableArray * viewStack;
    NSMutableArray * controlsStack;
    
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
    viewStack = [[NSMutableArray alloc] init];
    controlsStack = [[NSMutableArray alloc] init];
    [self loadUi:1];
    [self formatSubviews];
    [self.view addSubview:((UIView *)[viewStack lastObject])];
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

static int loadScreen(lua_State *L) {
    double d = lua_tonumber(L, 1);
    [ponteiro loadUi: d];
    [ponteiro hideViews];
    [ponteiro formatSubviews];
    [ponteiro showViews];
    return 0;
}

static int exitScreen(lua_State *L) {
    [ponteiro exitScreenProc];
    return 0;
}

static const struct luaL_Reg aamo_f [] = {
    {"getTextField", getTextField},
    {"showMessage", showMessage},
    {"loadScreen", loadScreen},
    {"exitScreen", exitScreen},    
    {NULL, NULL}
};

int luaopen_mylib (lua_State *L){
    
    luaL_register(L, "aamo", aamo_f);
    
    return 1;
}



//***********************************

- (void) exitScreenProc
{
    /*
     Apple User interface Guidelines recommends to avoid quitting programmatically.
     AAMO iOS Behaves different from AAMO Android in this aspect. it never quits the app, 
     even if it is the last screen on the stack.
     
     O Guia de UI da Apple recomenda evitar sair da app programaticamente. 
     O AAMO iOS se comporta diferente do AAMO Android neste aspecto. Ele nunca volta à tela 
     inicial do dispositivo, mesmo que esteja na primeira tela da app.
     */
    
    if ([viewStack count] > 1) {
        [self hideViews];
        [viewStack removeLastObject];
        [controlsStack removeLastObject];
        [self showViews];
    }
}

- (void) hideViews
{
    UIView * lastView = (UIView *) [viewStack lastObject];
    [lastView removeFromSuperview];
}

- (void) showViews
{
    dynaViews = ((NSMutableArray *)[controlsStack lastObject]);
    [self.view addSubview:((UIView *) [viewStack lastObject])];
}

- (void) formatSubviews
{
    AAmoDynaView *dv = nil;
    CGSize screenSize = self.view.bounds.size;
    CGRect  viewRect = CGRectMake(0, 0, screenSize.width, screenSize.height);
    UIView * mView = [[UIView alloc] initWithFrame:viewRect];
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
                [mView addSubview:tv];
                break;
            }
            case 2: {
                // Label
                UILabel * lv = [[UILabel alloc]
                                initWithFrame:CGRectMake(left, top, width, height)];
                dv.view = lv;
                lv.tag = dv.id;
                [mView addSubview:lv];
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
                [mView addSubview:bv];
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
                [mView addSubview:sv];
                [sv setOn:dv.checked];
                break;
            }
                
        }

        
    }

    [viewStack addObject:mView];
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




- (void) loadUi: (double) screenId
{
    dynaViews = [[NSMutableArray alloc] init];
    NSString * appPath = nil;
    if (screenId == 1) {
        appPath = [[NSBundle mainBundle] pathForResource:@"ui" ofType:@"xml"];
    }
    else {
        int nScreen = screenId;
        appPath = [[NSBundle mainBundle] pathForResource:
                   [NSString stringWithFormat:@"ui_%d", nScreen]
                                                  ofType:@"xml"];
    }

    BOOL success;
    NSURL *xmlURL = [NSURL fileURLWithPath:appPath];
    NSXMLParser *uiParser = [[NSXMLParser alloc] initWithContentsOfURL:xmlURL];
    [uiParser setDelegate:self];
    [uiParser setShouldResolveExternalEntities:YES];
    success = [uiParser parse];
    [controlsStack addObject:dynaViews];
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
    
    // *********************************************** TEM QUE PESQUISAR SUBVIEWS DA SUBVIW
    
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
