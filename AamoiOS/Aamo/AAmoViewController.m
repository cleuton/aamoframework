//
//  AAmoViewController.m
//  Aamo
//
//  Copyright (c) 2011 __The Code Bakers__. All rights reserved.
//

#import "AAmoViewController.h"
#import "AAmoDynaView.h"
#import "AAmoScreenData.h"
#import "AAmoGlobalParameter.h"
#import "AamoDBAdapter.h"
#import "AAmoMapaQuery.h"

#define VERSION 1.0
#define MACRO_UI 1
#define MACRO_ELEMENT 2
#define MACRO_MENU 3
#define L10N_PREFIX @"l10n::"
#define TEXTBOX 1
#define LABEL 2
#define BUTTON 3
#define CHECKBOX 4
#define LISTBOX 5
#define WEBBOX 6
#define IMAGEBOX 7
#define GLOBAL_LISTBOX_INDEX @"aamo::selectedIndex"
#define GLOBAL_LISTBOX_TEXT  @"aamo::selectedText";
#define GLOBAL_MENU_INDEX @"aamo::selectedMenuIndex"
#define GLOBAL_MENU_TEXT  @"aamo::selectedMenuText";



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

    AAmoResourceBundle * res;
    
}
@end

static AAmoViewController * ponteiro;
static AamoDBAdapter * dbAdapter;
//errors
const int errorCode_10 = 10;
const int errorCode_11 = 11;
const int errorCode_12 = 12;
const int errorCode_20 = 20;  // Erro no open database
const int errorCode_21 = 21;  // Erro na query - retorna nil 
const int errorCode_22 = 22;  // Erro no ExecSQL - comando invalido
const int errorCode_100 = 100;

static int globalErrorCode;
static sqlite3_stmt * statement;

@implementation AAmoViewController

@synthesize execOnLeaveOnBack;
@synthesize globalParameters;
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
    globalParameters = [[NSMutableArray alloc] init];
    self.execOnLeaveOnBack = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:NO];
    
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
    
    args = [[NSMutableArray alloc] init];
    mapaConsultas = [NSMutableDictionary dictionary];
    mapaQuery = [[NSMutableArray alloc] init];
}


