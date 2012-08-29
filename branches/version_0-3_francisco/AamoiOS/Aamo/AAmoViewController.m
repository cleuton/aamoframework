//
//  AAmoViewController.m
//  Aamo
//
//  Copyright (c) 2011 __The Code Bakers__. All rights reserved.
//

#import "AAmoViewController.h"
#import "AAmoDynaView.h"
#import "AAmoScreenData.h"
#import "AamoDBAdapter.h"
#import "AAmoMapaQuery.h"


#define VERSION 0.2
#define MACRO_UI 1
#define MACRO_ELEMENT 2

@interface AAmoViewController ()
{
@private
    NSMutableArray * dynaViews;
    
    AAmoScreenData * screenData;
    
    NSMutableString * currentStringValue;
    NSString * currentElementName;
    int currentMacro;
    AAmoDynaView * currentElement;
    NSMutableArray * viewStack;
    NSMutableArray * controlsStack;
    NSMutableArray * screenDataStack;
    int globalErrorCode;
    	
    
    
    
}
@end

static AAmoViewController * ponteiro;
static AamoDBAdapter * dbAdapter;

//errors
const int errorCode_10 = 10;
const int errorCode_11 = 11;
const int errorCode_12 = 12;

const int errorCode_20 = 20; //erro no open database
const int errorCode_21 = 21; //erro na query 
const int errorCode_22 = 22; //erro na execução do ExecSQL

static int globalErrorCode;
static sqlite3_stmt * statement;
static NSDictionary *dicParam;

@implementation AAmoViewController

@synthesize mapaConsultas;
@synthesize mapaQuery;
@synthesize isEof;
static int contador;
@synthesize args;

+ (void) initialize {
   dbAdapter = [[AamoDBAdapter alloc] init];
}

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
    screenDataStack = [[NSMutableArray alloc] init];
    screenData = [[AAmoScreenData alloc] init];
    [self loadUi:1];
    [self formatSubviews];
    [self.view addSubview:((UIView *)[viewStack lastObject])];
    
    //errors
    globalErrorCode = 0;
    
    //dbAdapter = [[AamoDBAdapter alloc] init];
    args = [[NSMutableArray alloc] init];
    mapaConsultas = [NSMutableDictionary dictionary];
    mapaQuery = [[NSMutableArray alloc] init];
}

- (void) execLua: (NSString *) script
{
    
    NSString *luaFilePath = [[NSBundle mainBundle] pathForResource:script ofType:@"lua"];
    int lenComando = [script length];
    NSRange encontrou = [script rangeOfString:@"lua::"];
    int err = 0;
    if (encontrou.location == NSNotFound) {
        err = luaL_loadfile(L, [luaFilePath cStringUsingEncoding:[NSString defaultCStringEncoding]]); 
    }
    else {
        // Immediate Lua command
        char str [lenComando + 1];
        [[script substringFromIndex:5] getCString:str maxLength:lenComando encoding:[NSString defaultCStringEncoding]];
        luaL_loadstring(L, (const char *) str);
    }
    err = lua_pcall(L, 0, 0, 0);
    if (err != 0) {
        const char *msg = lua_tostring(L, -1);
        NSString *textoMsg = [NSString stringWithCString:msg encoding:[NSString defaultCStringEncoding]];
        NSLog(@"AAMO ERROR: %@",textoMsg);
        
    }
}

// Lua Callbacks! Parte da API AAMO:

static int showMessage(lua_State *L){
	const char *msg = lua_tostring(L, -1);
	NSString *textoMsg = [NSString stringWithCString:msg encoding:[NSString defaultCStringEncoding]];
    [ponteiro sendAlert:textoMsg];
	
    return 0;
}

static int getTextField(lua_State *L){
	
	if (lua_gettop (L)>0){
	    double d = lua_tonumber(L, 1);  /* get argument */
	    if (d == 0){
            globalErrorCode = errorCode_12 ; 
            return 0;
        }
        else {
            const char * texto = [ponteiro getTextFieldContent:d];
            if (texto == nil){
                globalErrorCode = errorCode_12 ; 
                return 0;
            }else{
                lua_pushstring(L, texto);  
                return 1;  /* number of results */
            }
        }   
	}
	else {
		globalErrorCode = errorCode_10 ; 
		return 0;
	}	
}

