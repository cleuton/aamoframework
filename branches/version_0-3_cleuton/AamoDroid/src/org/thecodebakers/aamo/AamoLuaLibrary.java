package org.thecodebakers.aamo;

import org.keplerproject.luajava.JavaFunction;
import org.keplerproject.luajava.LuaException;
import org.keplerproject.luajava.LuaObject;
import org.keplerproject.luajava.LuaState;

import android.util.Log;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.TextView;

public class AamoLuaLibrary {
	
	public static AamoDroidActivity selfRef;
	protected static int errorCode = 0;
	
	//errors LUA 
	protected enum Errors {
	    LUA_10(10), 	// parametro faltando 
	    LUA_11(11), 	// Arquivo nÃ£o encontrado
	    LUA_12(12), 	// Valor igual a nulo
	    LUA_13(13),
	    LUA_14(14), 
	    LUA_15(15); 
	    
	    int errorCode;
	    
	    Errors (int error){
	    	errorCode = error;
	    }
	    
	    int getErrorCode(){
	    	return errorCode;
	    }
	}
	
	//**** Funcoes a serem invocadas pelo codigo Lua
	public static int m_getTextField(LuaState L) throws LuaException {
	  L.newTable();
	  L.pushValue(-1);
	  L.setGlobal("aamo");
	  L.pushString("getTextField");
	  L.pushJavaFunction(new JavaFunction(L) {
	    public int execute() throws LuaException {  
	      if (L.getTop() > 1) {
	    	  LuaObject d = getParam(2);
	    	  if (d == null){
	    		  AamoLuaLibrary.errorCode = Errors.LUA_12.getErrorCode(); 
	    		  return 0;
	    	  }
	    	  else
	    	  {	  
	    		  //L.pushString(getTextBox(d));
	    		  String txt = getTextBox(d);
	    		  if (txt == null){
		    		  AamoLuaLibrary.errorCode = Errors.LUA_12.getErrorCode();
		    		  return 0;
		    	  }else{
		    		  L.pushString(txt);  
		    	  }
	    	  }	  
	      }
	      else 
	      {
	    	  AamoLuaLibrary.errorCode = Errors.LUA_10.getErrorCode();
	      }
	      
	      return 1;
	    }
	  });
	  L.setTable(-3);
	  return 1;
	}

	private static String getTextBox(LuaObject d) {
		double nd = d.getNumber();
		String texto = null;
		for (DynaView dv : selfRef.dynaViews) {
			if (dv.id == nd) {
				if (dv.type == 1) { // Ã© um textbox
					texto = ((EditText) dv.view).getText().toString();
					break;
				}
				else {
					break;
				}
				
			}
		}
		return texto;
	}
	
	public static int m_showMessage(LuaState L) throws LuaException {
	  L.newTable();
	  L.pushValue(-1);
	  L.getGlobal("aamo");
	  L.pushString("showMessage");
	  L.pushJavaFunction(new JavaFunction(L) {
	    public int execute() throws LuaException {  
	      if (L.getTop() > 1) {
	    	  LuaObject msg = getParam(2);
	    	  if (msg == null){
	    		  AamoLuaLibrary.errorCode = Errors.LUA_12.getErrorCode();
	    		  return 0;
	    	  }else {
	    		  showMessageBox(msg);  
	    	  }
	      }
	      else 
	      {
	    	  AamoLuaLibrary.errorCode = Errors.LUA_10.getErrorCode();
	      }
	      return 0;
	    }
	  }); 
	  L.setTable(-3);
	  return 1;
	}
	
	public static int m_loadScreen(LuaState L) throws LuaException {
	  L.newTable();
	  L.pushValue(-1);
	  L.getGlobal("aamo");
	  L.pushString("loadScreen");
	  L.pushJavaFunction(new JavaFunction(L) {
	    public int execute() throws LuaException {  
	      if (L.getTop() > 1) {
	    	  LuaObject tela = getParam(2);
	    	  try{
	    	  	  loadScreen(tela);
	    	   }catch(AamoException ae){
	      		  AamoLuaLibrary.errorCode = 11; // arquivo nÃ£o encontrado
	      	   } 	   
	    	  
	      }else {
	    	  AamoLuaLibrary.errorCode = Errors.LUA_10.getErrorCode();
	      }
	      return 0;
	    }
	  });
	  L.setTable(-3);
	  return 1;
	}
	