- (void)viewWillUnload
{
    
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
            [ponteiro execOnLeave];
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

// Funcoes de banco de dados

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
       
        int position = 3; 
        int ret = paramType (L, position);
        //NSLog(@"RETORNO %d ", ret);
        contador =0;
        
        NSString *querySQL = [[NSString alloc] initWithUTF8String:(const char *) sql];
        NSMutableArray *consultas = (NSMutableArray *) [dbAdapter query:querySQL  paramQuery:ponteiro.args]; 
        
        if (consultas == nil) {
            globalErrorCode = errorCode_21; 
            return 0;
        }
        
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
            //NSLog(@"retorno da query %@",  retorno);
            const char * coluna = [retorno cStringUsingEncoding:[NSString defaultCStringEncoding]];
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
            //NSLog(@"retorno NEXT %@",  retorno);
            //char *coluna = (char *)sqlite3_column_text(statement, j);
            const char * coluna = [retorno cStringUsingEncoding:[NSString defaultCStringEncoding]];
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

        mp = nil;
        chave = nil;

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
    //NSLog(@"top %d", top);
    
    if (lua_gettop (L)>0){
        const char *sql = lua_tostring(L, 1);
        if (sql == nil){
            globalErrorCode = errorCode_12 ; 
            return 0;
        }
        
        int position = 2; 
        int ret = paramType (L, position);
        
        NSString *querySQL = [[NSString alloc] initWithUTF8String:(const char *) sql];
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

int paramType (lua_State *L, int position) 
{
    int top = lua_gettop (L);	        
    
    if (top == 0) return 0;
    
    [ponteiro.args removeAllObjects];
    
    for (int i=position; i <= top; i++) {
        
    	int argType = lua_type(L, i);
        AAmoMapaQuery * mq = [[AAmoMapaQuery alloc] init];
        switch (argType) {
            case LUA_TSTRING: {             
                const char *param = lua_tostring(L, i);
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
                NSNumber *numberKey = [NSNumber numberWithInt:num];
                NSString *ch=@"key"; 
                NSString *chave = [ch stringByAppendingFormat:@"%d ",i];
                
                mq.name = chave;
                mq.object = numberKey;
                mq.type = 2;
                
                break;
            }
         
        }
              
        [ponteiro.args addObject:mq];
    
    }
    
    return 1;
}



// Fim Funcoes de banco de dados

static int showScreen(lua_State *L) {
    if (lua_gettop (L)>0){
	    double d = lua_tonumber(L, 1);
	    if (d == 0){
            globalErrorCode = errorCode_12 ; 
        }
        else {
            [ponteiro execOnLeave];
            ponteiro.execOnLeaveOnBack = NO;
            if (![ponteiro showScreen:d]) {
                [ponteiro loadUi: d];
                if (globalErrorCode == 0){
                    [ponteiro hideViews];
                    [ponteiro formatSubviews];
                    [ponteiro showViews];
                }
            }
            ponteiro.execOnLeaveOnBack = YES;
        }	
	}
	else {
		globalErrorCode = errorCode_10 ; 
	}	    
    return 0;
}

static int getLocalizedText(lua_State *L) {
    
    if (lua_gettop (L)>0){
	    const char *msg = lua_tostring(L, -1);
	    if (msg == nil){
            globalErrorCode = errorCode_12 ; 
        }
        else {
            NSString * key = [NSString stringWithFormat:@"%@%@", L10N_PREFIX, 
            [NSString stringWithCString:msg encoding:[NSString defaultCStringEncoding]]];
            const char * texto = [[ponteiro checkL10N: key] cStringUsingEncoding:[NSString defaultCStringEncoding]];
            lua_pushstring(L, texto);
    		return 1;
        }
    }
	
    return 0;
}

static int setGlobalParameter(lua_State *L) {
    if (lua_gettop (L)>0){
	    const char *name = lua_tostring(L, 1);
	    if (name == nil){
            globalErrorCode = errorCode_12 ; 
            return 0;
    	}
    	int objectType = lua_type(L, -1);
        // LUA_TNUMBER, LUA_TBOOLEAN, LUA_TSTRING
        AAmoGlobalParameter * gp = [[AAmoGlobalParameter alloc] init];
        gp.name = [NSString stringWithCString:name encoding:[NSString defaultCStringEncoding]];
        if ([ponteiro.globalParameters containsObject:gp]) {
            int indice = [ponteiro.globalParameters indexOfObject:gp];
            gp = [ponteiro.globalParameters objectAtIndex:indice];
        }
        else {
            [ponteiro.globalParameters addObject:gp];
            
            NSLog(@"%d", [ponteiro.globalParameters count]);
        }
        switch (objectType) {
            case LUA_TNUMBER: {
                double num = lua_tonumber(L, -1);
                NSNumber * numero = [NSNumber numberWithDouble:num];
                gp.object = numero;
                gp.type = 2;
                [ponteiro.globalParameters addObject:gp];
                return 0;
                break;
            }
            case LUA_TBOOLEAN: {
                int num = lua_toboolean(L, -1);
                NSNumber * numero = [NSNumber numberWithInt:num];
                gp.object = numero;
                gp.type = 3;
                [ponteiro.globalParameters addObject:gp];
                return 0;
                break;
            }
            case LUA_TSTRING: {
                const char *texto = lua_tostring(L, -1);
                NSString * textoString = [NSString stringWithCString:texto encoding:[NSString defaultCStringEncoding]];
                gp.object = textoString;
                gp.type = 1;
                [ponteiro.globalParameters addObject:gp];
                
                NSLog(@"name: %@ obj: %@",gp.name, gp.object);
                
                return 0;
                break;
            }
        }
        return 0;
	}
	else {
		globalErrorCode = errorCode_10 ; 
		return 0;
	}    
}

static int getGlobalParameter(lua_State *L) {
    if (lua_gettop (L)>0){
	    const char *name = lua_tostring(L, -1);
	    if (name == nil){
            globalErrorCode = errorCode_12 ; 
        }
        else {
            NSString * key =  
                              [NSString stringWithCString:name encoding:[NSString defaultCStringEncoding]];
            NSLog(@"%@", key);
            AAmoGlobalParameter * gp = [[AAmoGlobalParameter alloc] init];
            gp.name = [NSString stringWithCString:name encoding:[NSString defaultCStringEncoding]];
            NSLog(@"%d", [ponteiro.globalParameters count]);
            if ([ponteiro.globalParameters containsObject:gp]) {
                int indice = [ponteiro.globalParameters indexOfObject:gp];
                gp = [ponteiro.globalParameters objectAtIndex:indice];
                switch (gp.type) {
                    case 1: {
                        // String
                        NSString * saida =  gp.object;
                        const char * texto = [saida cStringUsingEncoding:[NSString defaultCStringEncoding]];
                        lua_pushstring(L, texto);
                        break;
                    }
                    case 2: {
                        // Number
                        double numero = [((NSNumber *)gp.object) doubleValue];
                        lua_pushnumber(L, numero);
                        break;
                    }
                    case 3: {
                        // BOOL
                        int resultado = [((NSNumber *) gp.object) intValue];
                        lua_pushboolean(L, resultado);
                        break;
                    }
                    default: {
                        lua_pushnil(L);
                        break;
                    }
                }
            }
            else {
                lua_pushnil(L);            
            }
            
    		return 1;
        }
    }
	
    return 0;

}

static int addListBoxOption(lua_State *L) {
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
    		[ponteiro setListBox:d text:textoMsg];
        }	
        return 0;
	}
	else {
		globalErrorCode = errorCode_10 ; 
		return 0;
	}    

}