static int loadScreen(lua_State *L) {
	
	if (lua_gettop (L)>0){
	    double d = lua_tonumber(L, 1);
	    if (d == 0){
            globalErrorCode = errorCode_12 ; 
        }
        else {
            [ponteiro loadUi: d];
            if (globalErrorCode == 0){
               [ponteiro hideViews];
               [ponteiro formatSubviews];
               [ponteiro showViews];
            }
            
        }	
	}
	else {
		globalErrorCode = errorCode_10 ; 
	}	    
    
    return 0;
}

static int exitScreen(lua_State *L) {
    [ponteiro exitScreenProc];
    return 0;
}

static int showLog(lua_State *L) {
	if (lua_gettop (L)>0){
	    const char *msg = lua_tostring(L, -1);
	    if (msg == nil){
            globalErrorCode = errorCode_12 ; 
		}
        else {
    		NSString *textoMsg = [NSString stringWithCString:msg encoding:[NSString defaultCStringEncoding]];
		    NSLog(@"%@",textoMsg);
        }    
	}
	else {
		globalErrorCode = errorCode_10 ; 
	}
    
	return 0;			
}

static int getCheckBox(lua_State *L){
    int top = lua_gettop (L);
    if (top>0){
        double d = lua_tonumber(L, 1);  /* get argument */
        if (d == 0){
            globalErrorCode = errorCode_12 ; 
            return 0;
        }
        else
        {
            int valor = [ponteiro getCheckBox:d];
	    	if (valor == 0){
                globalErrorCode = errorCode_12 ; 
                return 0;	
	    	}
	    	else{
		    	lua_pushnumber(L, valor);
	    		return 1;  /* number of results */
    		}
        }
    }
    else {
		globalErrorCode = errorCode_10 ; 
		return 0;	
	}
}

static int setCheckBox(lua_State *L) {
	
	if (lua_gettop (L)>0){
    	
    	double d = lua_tonumber(L, 1); // CheckBox id
    	if (d == 0){
            globalErrorCode = errorCode_12 ; 
            return 0;
    	}
    	
    	double e = lua_tonumber(L, 2); // CheckBox id
    	if (e == 0){
            globalErrorCode = errorCode_12 ; 
            return 0;
    	}
        
    	[ponteiro setCheckBoxValue:d value:e];
    	return 0;
	}
	else {
		globalErrorCode = errorCode_10 ; 
		return 0;	
	}		
}

static int getCurrentScreenId(lua_State *L) {
    lua_pushnumber(L, [ponteiro getCurrentScreenId]);
    return 1;
}

static int getLabelText(lua_State *L) {
	if (lua_gettop (L)>0){
	    double d = lua_tonumber(L, 1);  /* get argument */
	    if (d == 0){
            globalErrorCode = errorCode_12 ; 
            return 0;
    	}
    	
    	const char * texto = [ponteiro getLabelContent:d];
	    if (texto == nil){
            globalErrorCode = errorCode_12 ; 
		   	return 0;
        }
        else {
            lua_pushstring(L, texto);
    		return 1;  /* number of results */
        }		
	}
	else {
		globalErrorCode = errorCode_10 ; 
		return 0;	
	}	 	
}

static int setLabelText(lua_State *L) {
	if (lua_gettop (L)>0){
	    double d = lua_tonumber(L, 1); // id
	    if (d == 0){
            globalErrorCode = errorCode_12 ; 
            return 0;
    	}
    	
    	const char *msg = lua_tostring(L, -1); // text
        if (msg == nil){
            globalErrorCode = errorCode_12 ; 
		   	return 0;
        }
        else {
		    NSString *textoMsg = [NSString stringWithCString:msg encoding:[NSString defaultCStringEncoding]];
    		[ponteiro setLabelContent:d text:textoMsg];
	    	return 0;
        }	
	}
	else {
		globalErrorCode = errorCode_10 ; 
		return 0;
	}
}