	protected static void loadScreen(LuaObject tela)throws AamoException {
		int ntela = (int) tela.getNumber();
		selfRef.loadUI(ntela);
		selfRef.formatSubviews();
	}
	
	protected static void showMessageBox(LuaObject msg) {
		selfRef.showAlertMessage(msg.toString());
		
	}
	
	protected static void exitScreen() {
		if (selfRef.screenStack.size() > 1) {
			// tem algo na pilha, vamos voltar
			
			// Check for "onEndScript"
			
			if (selfRef.screenData.onEndScript != null && selfRef.screenData.onEndScript.length() > 0) {
				selfRef.execLua(selfRef.screenData.onEndScript);
			}
			
			selfRef.screenData = selfRef.screenStack.pop(); // remove the current screen
			selfRef.screenData = selfRef.screenStack.peek(); // get the previous screen without removing it
			selfRef.baseLayout.showPrevious();
			selfRef.baseLayout.removeView(selfRef.dvLayout);
			selfRef.dvLayout = selfRef.screenData.dvLayout;
			selfRef.dynaViews = selfRef.controlsStack.pop();  // remove current controls
			selfRef.dynaViews = selfRef.controlsStack.peek(); // get the previous controls without removing them
		}
		else {
			// It is the last screen
			if (selfRef.screenData.onEndScript != null && selfRef.screenData.onEndScript.length() > 0) {
				selfRef.execLua(selfRef.screenData.onEndScript);
			}
			selfRef.finish();
		}
	}
	
	public static int m_exitScreen(LuaState L) throws LuaException {
	  L.newTable();
	  L.pushValue(-1);
	  L.getGlobal("aamo");
	  L.pushString("exitScreen");
	  L.pushJavaFunction(new JavaFunction(L) {
	    public int execute() throws LuaException {  
	      exitScreen();
	      return 0;
	    }
	  });
	  L.setTable(-3);
	  return 1;
	}
	
	public static int m_getCurrentScreenId(LuaState L) throws LuaException {
		  L.newTable();
		  L.pushValue(-1);
		  L.getGlobal("aamo");
		  L.pushString("getCurrentScreenId");
		  L.pushJavaFunction(new JavaFunction(L) {
		    public int execute() throws LuaException {  
			    L.pushNumber(selfRef.screenData.uiid);
			    return 1;
		    }
		  });
		  L.setTable(-3);
		  return 1;
	}
	
	public static int m_log(LuaState L) throws LuaException {
		  L.newTable();
		  L.pushValue(-1);
		  L.getGlobal("aamo");
		  L.pushString("log");
		  L.pushJavaFunction(new JavaFunction(L) {
		    public int execute() throws LuaException {  
		    	if (L.getTop() > 1) {
			    	  LuaObject msg = getParam(2);
			    	  Log.d("AAMO",msg.getString());
			    }
		    	else 
			    {
			        AamoLuaLibrary.errorCode = Errors.LUA_10.getErrorCode();
			    }
			    return 0;
		    }
		  });
		  L.setTable(-3);
		  return 1;
	}
	
	public static int m_getLabelText(LuaState L) throws LuaException {
		  L.newTable();
		  L.pushValue(-1);
		  L.getGlobal("aamo");
		  L.pushString("getLabelText");
		  L.pushJavaFunction(new JavaFunction(L) {
		    public int execute() throws LuaException {  
		    	if (L.getTop() > 1) {
			    	  LuaObject d = getParam(2);
			    	  if (d == null){
			    		  AamoLuaLibrary.errorCode = Errors.LUA_12.getErrorCode(); 
			    		  return 0;
			    	  }
			    	  else {
			    		  String txt = getLabel(d);
			    		  if (txt == null){
				    		  AamoLuaLibrary.errorCode = Errors.LUA_12.getErrorCode();
				    	  }else{
				    		  L.pushString(txt);//getLabel(d)  
				    	  }
			    	  }
			    }
		    	else 
			    {
			        AamoLuaLibrary.errorCode = Errors.LUA_10.getErrorCode();
			    }
			    return 1;
		    }
		  });
		  L.setTable(-3);
		  return 1;
	}
	