static int clearListBox(lua_State *L) {
    if (lua_gettop (L)>0){
	    double d = lua_tonumber(L, 1); // id
	    if (d == 0){
            globalErrorCode = errorCode_12 ;
            return 0;
    	}
    	
        [ponteiro clearListBoxControl:d];
        return 0;
	}
	else {
		globalErrorCode = errorCode_10 ;
		return 0;
	}
    
}

static int showMenu(lua_State *L) {
    [ponteiro showScreenMenu];
    return 0;
}

static int navigateTo(lua_State *L) {
    if (lua_gettop (L)>0){
	    double d = lua_tonumber(L, 1); // id
	    if (d == 0){
            globalErrorCode = errorCode_12 ;
            return 0;
    	}
    	
    	const char *url = lua_tostring(L, -1); // text
        if (url == nil){
            globalErrorCode = errorCode_12 ;
		   	return 0;
        }
        else {
		    NSString *textoUrl = [NSString stringWithCString:url encoding:[NSString defaultCStringEncoding]];
    		[ponteiro urlNavigate:d to:textoUrl];
	    	return 0;
        }
	}
	else {
		globalErrorCode = errorCode_10 ;
		return 0;
	}

}

//setPicture
static int setPicture(lua_State *L) {
    if (lua_gettop (L)>0){
	    double d = lua_tonumber(L, 1); // id
	    if (d == 0){
            globalErrorCode = errorCode_12 ;
            return 0;
    	}
    	
    	const char *url = lua_tostring(L, -1); // text
        if (url == nil){
            globalErrorCode = errorCode_12 ;
		   	return 0;
        }
        else {
		    NSString *textoUrl = [NSString stringWithCString:url encoding:[NSString defaultCStringEncoding]];
            
            [ponteiro setPictureNow:d file:textoUrl];
	    	return 0;
        }
	}
	else {
		globalErrorCode = errorCode_10 ;
		return 0;
	}
    
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
    {"showScreen", showScreen},
    {"getLocalizedText",getLocalizedText},
    {"setGlobalParameter", setGlobalParameter},
    {"getGlobalParameter", getGlobalParameter},
    {"addListBoxOption", addListBoxOption},
    {"clearListBox", clearListBox},
    {"showMenu", showMenu},
    {"navigateTo", navigateTo},
    {"setPicture", setPicture},
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



//*****************************************************************************************************

- (void) setPictureNow:(double)ib file:(NSString *)picture
{
    for (AAmoDynaView * dv in dynaViews) {
        if (dv.id == ib && dv.type == IMAGEBOX) {
            UIImage * image = [UIImage imageNamed:picture];
            UIImageView * iv = (UIImageView *) dv.view;
            [iv setImage:image];
            if (dv.stretch == 0) {
                [iv sizeToFit];
            }

            break;
        }
    }
}

- (void) urlNavigate:(double) idc to:(NSString*) wurl
{
    
    for (AAmoDynaView * dv in dynaViews) {
        if (dv.id == idc && dv.type == WEBBOX) {
            UIWebView * wv = (UIWebView *) dv.view;
            NSURL *url = [NSURL URLWithString:[self checkL10N:wurl]];
            NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
            [wv loadRequest:requestObj];
            break;
        }
    }
}

- (void) showScreenMenu
{
    UIActionSheet * sheet;
    if (screenData.menuOptions != nil && [screenData.menuOptions count] > 0) {
        sheet = [[UIActionSheet alloc] initWithTitle:nil
                                            delegate:self
                                   cancelButtonTitle:@"X"
                              destructiveButtonTitle:nil
                                   otherButtonTitles: nil];
        for (NSString * option in screenData.menuOptions) {
            [sheet addButtonWithTitle:[self checkL10N: option]];
        }
        
        // Show the sheet
        [sheet showInView:self.view];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    AAmoGlobalParameter * gp = [[AAmoGlobalParameter alloc] init];
    gp.name = GLOBAL_MENU_INDEX;
    
    if ([ponteiro.globalParameters containsObject:gp]) {;
        gp = [ponteiro.globalParameters objectAtIndex:[ponteiro.globalParameters indexOfObject:gp]];
    }
    else {
        [ponteiro.globalParameters addObject:gp];
    }
    gp.object = [NSNumber numberWithInteger:buttonIndex];
    gp.type = 2;
    
    //NSLog(@"gp.name: %@, object: %d", gp.name, [((NSNumber*) gp.object) intValue]);
    
    gp = [[AAmoGlobalParameter alloc] init];
    gp.name = GLOBAL_MENU_TEXT;
    
    if ([ponteiro.globalParameters containsObject:gp]) {;
        gp = [ponteiro.globalParameters objectAtIndex:[ponteiro.globalParameters indexOfObject:gp]];
    }
    else {
        [ponteiro.globalParameters addObject:gp];
    }
    gp.object = [self checkL10N:[screenData.menuOptions objectAtIndex:buttonIndex]];
    gp.type = 1;
    
    //NSLog(@"gp.name: %@, object: %@", gp.name, (NSString*)gp.object);
    
    if (screenData.onMenuSelected != nil) {
        [self execLua:screenData.onMenuSelected];
    }
    
}

- (void) setListBox:(double)d text:(NSString*)textoMsg
{
    
    for (AAmoDynaView * dv in dynaViews) {
        if (dv.id == d && dv.type == LISTBOX) {
            [dv.listBoxElements addObject:textoMsg];
            UITableView *  tv = (UITableView *)dv.view;
            [tv reloadData];
            break;
        }
    }
}

// UITableViewDelegate e UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger elementos = 0;
    for (AAmoDynaView * dv in dynaViews) {
        if (dv.id == tableView.tag && dv.type == LISTBOX) {
            elementos = [dv.listBoxElements count];
            break;
        }
    }
    return elementos;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView 
cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    
    static NSString *cellIdentifier = @"tvcell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                          reuseIdentifier:cellIdentifier];
    }
    NSString * texto; 
    for (AAmoDynaView * dv in dynaViews) {
        if (dv.id == tableView.tag && dv.type == LISTBOX) {
            texto = [dv.listBoxElements objectAtIndex:indexPath.row];
            
            break;
        }
        
    }
    cell.textLabel.text = texto;
    return cell;
}