static int setTextField(lua_State *L) {
	if (lua_gettop (L)>0){
	    double d = lua_tonumber(L, 1); // id
	    if (d == 0){
            globalErrorCode = errorCode_12 ; 
            return 0;
    	}
    	
    	const char *msg = lua_tostring(L, -1); // text
	    if (msg == nil){
            globalErrorCode = errorCode_12 ; 
        }
        else {
	    	NSString *textoMsg = [NSString stringWithCString:msg encoding:[NSString defaultCStringEncoding]];
    		[ponteiro setTextContent:d text:textoMsg];
        }	
        return 0;
	}
	else {
		globalErrorCode = errorCode_10 ; 
		return 0;
	}    
}

static int getErrorCode(lua_State *L) {
	
   	lua_pushnumber(L, globalErrorCode);
   	return 1;
}

static int query (lua_State *L)
{
    if (lua_gettop (L)>0){
        const char *title = lua_tostring(L, 1);
	    if (title == nil){
            globalErrorCode = errorCode_12 ; 
            return 0;
		}
       
        const char *sql = lua_tostring(L, 2);
        if (sql == nil){
            globalErrorCode = errorCode_12 ; 
            return 0;
		}
        
    	NSMutableArray * args = [[NSMutableArray alloc] init];
        //getQueryParams(L, 3);
        
       
        
        for (int i=3; i < lua_gettop (L)>0; i++) {
            
           const char *param = lua_tostring(L, i);
           NSString *texto = [NSString stringWithCString:param encoding:[NSString defaultCStringEncoding]];
           
           [args addObject:texto];
        }
        
        contador =0;
        
        NSString *querySQL = [[NSString alloc] initWithUTF8String:(const char *) sql];
        NSMutableArray *consultas = (NSMutableArray *) [dbAdapter query:querySQL  paramQuery:args]; 
        
        if (contador < [consultas count])
        {
            ponteiro.isEof = NO;
        } 
        else {
            ponteiro.isEof = YES;
            return 0;            
        }
        
        NSArray *row = [consultas objectAtIndex:contador];
        lua_newtable(L);      
        for(int j=0; j< [row count]; j++) {
            NSString *retorno = [row objectAtIndex:j];
            NSLog(@"retorno da consulta %@",  retorno);
            char *coluna = (char *)sqlite3_column_text(statement, j);
           	lua_pushnumber(L, j);
			lua_pushstring(L, coluna);
           	lua_settable(L, -3); 
        }
        	    
        NSString *chave = [[NSString alloc] initWithUTF8String:title];
        AAmoMapaQuery * gp = [[AAmoMapaQuery alloc] init];
        gp.name = chave;
        
        if ([ponteiro.mapaQuery containsObject:gp]) {
            int indice = [ponteiro.mapaQuery indexOfObject:gp];
            gp = [ponteiro.mapaQuery objectAtIndex:indice];
        }
        else{
            
            gp.object = consultas;
            [ponteiro.mapaQuery addObject:gp];
        }    
        
        
    	return 1;
	}
	else {
		globalErrorCode = errorCode_10 ; 
		return 0;
	}    
}

static int next (lua_State *L)
{
    if (lua_gettop (L)>0){
        const char *title = lua_tostring(L, 1);
	    if (title == nil){
            globalErrorCode = errorCode_12 ; 
            return 0;
		}
        
        NSString *chave = [[NSString alloc] initWithUTF8String:title];
        
        AAmoMapaQuery * mp = [[AAmoMapaQuery alloc] init];
    	mp.name = chave;
    
        if ([ponteiro.mapaQuery containsObject:mp]) {
           int indice = [ponteiro.mapaQuery indexOfObject:mp];
           mp = [ponteiro.mapaQuery objectAtIndex:indice];
        }
        
        contador++;
        
        NSMutableArray *consultas = (NSMutableArray *) mp.object;
        
        if (contador < [consultas count])
        {
            ponteiro.isEof = NO;
        } 
        else {
            ponteiro.isEof = YES;
            return 0;            
        }

        
        NSArray *row = [consultas objectAtIndex:contador];
                
        lua_newtable(L);      
        for(int j=0; j< [row count]; j++) {
            NSString *retorno = [row objectAtIndex:j];
            NSLog(@"retorno %@",  retorno);
            char *coluna = (char *)sqlite3_column_text(statement, j);
           	lua_pushnumber(L, j);
			lua_pushstring(L, coluna);
           	lua_settable(L, -3); 
        }
        
        
    	return 1;
	}
	else {
		globalErrorCode = errorCode_10 ; 
		return 0;
	}    
}