	public static int m_setLabelText(LuaState L) throws LuaException {
		  L.newTable();
		  L.pushValue(-1);
		  L.getGlobal("aamo");
		  L.pushString("setLabelText");
		  L.pushJavaFunction(new JavaFunction(L) {
		    public int execute() throws LuaException {  
		    	if (L.getTop() > 1) {
			       LuaObject d = getParam(2);
			       LuaObject e = getParam(3);
			       if (d == null){
			    	   AamoLuaLibrary.errorCode = Errors.LUA_12.getErrorCode();
			    	   return 0;
			       }
			       else if (e == null) {
			    	   AamoLuaLibrary.errorCode = Errors.LUA_12.getErrorCode();
			    	   return 0;
			       }
			       else {
			      	   setLabel(d,e);
			       }
			      
			    }else {
		    	   AamoLuaLibrary.errorCode = Errors.LUA_10.getErrorCode();
			    }
			    return 0;
		    }
		  });
		  L.setTable(-3);
		  return 1;
	}
	
	public static int m_setTextField(LuaState L) throws LuaException {
		  L.newTable();
		  L.pushValue(-1);
		  L.getGlobal("aamo");
		  L.pushString("setTextField");
		  L.pushJavaFunction(new JavaFunction(L) {
		    public int execute() throws LuaException {  
		    	if (L.getTop() > 1) {
			    	LuaObject d = getParam(2);
			    	LuaObject e = getParam(3);
			    	if (d == null){
				       AamoLuaLibrary.errorCode = Errors.LUA_12.getErrorCode();
				       return 0;
				    }
				    else if (e == null) {
				       AamoLuaLibrary.errorCode = Errors.LUA_12.getErrorCode();
				       return 0;
				    }
				    else {
				       setTextBox(d,e);
				    }
			    }
		    	else 
		    	{
		    		AamoLuaLibrary.errorCode = Errors.LUA_10.getErrorCode();
			    }
			    return 0;
		    }
		  });
		  L.setTable(-3);
		  return 1;
	}
	
	private static String getLabel(LuaObject d) {
		double nd = d.getNumber();
		String texto = null;
		for (DynaView dv : selfRef.dynaViews) {
			if (dv.id == nd) {
				if (dv.type == 2) {
					// Ã© um label
					texto = ((TextView) dv.view).getText().toString();
					break;
				}
				else {
					break;
				}
			}
		}
		return texto;
	}
	
	private static void setLabel(LuaObject d, LuaObject e) {
		double nd = d.getNumber();
		for (DynaView dv : selfRef.dynaViews) {
			if (dv.id == nd) {
				((TextView) dv.view).setText(e.getString());
			}
		}
	}
	private static void setTextBox(LuaObject d, LuaObject e) {
		double nd = d.getNumber();
		for (DynaView dv : selfRef.dynaViews) {
			if (dv.id == nd) {
				((EditText) dv.view).setText(e.getString());
			}
		}
	}
	