- (void)tableView:(UITableView *)tableView 
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    
    AAmoDynaView * dv;
    for (dv in dynaViews) {
        if (dv.id == tableView.tag && dv.type == LISTBOX) {
            if (dv.onElementSelected != nil && [dv.onElementSelected length] > 0) {
                break;
                return;
            }
        }
    }
    
    //NSLog(@"Index: %d, texto: %@", indexPath.row,[dv.listBoxElements objectAtIndex:indexPath.row]);

    
    AAmoGlobalParameter * gp = [[AAmoGlobalParameter alloc] init];
    gp.name = GLOBAL_LISTBOX_INDEX;
    
    if ([ponteiro.globalParameters containsObject:gp]) {;
        gp = [ponteiro.globalParameters objectAtIndex:[ponteiro.globalParameters indexOfObject:gp]];
    }
    else {
        [ponteiro.globalParameters addObject:gp];
    }
    gp.object = [NSNumber numberWithInteger:indexPath.row];
    gp.type = 2;
    
    //NSLog(@"gp.name: %@, object: %d", gp.name, [((NSNumber*) gp.object) intValue]);
    
    gp = [[AAmoGlobalParameter alloc] init];
    gp.name = GLOBAL_LISTBOX_TEXT;

    if ([ponteiro.globalParameters containsObject:gp]) {;
        gp = [ponteiro.globalParameters objectAtIndex:[ponteiro.globalParameters indexOfObject:gp]];
    }
    else {
        [ponteiro.globalParameters addObject:gp];
    }
    gp.object = [dv.listBoxElements objectAtIndex:indexPath.row];
    gp.type = 1;
    
    //NSLog(@"gp.name: %@, object: %@", gp.name, (NSString*)gp.object);
    
    [self execLua:dv.onElementSelected];
}