static int closeCursor(lua_State *L)
{
    if (lua_gettop (L)>0){
        const char *title = lua_tostring(L, 1);
	    if (title == nil){
            globalErrorCode = errorCode_12 ; 
            return 0;
		}
        
        NSString *chave = [[NSString alloc] initWithUTF8String:title];
        AAmoMapaQuery * mp = [[AAmoMapaQuery alloc] init];
    	mp.name = chave;
    
    	if ([ponteiro.mapaQuery containsObject:mp]) {
           int indice = [ponteiro.mapaQuery indexOfObject:mp];
           [ponteiro.mapaQuery removeObjectAtIndex:indice];
           
        }
        
        mp = nil;
        chave = nil;
       
    	return 1;
	}
	else {
		globalErrorCode = errorCode_10 ; 
		return 0;
	}    
}

static int eof (lua_State *L)
{
    if (lua_gettop (L)>0){
        const char *title = lua_tostring(L, 1);
	    if (title == nil){
            globalErrorCode = errorCode_12 ; 
            return 0;
		}
        
        NSString *chave = [[NSString alloc] initWithUTF8String:title];
        
        AAmoMapaQuery * mp = [[AAmoMapaQuery alloc] init];
    	mp.name = chave;
    
    	if ([ponteiro.mapaQuery containsObject:mp]) {
           int indice = [ponteiro.mapaQuery indexOfObject:mp];
           mp = [ponteiro.mapaQuery objectAtIndex:indice];
        }
        
               
        BOOL result = [ponteiro isEof]; 
        if (result)
        {
           lua_pushboolean(L, true);
        } else {
           lua_pushboolean(L, false);

        }
        
    	return 1;
	}
	else {
		globalErrorCode = errorCode_10 ; 
		return 0;
	}    
}

static int execSQL (lua_State *L)
{
    int top = lua_gettop (L);
    NSLog(@"top %d", top);
    
    if (lua_gettop (L)>0){
        const char *sql = lua_tostring(L, 1);
        if (sql == nil){
            globalErrorCode = errorCode_12 ; 
            return 0;
		}
        
        int position = 2; 
        int posType = -2;
    	int ret = paramType (L, position, posType);
        
        NSString *querySQL = [[NSString alloc] initWithUTF8String:(const char *) sql];
        NSLog(@"SQL Controller %@", querySQL);    
        
        BOOL result = [dbAdapter execSQL:querySQL paramQuery:ponteiro.args]; 
        
        if (result){
           NSString *texto = @ "Command executed successfully.";
           const char *param = [texto UTF8String];
           lua_pushstring(L, param);
        }  
        else {
            globalErrorCode = errorCode_22 ; 
            return 0;
        }
    	return 1;
	}
	else {
		globalErrorCode = errorCode_10 ; 
		return 0;
	}    

}

static int openDatabase (lua_State *L)
{
    if (lua_gettop (L)>0){
        const char *dbName = lua_tostring(L, 1);
        if (dbName == nil){
            globalErrorCode = errorCode_12 ; 
            return 0;
        }
        
        NSString *databaseName = [[NSString alloc] initWithUTF8String:dbName];
        
        int ret = [dbAdapter openDatabase:databaseName]; 
	    if (ret == 1) {
	        globalErrorCode = errorCode_20 ; 
            return 0;	
	    }
	
        return 1;
   }
   else {
	   globalErrorCode = errorCode_10 ; 
	   return 0;
   }    

}

static int closeDatabase (lua_State *L)
{
    if (lua_gettop (L)>0){
        const char *dbName = lua_tostring(L, 1);
        if (dbName == nil){
            globalErrorCode = errorCode_12 ; 
            return 0;
		}
        
        NSString *databaseName = [[NSString alloc] initWithUTF8String:dbName];
        
        [dbAdapter closeDatabase:databaseName ]; 
        
        return 1;
	}
	else {
		globalErrorCode = errorCode_10 ; 
		return 0;
	}    

}