	public static int m_getCheckBox(LuaState L) throws LuaException {
		  L.newTable();
		  L.pushValue(-1);
		  L.getGlobal("aamo");
		  L.pushString("getCheckBox");
		  L.pushJavaFunction(new JavaFunction(L) {
		    public int execute() throws LuaException {  
		    	if (L.getTop() > 1) {
		    		LuaObject d = getParam(2);
		    		if (d == null){
					   AamoLuaLibrary.errorCode = Errors.LUA_12.getErrorCode(); 
					   return 0;
					}
		    		else {
		    			
			    		double nd = d.getNumber();
				  		int retorno = 0;
						for (DynaView dv : selfRef.dynaViews) {
							if (dv.id == nd) {
								if (dv.type == 4) {
									if (((CheckBox) dv.view).isChecked()) {
										retorno = 1;
				  					}	
									break;
								}
							}
						}
					
						if (retorno == 0){
				    	    AamoLuaLibrary.errorCode = Errors.LUA_12.getErrorCode(); 
				    	    return 0;
				    	}
				    	else {
				    		L.pushNumber(retorno);
				    	}
						return 1;
		    		}
			    }
		    	else 
		    	{
			    	AamoLuaLibrary.errorCode = Errors.LUA_10.getErrorCode();
			    	return 0;
				}
			    
		    }
		  });
		  L.setTable(-3);
		  return 1;
	}

	public static int m_setCheckBox(LuaState L) throws LuaException {
		  L.newTable();
		  L.pushValue(-1);
		  L.getGlobal("aamo");
		  L.pushString("setCheckBox");
		  L.pushJavaFunction(new JavaFunction(L) {
		    public int execute() throws LuaException {  
		    	if (L.getTop() > 1) {
			    	  LuaObject d = getParam(2);
			    	  LuaObject e = getParam(3);
			    	  
			    	  if (d == null || e == null){
					       AamoLuaLibrary.errorCode = Errors.LUA_12.getErrorCode();
					       return 0;
					  }
					  else {
			    	  
						  double nd = d.getNumber();
						  for (DynaView dv : selfRef.dynaViews) {
							  if (dv.id == nd) {	
								((CheckBox) dv.view).setChecked(
										(e.getNumber() > 0) ? true : false);
							  }
						  }	   
			    	  }
			    }
		    	else 
		    	{
		    	   AamoLuaLibrary.errorCode = Errors.LUA_10.getErrorCode();
			    }
			    return 0;
		    }
		  });
		  L.setTable(-3);
		  return 1;
	}
	
	public static int m_getError(LuaState L) throws LuaException {
		  L.newTable();
		  L.pushValue(-1);
		  L.getGlobal("aamo");
		  L.pushString("getError");
		  L.pushJavaFunction(new JavaFunction(L) {
		    public int execute() throws LuaException {  
			    L.pushNumber(AamoLuaLibrary.errorCode);
			    return 1;
		    }
		  });
		  L.setTable(-3);
		  return 1;
	}
	
	public static int m_showScreen(LuaState L) throws LuaException {
		  L.newTable();
		  L.pushValue(-1);
		  L.getGlobal("aamo");
		  L.pushString("showScreen");
		  L.pushJavaFunction(new JavaFunction(L) {
		    public int execute() throws LuaException {  
		      if (L.getTop() > 1) {
		    	  LuaObject tela = getParam(2);
		    	  try{
		    		  // Verificar se a tela já existe na pilha
		    		  int pos = -1;
		    		  for (ScreenData sd : selfRef.screenStack) {
		    			  if (sd.uiid == tela.getNumber()) {
		    				  pos = selfRef.screenStack.indexOf(sd);
		    				  break;
		    			  }
		    		  }
		    		  if (pos < 0) {
		    			  // A tela não existe na pilha
		    			  loadScreen(tela);
		    		  }
		    		  else {
		    			  ScreenData sd = null;
		    			  do {
		    				sd = selfRef.screenData;
		    				if (sd.uiid == tela.getNumber()) {
		    					break;
		    				}
		    				AamoLuaLibrary.exitScreen();
		    			  } while (sd.uiid != tela.getNumber());
		    		  }
		    	   }catch(AamoException ae){
		      		  AamoLuaLibrary.errorCode = 11; // arquivo nÃ£o encontrado
		      	   } 	   
		    	  
		      }else {
		    	  AamoLuaLibrary.errorCode = Errors.LUA_10.getErrorCode();
		      }
		      return 0;
		    }
		  });
		  L.setTable(-3);

		return 1;
	}
	
}