- (void) clearListBoxControl: (double) idl
{
    AAmoDynaView * dv;
    for (dv in dynaViews) {
        if (dv.id == idl && dv.type == LISTBOX) {
            [dv.listBoxElements removeAllObjects];
            UITableView *tv = (UITableView *) dv.view;
            [tv reloadData];
        }
    }
}

- (void) loadBundle
{
    if (res == nil) {
        res = [[AAmoResourceBundle alloc] init];
    }
}

- (BOOL) showScreen: (double) screenNumber
{
    BOOL existe = false;
    for (AAmoScreenData *sd in screenDataStack) {
        if (sd.uiid == screenNumber) {
            existe = YES;
            break;
        }
    }
    if (existe) {
        AAmoScreenData *sd = nil;
        do {
            sd = screenData;
            if (sd.uiid == screenNumber) {
                break;
            }
            [self exitScreenProc];
        } while (sd.uiid != screenNumber);
    }
    // Always Check if the screen has an "onBackScript"
    
    if (screenData.onBackScript != nil && [screenData.onBackScript length] > 0) {
        [self execLua: screenData.onBackScript];
    }
    return existe;
}

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
        
        // Check if the screen has an "onBackScript"
        
        if (self.execOnLeaveOnBack && 
            screenData.onBackScript != nil && [screenData.onBackScript length] > 0) {
            [self execLua: screenData.onBackScript];
        }
        
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
    return nil;
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

