package org.thecodebakers.aamo;

import org.keplerproject.luajava.JavaFunction;
import org.keplerproject.luajava.LuaException;
import org.keplerproject.luajava.LuaObject;
import org.keplerproject.luajava.LuaState;

import android.widget.EditText;

public class AamoLuaLibrary {
	
	public static AamoDroidActivity selfRef;
	
	//**** Fun�›es a serem invocadas pelo c—digo Lua
	public static int modulo1(LuaState L) throws LuaException {
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
	
	public static int modulo2(LuaState L) throws LuaException {
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
	
	public static int modulo3(LuaState L) throws LuaException {
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
			selfRef.finish();
		}
	}
	
	public static int modulo4(LuaState L) throws LuaException {
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
	
	public static int modulo5(LuaState L) throws LuaException {
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
}
