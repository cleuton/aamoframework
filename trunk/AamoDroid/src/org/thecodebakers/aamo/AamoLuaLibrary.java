package org.thecodebakers.aamo;

import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.keplerproject.luajava.JavaFunction;
import org.keplerproject.luajava.LuaException;
import org.keplerproject.luajava.LuaObject;
import org.keplerproject.luajava.LuaState;
import org.thecodebakers.aamo.DynaView.CONTROL_TYPE;
import org.thecodebakers.aamo.sqlite.DBAdapter;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.database.Cursor;
import android.util.Log;
import android.webkit.WebView;
import android.widget.ArrayAdapter;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.ListAdapter;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.ImageView.ScaleType;

public class AamoLuaLibrary {
	
	public static AamoDroidActivity selfRef;
	public static int errorCode = 0;
	private static Cursor cursorMaster;
	private static Map<String, Cursor> cursorMap = new HashMap<String, Cursor>();
	
	//errors LUA 
	protected enum Errors {
	    LUA_10(10), 	// parametro faltando 
	    LUA_11(11), 	// Arquivo nÃ£o encontrado
	    LUA_12(12), 	// Valor igual a nulo
	    LUA_13(13),
	    LUA_14(14), 
	    LUA_15(15),
	    LUA_20(20),		// erro no open database
	    LUA_21(21),     // erro na query - retorna nil 
	    LUA_22(22),     // erro no ExecSQL - comando invalido
	    LUA_100(100); 
	    
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
				if (dv.type == CONTROL_TYPE.TEXTBOX) { // Ã© um textbox
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
		selfRef.execOnLeave();
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
			// Check if the screen has an "onBackScript"
	        
	        if (selfRef.execOnLeaveOnBack  && 
	        		selfRef.screenData.onBackScript != null && selfRef.screenData.onBackScript.length() > 0) {
	            selfRef.execLua(selfRef.screenData.onBackScript);
	        }
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
				if (dv.type == CONTROL_TYPE.LABEL) {
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
								if (dv.type == CONTROL_TYPE.CHECKBOX) {
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
		    		  selfRef.execOnLeave();
		    		  selfRef.execOnLeaveOnBack = false;
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
		    			  if (sd.onBackScript != null && sd.onBackScript.length() > 0) {
		    				  selfRef.execLua(sd.onBackScript);
		    			  }
		    		  }
		    	   }catch(AamoException ae){
		      		  AamoLuaLibrary.errorCode = 11; // arquivo nÃ£o encontrado
		      	   } finally {	   
		      		 selfRef.execOnLeaveOnBack = true;
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
	
	public static int m_getLocalizedText(LuaState L) throws LuaException {
		  L.newTable();
		  L.pushValue(-1);
		  L.getGlobal("aamo");
		  L.pushString("getLocalizedText");
		  L.pushJavaFunction(new JavaFunction(L) {
		    public int execute() throws LuaException {  
		      if (L.getTop() > 1) {
		    	  LuaObject d = getParam(2);
		    	  if (d == null) {
		    		  AamoLuaLibrary.errorCode = Errors.LUA_12.getErrorCode(); 
		    		  return 0;
		    	  }
		    	  else {	  
		    		  String txt = selfRef.checkL10N("l10n::" + d.getString());
		    		  if (txt == null) {
			    		  AamoLuaLibrary.errorCode = Errors.LUA_100.getErrorCode();
			    		  return 0;
			    	  }
		    		  else {
			    		  L.pushString(txt);  
			    	  }
		    	  }	  
		      }
		      else {
		    	  AamoLuaLibrary.errorCode = Errors.LUA_10.getErrorCode();
		    	  return 0;
		      }
		      
		      return 1;
		    }
		  });
		  L.setTable(-3);
		  return 1;
	}
	
	public static int m_setGlobalParameter(LuaState L) throws LuaException {
		  L.newTable();
		  L.pushValue(-1);
		  L.getGlobal("aamo");
		  L.pushString("setGlobalParameter");
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
			    	  
						  String nomeParametro = d.getString();
						  GlobalParameter gp = new GlobalParameter();
						  gp.setName(nomeParametro);
						  if (selfRef.globalParameters.contains(gp)) {
							  gp = selfRef.globalParameters.get(selfRef.globalParameters.indexOf(gp));
						  }
						  else {
							  
							  selfRef.globalParameters.add(gp);
						  }
						  gp.setObject(e);
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
	
	public static int m_getGlobalParameter(LuaState L) throws LuaException {
		  L.newTable();
		  L.pushValue(-1);
		  L.getGlobal("aamo");
		  L.pushString("getGlobalParameter");
		  L.pushJavaFunction(new JavaFunction(L) {
		    public int execute() throws LuaException {  
		    	if (L.getTop() > 1) {
			    	  LuaObject d = getParam(2);
			    	  
			    	  if (d == null){
					       AamoLuaLibrary.errorCode = Errors.LUA_12.getErrorCode();
					       return 0;
					  }
					  else {
			    	  
						  String nomeParametro = d.getString();
						  GlobalParameter gp = new GlobalParameter();
						  gp.setName(nomeParametro);
						  if (selfRef.globalParameters.contains(gp)) {
							  gp = selfRef.globalParameters.get(selfRef.globalParameters.indexOf(gp));
							  if (gp.getObject() == null) {
								  // É um objeto java
								  if (gp.getJavaObject() instanceof java.lang.Integer) {
									  int numero = ((Integer) gp.getJavaObject()).intValue();
									  L.pushNumber(numero);
								  }
								  else {
									  String texto = (String) gp.getJavaObject();
									  L.pushString(texto);
								  }
							  }
							  else {
								  L.pushObjectValue(gp.getObject());
							  }
							  
						  }
						  else {
							  L.pushNil();
						  }
						  return 1;
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
	
	public static int m_addListBoxOption(LuaState L) throws LuaException {
		  L.newTable();
		  L.pushValue(-1);
		  L.getGlobal("aamo");
		  L.pushString("addListBoxOption");
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
				       setListBox(d,e);
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

	protected static void setListBox(LuaObject d, LuaObject e) {
		double nd = d.getNumber();
		for (DynaView dv : selfRef.dynaViews) {
			if (dv.id == nd && dv.type == CONTROL_TYPE.LISTBOX) {
				
				dv.listElements.add(e.getString());
			}
		}
	}
	
	public static int m_clearListBox(LuaState L) throws LuaException {
		  L.newTable();
		  L.pushValue(-1);
		  L.getGlobal("aamo");
		  L.pushString("clearListBox");
		  L.pushJavaFunction(new JavaFunction(L) {
		    public int execute() throws LuaException {  
		    	if (L.getTop() > 1) {
			    	LuaObject d = getParam(2);
			    	if (d == null){
				       AamoLuaLibrary.errorCode = Errors.LUA_12.getErrorCode();
				       return 0;
				    }

				    else {
				    	for (DynaView dv : selfRef.dynaViews) {
							if (dv.id == d.getNumber() && dv.type == CONTROL_TYPE.LISTBOX) {
								dv.listElements.clear();
								ListView lv = (ListView) dv.view;
								ArrayAdapter<String> adapter = (ArrayAdapter<String>) lv.getAdapter();
								adapter.notifyDataSetChanged();
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
	
	//m_showMenu

	public static int m_showMenu(LuaState L) throws LuaException {
		  L.newTable();
		  L.pushValue(-1);
		  L.getGlobal("aamo");
		  L.pushString("showMenu");
		  L.pushJavaFunction(new JavaFunction(L) {
		    public int execute() throws LuaException {  
		      selfRef.openOptionsMenu();
		      return 0;
		    }
		  });
		  L.setTable(-3);
		  return 1;
	}
	
	//m_navigateTo
	public static int m_navigateTo(LuaState L) throws LuaException {
		  L.newTable();
		  L.pushValue(-1);
		  L.getGlobal("aamo");
		  L.pushString("navigateTo");
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
				    	   for (DynaView dv : selfRef.dynaViews) {
								if (dv.id == d.getNumber() && dv.type == CONTROL_TYPE.WEBBOX) {									
									WebView wv = (WebView) dv.view;
									wv.loadUrl(selfRef.checkL10N(e.getString()));
								}
							}
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
	
	public static int m_setPicture(LuaState L) throws LuaException {
		  L.newTable();
		  L.pushValue(-1);
		  L.getGlobal("aamo");
		  L.pushString("setPicture");
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
				       setPicture(d,e);
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

	protected static void setPicture(LuaObject d, LuaObject e) {
		int controle = (int) d.getNumber();
		for (DynaView dv : selfRef.dynaViews) {			
			if (dv.view.getTag().equals(new Integer(controle))) {
				ImageView iv = (ImageView) dv.view;
                if (dv.picture != null && dv.picture.length() > 0) {
                	try {
						InputStream istr = selfRef.getApplicationContext().getAssets().open("app/" + e.getString());
						Bitmap bmImg = BitmapFactory.decodeStream(istr);
	                	iv.setImageBitmap(bmImg);
					} catch (IOException ex) {
						Log.d("AAMO::Lua","Exception loading IMAGEBOX: " + ex.getLocalizedMessage());
					}
                	
                }
                if (!dv.stretch) {
                	iv.setAdjustViewBounds(true);
                }
                else {
                	iv.setScaleType(ScaleType.FIT_XY);
	                iv.setAdjustViewBounds(false);
                }
				break;
			}
		}
		
	}

public static int m_query(LuaState L) throws LuaException {
		
		  
		  L.newTable();
		  L.pushValue(-1);
		  L.getGlobal("aamo");
		  L.pushString("query");
		  L.pushJavaFunction(new JavaFunction(L) {
		    public int execute() throws LuaException {  
		      if (L.getTop() > 1) {
		    	  
		    	  LuaObject d = getParam(2);   // titulo da query
		    	  LuaObject sql = getParam(3); // sql
		    	  if (d == null) {
		    		  AamoLuaLibrary.errorCode = Errors.LUA_12.getErrorCode(); 
		    		  return 0;
		    	  }
		    	  else {
		    		  DBAdapter adapter = new DBAdapter(selfRef.getApplicationContext());
		    		  
		    		  List <String> args = getQueryParams(L, 4);
		    		  
		    		  Cursor cursor = adapter.query(sql.getString(), args); 
		    		  if (cursor == null){
		    			  AamoLuaLibrary.errorCode = Errors.LUA_21.getErrorCode();
				    	  return 0; 
		    		  }
		    		  
		    		  cursor.moveToFirst();
		    		  cursorMaster = cursor;
		    		  cursorMap.put(d.getString(), cursor);  
		    		  
		    		  if(!cursor.isAfterLast()){  
		    			    L.newTable();
		    			    for(int j=0; j<cursor.getColumnCount(); j++) {
			    	        	L.pushNumber(j);
		    	                L.pushString(cursor.getString(j));
			    			    L.setTable(-3);
		    	            }
			    	   }  
			    	   
		    		   return 1;
		    	  }	  
		    	  
		      }
		      else {
		    	  AamoLuaLibrary.errorCode = Errors.LUA_10.getErrorCode();
		    	  return 0;
		      }
		      

		    }
		  });
		  L.setTable(-3);
		  return 1;
	}
	
	/**
	 * Retorna uma table Lua com os campos do próximo registro.
	 * @param L
	 * @return
	 * @throws LuaException
	 */
	
	public static int m_next(LuaState L) throws LuaException
	{
		     
		    L.newTable();
			L.pushValue(-1);
			L.getGlobal("aamo");
			L.pushString("next");
			L.pushJavaFunction(new JavaFunction(L) {
			   public int execute() throws LuaException {
				   if (L.getTop() > 1) {
				    	  
				    	  LuaObject d = getParam(2); // titulo da query
				    	  if (d == null) {
				    		  AamoLuaLibrary.errorCode = Errors.LUA_12.getErrorCode(); 
				    		  return 0;
				    	  }
				    	  else {
				    		   cursorMaster = cursorMap.get(d.getString());  
						       if(cursorMaster.moveToNext()){  
						    		L.newTable();
						    		for(int j=0; j < cursorMaster.getColumnCount(); j++) 
								    {
								        L.pushNumber(j);
								        L.pushString(cursorMaster.getString(j));
								        L.setTable(-3);
								    }   
							   }
						       cursorMaster = null;
				    	  } 	
				          return 1;
				   }
				   else {
				    	  AamoLuaLibrary.errorCode = Errors.LUA_10.getErrorCode();
				    	  return 0;
				  }  
			    }
		   });
			
		   L.setTable(-3);
		   return 1;
	}
	
	/**
	 * Fecha o cursor correspondente ao nome.
	 * @param L
	 * @return
	 * @throws LuaException
	 */
	public static int m_closeCursor(LuaState L) throws LuaException
	{
		    
		  L.newTable();
		  L.pushValue(-1);
		  L.getGlobal("aamo");
		  L.pushString("closeCursor");
		  L.pushJavaFunction(new JavaFunction(L) {
			  public int execute() throws LuaException {
				   if (L.getTop() > 1) {
				    	  
				    	  LuaObject d = getParam(2); // titulo da query
				    	  if (d == null) {
				    		  AamoLuaLibrary.errorCode = Errors.LUA_12.getErrorCode(); 
				    		  return 0;
				    	  }
				    	  else {
				    		   cursorMaster = cursorMap.get(d.getString());  
						       if (cursorMaster != null && 
						    		!cursorMaster.isClosed()) {
						    		
							    	cursorMaster.close();
					    	    }
							    cursorMaster = null;
							    cursorMap.remove(d.getString());
				    	  } 	
				          return 1;
				   }
				   else {
				    	  AamoLuaLibrary.errorCode = Errors.LUA_10.getErrorCode();
				    	  return 0;
				  }  
			    }
		   });
 		   L.setTable(-3);
		   return 1;
	}
	
	/**
	 * Retorna um boolean indicando se o último comando (query ou next) 
	 * com aquele nome, retornou EOF.
	 * @param L
	 * @return int
	 * @throws LuaException
	 */
	public static int m_eof(LuaState L) throws LuaException
	{
		    
		  L.newTable();
		  L.pushValue(-1);
		  L.getGlobal("aamo");
		  L.pushString("eof");
		  L.pushJavaFunction(new JavaFunction(L) {
			  public int execute() throws LuaException {
				   if (L.getTop() > 1) {
				    	  
				    	  LuaObject d = getParam(2); // titulo da query
				    	  if (d == null) {
				    		  AamoLuaLibrary.errorCode = Errors.LUA_12.getErrorCode(); 
				    		  return 0;
				    	  }
				    	  else {
				    		   cursorMaster = cursorMap.get(d.getString());  
				    		   if(!cursorMaster.isAfterLast()){
						    		L.pushBoolean(false);
					    	    }else {
					    	    	L.pushBoolean(true);
					    	    }
				    	  } 	
				          return 1;
				   }
				   else {
				   	  AamoLuaLibrary.errorCode = Errors.LUA_10.getErrorCode();
				   	  return 0;
				  }  
			   }
		  });
		  L.setTable(-3);
		  return 1;
	 }
	
	
	public static int m_execSQL(LuaState L) throws LuaException {
				  
		  L.newTable();
		  L.pushValue(-1);
		  L.getGlobal("aamo");
		  L.pushString("execSQL");
		  L.pushJavaFunction(new JavaFunction(L) {
		    public int execute() throws LuaException {  
		      if (L.getTop() > 1) {
		    	  LuaObject d     = getParam(2); // sql
		    	  
		    	  if (d == null) {
		    		  AamoLuaLibrary.errorCode = Errors.LUA_12.getErrorCode(); 
		    		  return 0;
		    	  }
		    	  else {
		    		  DBAdapter adapter = new DBAdapter(selfRef.getApplicationContext());
		    		  List <String> args = getQueryParams(L, 3); //capture the parameters 
		    		  
		    		  String  registro = null;
		    		  try {
		    			  adapter.execSQL(d.getString(), args); 
		    			  registro = "Command executed successfully.";
		    		  }catch (Exception e){
		    			  AamoLuaLibrary.errorCode = Errors.LUA_22.getErrorCode();
				    	  return 0;
		    		  }
		    		  
		    		  L.pushString(registro);
		    		  
		    		  return 1;
		    	  }	  
		      }
		      else {
		    	  AamoLuaLibrary.errorCode = Errors.LUA_10.getErrorCode();
		    	  return 0;
		      }
		    }
		  });
		  L.setTable(-3);
		  return 1;
	}
	
	/**
	 * Create and/or open a database that will be used for reading/writing
	 * @param L
	 * @return int
	 * @throws LuaException
	 */
	public static int m_openDatabase(LuaState L) throws LuaException
	{
		    
		  L.newTable();
		  L.pushValue(-1);
		  L.getGlobal("aamo");
		  L.pushString("openDatabase");
		  L.pushJavaFunction(new JavaFunction(L) {
			  public int execute() throws LuaException {
				   if (L.getTop() > 1) {
				    	  
				    	  LuaObject d = getParam(2); // database name
				    	  if (d == null) {
				    		  AamoLuaLibrary.errorCode = Errors.LUA_12.getErrorCode(); 
				    		  return 0;
				    	  }
				    	  else {
				    		  DBAdapter adapter = new DBAdapter(selfRef.getApplicationContext());
					    	  try {
					    		  adapter.openDatabase(d.getString());
					    	  }catch (Exception e){
					    		  AamoLuaLibrary.errorCode = Errors.LUA_20.getErrorCode();
							   	  return 0;
					    	  }
				    	  } 	
				          return 1;
				   }
				   else {
				   	  AamoLuaLibrary.errorCode = Errors.LUA_10.getErrorCode();
				   	  return 0;
				  }  
			   }
		  });
		  L.setTable(-3);
		  return 1;
	 }
	
	private static List<String> getQueryParams(LuaState L, int position) throws LuaException 
	{
		  List <String> args = new ArrayList<String>();
		  
		  for (int i=position; i <= L.getTop(); i++) {
			  LuaObject param  = L.getLuaObject(i);
			  
	  		  if (param.isNumber()) 
	  		  {	  
	  			  String pk = Double.toString(param.getNumber());
		    		  int idConverted = 0;
	  			  if (pk == null || pk.equals("0.0")){
		    			  args.add(null);
		    		  }
		    		  else {
		    			  idConverted = (int) param.getNumber();
		    			  args.add(Integer.toString(idConverted));
		    		  }
	  		  }else {
	  			  args.add(param.getString());
	  		  }
		  }
		  
		  return args;
	}
	
	/**
	 * clode database 
	 * @param L
	 * @return int
	 * @throws LuaException
	 */
	public static int m_closeDatabase(LuaState L) throws LuaException
	{
		    
		  L.newTable();
		  L.pushValue(-1);
		  L.getGlobal("aamo");
		  L.pushString("closeDatabase");
		  L.pushJavaFunction(new JavaFunction(L) {
			  public int execute() throws LuaException {
				   if (L.getTop() > 1) {
				    	  
				    	  LuaObject d = getParam(2); // database name
				    	  if (d == null) {
				    		  AamoLuaLibrary.errorCode = Errors.LUA_12.getErrorCode(); 
				    		  return 0;
				    	  }
				    	  else {
				    		  DBAdapter adapter = new DBAdapter(selfRef.getApplicationContext());
					    	  adapter.closeDatabase(d.getString()); 
				    	  } 	
				          return 1;
				   }
				   else {
				   	  AamoLuaLibrary.errorCode = Errors.LUA_10.getErrorCode();
				   	  return 0;
				  }  
			   }
		  });
		  L.setTable(-3);
		  return 1;
	 }
}
	