int paramType (lua_State *L, int position, int posType) 
{
    int top = lua_gettop (L);	        
    
    for (int i=position; i <= top; i++) {
        
    	int paramType = lua_type(L, posType);
        NSLog(@"paramType %d",paramType);
        AAmoMapaQuery * mq = [[AAmoMapaQuery alloc] init];
        
        switch (paramType) {
            case LUA_TSTRING: {             
                const char *param = lua_tostring(L, i);
                NSLog(@"valor string lua: %s", param);
                
                NSString *texto = [NSString stringWithCString:param encoding:[NSString defaultCStringEncoding]];
                NSString *ch=@"key"; 
                NSString *chave = [ch stringByAppendingFormat:@"%d ",i];
                
                mq.name = chave;
                mq.object = texto;
                mq.type = 1;
                
                break;
            }          
            case LUA_TNUMBER: {             
                double num = lua_tonumber(L, i);
                NSLog(@"valor LUA num: %f", num);
                NSNumber *numberKey = [NSNumber numberWithInt:num];
                NSLog(@"number %@",numberKey);
                
                NSString *ch=@"key"; 
                NSString *chave = [ch stringByAppendingFormat:@"%d ",i];
                NSLog(@"chave %@",chave);
                
                mq.name = chave;
                mq.object = numberKey;
                mq.type = 2;
                
                break;
            }
         
        }
        posType--;
        
        [ponteiro.args addObject:mq];
        

    }
    
    for (AAmoMapaQuery* obj in ponteiro.args){
        NSLog(@"valor name: %@", obj.name);
        NSLog(@"valor object: %@", obj.object);
    }    
     
    return 0;
}

static const struct luaL_Reg aamo_f [] = {
    {"getTextField", getTextField},
    {"showMessage", showMessage},
    {"loadScreen", loadScreen},
    {"exitScreen", exitScreen}, 
    {"log", showLog},
    {"getCheckBox", getCheckBox},
    {"setCheckBox", setCheckBox},
    {"getCurrentScreenId", getCurrentScreenId},
    {"getLabelText", getLabelText},
    {"setLabelText", setLabelText},
    {"setTextField", setTextField},
    {"getError", getErrorCode},
    {"query", query},
    {"execSQL", execSQL},
    {"next", next},
	{"eof", eof},
	{"closeCursor", closeCursor},
    {"closeDatabase", closeDatabase},
    {"openDatabase", openDatabase},
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
     
     As a side effect, "onEndScript" never gets executed in ui.xml (first screen). Only when the view gets unloaded.
     
     O Guia de UI da Apple recomenda evitar sair da app programaticamente. 
     O AAMO iOS se comporta diferente do AAMO Android neste aspecto. Ele nunca volta à tela 
     inicial do dispositivo, mesmo que esteja na primeira tela da app.
     
     */
    
    if ([viewStack count] > 1) {
        [self hideViews];
        [viewStack removeLastObject];
        [controlsStack removeLastObject];
        
        // Check if the screen has an "onEndScript"
        
        if (screenData.onEndScript != nil && [screenData.onEndScript length] > 0) {
            [self execLua: screenData.onEndScript];
        }
        [screenDataStack removeLastObject];
        screenData = screenDataStack.lastObject;
        [self showViews];
    }
}

- (int) getCheckBox:(double)idc
{
    int valor = 0;
    for (AAmoDynaView * dv in dynaViews) {
        if (dv.id == idc) {
            if (dv.type == 4) {
                if ([((UISwitch *)dv.view) isOn]) {
                    valor = 1;
                }
                break;
            }
        }
    }
    return valor;
}

- (void) setCheckBoxValue:(double) d value:(double) e
{
    for (AAmoDynaView * dv in dynaViews) {
        if (dv.id == d) {
            if (dv.type == 4) {
                [((UISwitch *)dv.view) setOn:(e == 1)];
            }
        }
    } 
}

- (int) getCurrentScreenId
{
    return screenData.uiid;
}

- (const char *) getLabelContent: (double) number
{
    AAmoDynaView *dv = nil;
    
    for(id el in dynaViews) {
        dv = el;
        if (dv.type == 2) {
            if (dv.id == number) {
                UILabel *theTextField = (UILabel *) dv.view;
                return [theTextField.text cStringUsingEncoding:[NSString defaultCStringEncoding]];
            }
        }
    }
}

