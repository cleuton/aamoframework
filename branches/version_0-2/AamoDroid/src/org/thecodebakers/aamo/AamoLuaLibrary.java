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
	
	//**** Fun�›es a serem invocadas pelo c—digo Lua
	public static int m_getTextField(LuaState L) throws LuaException {
	  L.newTable();
	  L.pushValue(-1);
	  L.setGlobal("aamo");
	  L.pushString("getTextField");
	  L.pushJavaFunction(new JavaFunction(L) {
	    public int execute() throws LuaException {  
	      if (L.getTop() > 1) {
	    	  LuaObject d = getParam(2);
	    	  L.pushString(getTextBox(d));
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
				texto = ((EditText) dv.view).getText().toString();
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
	    	  showMessageBox(msg);
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
	    	  loadScreen(tela);
	      }
	      return 0;
	    }
	  });
	  L.setTable(-3);
	  return 1;
	}
	
	protected static void loadScreen(LuaObject tela) {
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
			    	  L.pushString(getLabel(d));
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
			    	  setLabel(d,e);
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
			    	  setTextBox(d,e);
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
				texto = ((TextView) dv.view).getText().toString();
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
			  		double nd = d.getNumber();
			  		int retorno = 0;
					for (DynaView dv : selfRef.dynaViews) {
						if (dv.id == nd) {
							if (((CheckBox) dv.view).isChecked()) {
								retorno = 1;
		  					}
						}
					}
					L.pushNumber(retorno);
					return 1;

			    }
			    return 0;
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
			    	  double nd = d.getNumber();
			    	  for (DynaView dv : selfRef.dynaViews) {
							if (dv.id == nd) {	
								((CheckBox) dv.view).setChecked(
										(e.getNumber() > 0) ? true : false
										);
							}
			    	  }
			    }
			    return 0;
		    }
		  });
		  L.setTable(-3);
		  return 1;
	}
	
}