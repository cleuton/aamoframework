package org.thecodebakers.aamo;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.keplerproject.luajava.JavaFunction;
import org.keplerproject.luajava.LuaException;
import org.keplerproject.luajava.LuaObject;
import org.keplerproject.luajava.LuaState;
import org.thecodebakers.aamo.sqlite.DBAdapter;

import android.database.Cursor;
import android.util.Log;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.TextView;

public class AamoLuaLibrary {
	
	public static AamoDroidActivity selfRef;
	protected static int errorCode = 0;
	private static Cursor cursorMaster;
	private static Map<String, Cursor> cursorMap = new HashMap<String, Cursor>();
	
	//errors LUA 
	protected enum Errors {
	    LUA_10(10), 	// parametro faltando 
	    LUA_11(11), 	// Arquivo não encontrado
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
	/*
	private static final int SQLITE_TYPE_BLOB = 4; 
	private static final int SQLITE_TYPE_FLOAT = 2;	
	private static final int SQLITE_TYPE_INTEGER = 1;
	private static final int SQLITE_TYPE_NULL = 0;	
	private static final int SQLITE_TYPE_STRING = 3;
	*/
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
				if (dv.type == 1) { // é um textbox
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
	      		  AamoLuaLibrary.errorCode = 11; // arquivo não encontrado
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
					// é um label
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
	
	public static int m_query(LuaState L) throws LuaException {
		
		  
		  L.newTable();
		  L.pushValue(-1);
		  L.getGlobal("aamo");
		  L.pushString("query");
		  L.pushJavaFunction(new JavaFunction(L) {
		    public int execute() throws LuaException {  
		      if (L.getTop() > 1) {
		    	  
		    	  LuaObject d = getParam(2); // titulo da query
		    	  LuaObject sql = getParam(3); // sql
		    	  if (d == null) {
		    		  AamoLuaLibrary.errorCode = Errors.LUA_12.getErrorCode(); 
		    		  return 0;
		    	  }
		    	  else {
		    		  DBAdapter adapter = new DBAdapter(selfRef.getApplicationContext());
		    		  //List <String> args = new ArrayList <String>();
		    		  List <String> args = getQueryParams(L, 4);
		    		  
		    		  Cursor cursor = adapter.query(sql.getString(), args); 
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
	public static int m_close(LuaState L) throws LuaException
	{
		    
		  L.newTable();
		  L.pushValue(-1);
		  L.getGlobal("aamo");
		  L.pushString("close");
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
						    		L.pushBoolean(true);
					    	    }else {
					    	    	L.pushBoolean(false);
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
		    		  
		    		  //call update comand
		    		  adapter.execSQL(d.getString(), args); 
		    		  String  registro = "Command executed successfully.";
		    		  
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
	
	
}