- (void) setLabelContent: (double) number text: (NSString *) content
{
    AAmoDynaView *dv = nil;
    
    for(id el in dynaViews) {
        dv = el;
        if (dv.type == 2) {
            if (dv.id == number) {
                UILabel *theTextField = (UILabel *) dv.view;
                theTextField.text = content;
                break;
            }
        }
    }
}

- (void) setTextContent:(double)number text:(NSString *)content
{
    AAmoDynaView *dv = nil;
    
    for(id el in dynaViews) {
        dv = el;
        if (dv.type == 1) {
            if (dv.id == number) {
                UITextField *theTextField = (UITextField *) dv.view;
                theTextField.text = content;
                break;
            }
        }
    }
}

- (int) getGlobalErrorCode
{
    return globalErrorCode;
}

//*******************************************************************************************

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
    UIControl * mView = [[UIControl alloc] initWithFrame:viewRect];
    [mView addTarget:self action:@selector(dismissKeyboard:) forControlEvents:UIControlEventTouchUpInside];
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
                [sv addTarget:self action:@selector(checkBoxChanged:) forControlEvents:UIControlEventValueChanged];
                [mView addSubview:sv];
                [sv setOn:dv.checked];
                break;
            }
                
        }
        
        
    }
    
    [viewStack addObject:mView];
    [screenDataStack addObject:screenData];
    // Check "onLoadScreen" event:
    
    if (screenData.onLoadScript != nil && [screenData.onLoadScript length] > 0) {
        [self execLua: screenData.onLoadScript];
    }
    
}

- (void) checkBoxChanged:(UISwitch *)sender
{
    for (AAmoDynaView * dv in dynaViews) {
        if (dv.id == sender.tag) {
            if (dv.type == 4) {
                if (dv.onChangeScript != nil && [dv.onChangeScript length] > 0) {
                    [self execLua:dv.onChangeScript];
                    break;
                }
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


- (void) loadUi: (double) screenId
{
    dynaViews = [[NSMutableArray alloc] init];
    screenData = [[AAmoScreenData alloc] init];
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
    //se ocorreu erro na leitura do arquivo
    if (appPath == nil){
        globalErrorCode = errorCode_11 ; 
        return;
    }
    else {
    
        BOOL success;
        NSURL *xmlURL = [NSURL fileURLWithPath:appPath];
        NSXMLParser *uiParser = [[NSXMLParser alloc] initWithContentsOfURL:xmlURL];
        [uiParser setDelegate:self];
        [uiParser setShouldResolveExternalEntities:YES];
        success = [uiParser parse];
        [controlsStack addObject:dynaViews];
        
        globalErrorCode = 0 ; 
    }
    
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
        screenData.uiid = 1;
        screenData.title = [NSString stringWithFormat:@"AAMO v. %i",VERSION];
        screenData.onLoadScript = nil;
        screenData.onEndScript = nil;
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
            screenData.uiid = [[currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] intValue];
        }
        else if ([currentElementName isEqualToString: @"title"]) {
            screenData.title = [currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
        else if ([currentElementName isEqualToString: @"onLoadScript"]) {
            screenData.onLoadScript = [currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
        else if ([currentElementName isEqualToString: @"onEndScript"]) {
            screenData.onEndScript = [currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
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
        for (id controle in [objects subviews]) {
            if ([controle isKindOfClass:[UITextField class]]) {
                UITextField *theTextField = controle;
                if ([controle isFirstResponder]) {
                    [theTextField resignFirstResponder];
                }
            }            
        }
    }
}

- (const char *) getTextFieldContent: (double) number
{
    AAmoDynaView *dv = nil;
    const char * saida = nil;
    for(id el in dynaViews) {
        dv = el;
        if (dv.type == 1) {
            if (dv.id == number) {
                UITextField *theTextField = (UITextField *) dv.view;
                saida = [theTextField.text cStringUsingEncoding:[NSString defaultCStringEncoding]];
                break;
            }
        }
    }
    return saida;
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