- (void) execOnLeave
{
    if (self.execOnLeaveOnBack &&  
        screenData.onLeaveScript != nil && [screenData.onLeaveScript length] > 0) {
        [self execLua: screenData.onLeaveScript];
    }    
}

- (void) hideViews
{
    // Check if the screen has an "onBackScript"
    

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
    [mView setBackgroundColor:screenData.bgColor];
    for(id el in dynaViews) {
        dv = el;
        float height = (dv.percentHeight / 100) * screenSize.height;
        float width = (dv.percentWidth / 100) * screenSize.width;
        float top = (dv.percentTop / 100) * screenSize.height;
        float left = (dv.percentLeft / 100) * screenSize.width;
        switch (dv.type) {
            case TEXTBOX: {
                // Textbox
                UITextField * tv = [[UITextField alloc] 
                                    initWithFrame:CGRectMake(left, top, width, height)];
                tv.borderStyle = UITextBorderStyleRoundedRect;
                dv.view = tv;
                tv.tag = dv.id; 
                if (dv.text != nil) {
                    tv.text = [self checkL10N: dv.text];
                    
                }
                [mView addSubview:tv];
                break;
            }
            case LABEL: {
                // Label
                UILabel * lv = [[UILabel alloc]
                                initWithFrame:CGRectMake(left, top, width, height)];
                dv.view = lv;
                lv.tag = dv.id;
                [mView addSubview:lv];
                if (dv.text != nil) {
                    lv.text = [self checkL10N: dv.text];                    
                }
                break;
            }
            case BUTTON: {
                // Button
                UIButton *bv = [UIButton buttonWithType:UIButtonTypeRoundedRect];
                bv.frame = CGRectMake(left, top, width, height);
                dv.view = bv;
                bv.tag = dv.id;
                [mView addSubview:bv];
                [bv addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchDown];
                if (dv.text != nil) {
                    [bv setTitle:[self checkL10N: dv.text] 
                        forState:(UIControlState)UIControlStateNormal];
                }
                break;
            }
            case CHECKBOX: {
                // Checkbox
                UISwitch * sv = [[UISwitch alloc] initWithFrame:CGRectMake(left, top, width, height)];
                dv.view = sv;
                sv.tag = dv.id;
                [sv addTarget:self action:@selector(checkBoxChanged:) forControlEvents:UIControlEventValueChanged];
                [mView addSubview:sv];
                [sv setOn:dv.checked];
                break;
            }
            case LISTBOX: {
                UITableView * tv = [[UITableView alloc] initWithFrame:CGRectMake(left, top, width, height)];
                dv.view = tv;
                tv.tag = dv.id;
                [tv setDelegate:self];
                [tv setDataSource:self];
                [mView addSubview:tv];
                break;
            }
            case WEBBOX: {
                UIWebView *wv = [[UIWebView alloc] initWithFrame:CGRectMake(left, top, width, height)];
                dv.view = wv;
                wv.tag = dv.id;
                [mView addSubview:wv];
                if (dv.url != nil && [dv.url length] > 0) {
                    NSURL *url = [NSURL URLWithString:dv.url];
                    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
                    [wv loadRequest:requestObj];
                }
                break;
            }
            case IMAGEBOX: {
                UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(left, top, width, height)];
                dv.view = iv;
                iv.tag = dv.id;
                [mView addSubview:iv];
                if (dv.picture != nil && [dv.picture length] > 0) {
                    UIImage * imagem = [UIImage imageNamed:dv.picture];
                    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(left, top, width, height)];
                    [btn setBackgroundColor:[UIColor clearColor]];
                    btn.tag = dv.id;
                    [btn addTarget:self action:@selector(imageClick:) forControlEvents:UIControlEventTouchDown];
                    [mView addSubview:btn];
                    [iv setImage:imagem];
                    if (dv.stretch == 0) {
                        [iv sizeToFit];
                    }
                }
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
    else if ([elementName isEqualToString:@"menu"]) {
        currentMacro = MACRO_MENU;
        screenData.menuOptions = [[NSMutableArray alloc] init];
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
    if ([elementName isEqualToString:@"menu"]) {
        // temos que voltar ao macro_ui
        currentMacro = MACRO_UI;
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
        else if ([currentElementName isEqualToString: @"onLeaveScript"]) {
            screenData.onLeaveScript = [currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
        else if ([currentElementName isEqualToString: @"onBackScript"]) {
            screenData.onBackScript = [currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
        else if ([currentElementName isEqualToString:@"backgroundColor"]) {
            screenData.bgColor = [self checkColor: [currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
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
        else if ([currentElementName isEqualToString: @"onElementSelected"]) {
            currentElement.onElementSelected = [currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
        else if ([currentElementName isEqualToString:@"url"]) {
            currentElement.url = [self checkL10N:[currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
        }
        else if ([currentElementName isEqualToString:@"picture"]) {
            currentElement.picture = [self checkL10N:[currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
        }
        else if ([currentElementName isEqualToString:@"stretch"]) {
            currentElement.stretch = [self getStretch:[currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
        }
        
    }
    else if (currentMacro == MACRO_MENU) {
        if ([currentElementName isEqualToString:@"option"]) {
            [screenData.menuOptions addObject:[currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
        }
        else if ([currentElementName isEqualToString:@"onMenuSelected"]) {
            screenData.onMenuSelected = [currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
    }
    
    currentStringValue = nil;
}

- (int) getStretch: (NSString *) stretch
{
    int resultado = 0;
    if (stretch != nil && [stretch length] == 1) {
        if ([stretch isEqualToString:@"1"]) {
            resultado = 1;
        }
    }
    return resultado;
}

- (UIColor *) checkColor: (NSString *) htmlCode
{
    // #FFCCDD
    // 0123456
    UIColor * color = [UIColor whiteColor];
    if (htmlCode != nil &&
        [htmlCode length] == 7 &&
        [htmlCode characterAtIndex:0] == '#') {
        
        unsigned int cRed = 0;
        NSScanner *scanner = [NSScanner scannerWithString:
                              [htmlCode substringWithRange:NSMakeRange(1, 2)]
                              ];
        if ([scanner scanHexInt:&cRed] == YES) {
            unsigned int cGreen = 0;
            scanner = [NSScanner scannerWithString:
                       [htmlCode substringWithRange:NSMakeRange(3, 2)]
                       ];
            if ([scanner scanHexInt:&cGreen]) {
                unsigned int cBlue = 0;
                scanner = [NSScanner scannerWithString:
                           [htmlCode substringWithRange:NSMakeRange(5, 2)]
                           ];
                if ([scanner scanHexInt:&cBlue]) {
                    color = [UIColor colorWithRed:(cRed / 255.0)
                                            green:(cGreen / 255.0)
                                             blue:(cBlue / 255.0)
                                            alpha:(1.0)];
                }
            }
        }
    }
    return color;
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

-(void) imageClick:(id)sender
{
    AAmoDynaView *dv = nil;
    for(id el in dynaViews) {
        dv = el;
        if (dv.type == IMAGEBOX) {
            if (dv.id == ((UIView *)sender).tag) {
                [self execLua: dv.onClickScript];
                return;
            }
        }
    }
    
    
}

- (NSString *) checkL10N: (NSString *) key
{
    NSString * result = key;
    
    if ([key length] > [L10N_PREFIX length]) {
        
        if ([[key substringToIndex:([L10N_PREFIX length])] isEqualToString:L10N_PREFIX]) {
            NSString *newKey = [key substringFromIndex:([L10N_PREFIX length])];
            
            if (res == nil) {
                [self loadBundle];
                
            }
            if (res == nil) {
                globalErrorCode = errorCode_100;
            }
            else {
                result = [res getString:newKey]; 
            } 
        }
    }
    
    return result;
}

@end