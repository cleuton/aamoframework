package org.thecodebakers.aamo;

import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintStream;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import org.keplerproject.luajava.JavaFunction;
import org.keplerproject.luajava.LuaException;
import org.keplerproject.luajava.LuaObject;
import org.keplerproject.luajava.LuaState;
import org.keplerproject.luajava.LuaStateFactory;
import org.xmlpull.v1.XmlPullParser;
import org.xmlpull.v1.XmlPullParserException;
import org.xmlpull.v1.XmlPullParserFactory;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.res.AssetFileDescriptor;
import android.content.res.AssetManager;

import android.os.Bundle;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.RelativeLayout;
import android.widget.TextView;

public class AamoDroidActivity extends Activity implements OnClickListener {
	
	public static final double VERSION = 0.1;
	public static final int MACRO_UI = 1;
	public static final int  MACRO_ELEMENT = 2;
	private List<DynaView> dynaViews;
    int uiid;
    String title;
    String onLoadScript;
    String onEndScript;
    String currentStringValue;
    String currentElementName;
    int currentMacro;
    DynaView currentElement;
    private RelativeLayout dvLayout;
    private static AamoDroidActivity selfRef;
	
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        selfRef =this;
        setContentView(R.layout.main);
        
        dynaViews = new ArrayList<DynaView>();
        dvLayout = (RelativeLayout) this.findViewById(R.id.dvlayout);
        loadUI();
        formatSubviews();
        
    }

	private void formatSubviews() {
		DisplayMetrics metrics = new DisplayMetrics();
		getWindowManager().getDefaultDisplay().getMetrics(metrics);
		int screenHeight = metrics.heightPixels;
		int screenWidth = metrics.widthPixels;
	    for(DynaView dv : dynaViews) {
	    	
	        float height = (dv.percentHeight / 100) * screenHeight;
	        float width = (dv.percentWidth / 100) * screenWidth;
	        float top = (dv.percentTop / 100) * screenHeight;
	        float left = (dv.percentLeft / 100) * screenWidth;
	        
	        switch (dv.type) {
	            case 1: 
	                // Textbox
	            	EditText tv = new EditText(getApplicationContext());
	            	RelativeLayout.LayoutParams params = new RelativeLayout.LayoutParams((int)width, (int)height);
	            	params.leftMargin = (int) left;
	            	params.topMargin = (int) top;
	            	dvLayout.addView(tv, params);
	                dv.view = tv;
	                tv.setTag(new Integer(dv.id)); 
	                break;
	            
	            case 2: {
	                // Label
	            	TextView lv = new TextView(getApplicationContext());
	            	RelativeLayout.LayoutParams params2 = new RelativeLayout.LayoutParams((int)width, (int)height);
	            	params2.leftMargin = (int) left;
	            	params2.topMargin = (int) top;
	            	dvLayout.addView(lv, params2);
	                dv.view = lv;
	                lv.setTag(dv.id);
	                if (dv.text != null) {
	                    lv.setText(dv.text);
	                }
	                break;
	            }
	            case 3: {
	                // Button
	            	Button bv = new Button(getApplicationContext());
	            	RelativeLayout.LayoutParams params3 = new RelativeLayout.LayoutParams((int)width, (int)height);
	            	params3.leftMargin = (int) left;
	            	params3.topMargin = (int) top;
	            	dvLayout.addView(bv, params3);
	                dv.view = bv;
	                bv.setTag(dv.id);
	                bv.setOnClickListener( this);
	                bv.setText(dv.text);

	                break;
	            }
	            case 4: {
	                // Checkbox
	            	CheckBox sv = new CheckBox(getApplicationContext());
	            	RelativeLayout.LayoutParams params4 = new RelativeLayout.LayoutParams((int)width, (int)height);
	            	params4.leftMargin = (int) left;
	            	params4.topMargin = (int) top;
	            	dvLayout.addView(sv, params4);
	                dv.view = sv;
	                sv.setTag(dv.id);
	                sv.setChecked(dv.checked);

	                break;
	            }
	                
	        }
	        
	    }

	}

	private boolean loadUI() {
		InputStream istr;
		boolean resultado = true;
		try {
			istr = this.getApplicationContext().getAssets().open("app/ui.xml");
			XmlPullParserFactory factory = XmlPullParserFactory.newInstance(); 
			factory.setNamespaceAware(true); 
			XmlPullParser xpp = factory.newPullParser(); 
			xpp.setInput(istr, "UTF-8");
			
			int eventType = xpp.getEventType();
	        while (eventType != XmlPullParser.END_DOCUMENT) {
	        	if(eventType == XmlPullParser.START_DOCUMENT) {

	        	} 
	        	else if(eventType == XmlPullParser.START_TAG) {
	        	    currentElementName = xpp.getName();
	        	    if (currentElementName.equals("element")) {
	        	        currentElement = new DynaView();
	        	        dynaViews.add(currentElement);
	        	        currentElement.id = 0;
	        	        currentElement.type = 0;
	        	        currentElement.percentTop = 0;
	        	        currentElement.percentLeft = 0;
	        	        currentElement.percentHeight = 0;
	        	        currentElement.percentWidth = 0;
	        	        currentElement.checked = false;
	        	        currentElement.text = null;
	        	        currentElement.onCompleteScript = null;
	        	        currentElement.onChangeScript = null;
	        	        currentElement.onClickScript = null;
	        	        currentMacro = MACRO_ELEMENT;
	        	    }
	        	    else if (currentElementName.equals("ui")){
	        	        uiid = 1;
	        	        title = "AAMO v." +VERSION;
	        	        onLoadScript = null;
	        	        onEndScript = null;
	        	        currentMacro = MACRO_UI;
	        	    }

	        	} 
	        	else if(eventType == XmlPullParser.END_TAG) {
	        	    if (xpp.getName().equals("ui") ||
	        	    		xpp.getName().equals("element")) {
	        	    		eventType = xpp.next();
	        	    		continue;
	        	        }
	        	        if (currentMacro == MACRO_UI) {
	        	            if (currentElementName.equals("ui")) {
	        	                if (currentElementName.equals("version")) {
	        	                    // version
	        	                    double version = Double.parseDouble(currentStringValue);
	        	                    if (version > VERSION) {
	        	                        String mensagem = "WRONG XML VERSION. MUST BE 1.0";
	        	                        showAlertMessage(mensagem);
	        	                    }
	        	                }
	        	            }
	        	            else if (currentElementName.equals("uiid")) {
	        	                uiid = Integer.parseInt(currentStringValue.trim());
	        	            }
	        	            else if (currentElementName.equals("title")) {
	        	                title = currentStringValue.trim();
	        	            }
	        	            else if (currentElementName.equals("onLoadScript")) {
	        	                onLoadScript = currentStringValue.trim();
	        	            }
	        	            else if (currentElementName.equals("onEndScript")) {
	        	                onEndScript = currentStringValue.trim();
	        	            }
	        	        }
	        	        else if (currentMacro == MACRO_ELEMENT) {
	        	            
	        	            if (currentElementName.equals("id")) {
	        	                currentElement.id = Integer.parseInt(currentStringValue.trim());
	        	            }
	        	            else if (currentElementName.equals("type")) {
	        	                currentElement.type = Integer.parseInt(currentStringValue.trim());
	        	            }
	        	            else if (currentElementName.equals("percentTop")) {
	        	                currentElement.percentTop = Float.parseFloat(currentStringValue.trim());
	        	                
	        	            }
	        	            else if (currentElementName.equals("percentLeft")) {
	        	                currentElement.percentLeft = Float.parseFloat(currentStringValue.trim());
	        	            }
	        	            else if (currentElementName.equals("percentHeight")) {
	        	                currentElement.percentHeight = Float.parseFloat(currentStringValue.trim());
	        	            }
	        	            else if (currentElementName.equals("percentWidth")) {
	        	                currentElement.percentWidth = Float.parseFloat(currentStringValue.trim());
	        	            }
	        	            else if (currentElementName.equals("checked")) {
	        	                currentElement.checked = Integer.parseInt(currentStringValue.trim()) == 1;
	        	            }
	        	            else if (currentElementName.equals("text")) {
	        	                currentElement.text = currentStringValue.trim();
	        	               
	        	            }
	        	            else if (currentElementName.equals("onCompleteScript")) {
	        	                currentElement.onCompleteScript = currentStringValue.trim();
	        	            }
	        	            else if (currentElementName.equals("onClickScript")) {
	        	                currentElement.onClickScript =   currentStringValue.trim();
	        	            }
	        	            else if (currentElementName.equals("onChangeScript")) {
	        	                currentElement.onChangeScript = currentStringValue.trim();
	        	            }

	        	        }

	        	        currentStringValue = null;
	        	} 
	        	else if(eventType == XmlPullParser.TEXT) {
	        		currentStringValue = xpp.getText().trim();
	        	}
	          eventType = xpp.next();
	         }
			
			
		} catch (IOException e) {
			Log.d("XML", "IOException");
			resultado = false;
		} catch (XmlPullParserException e) {
			Log.d("XML", e.getMessage());
			resultado = false;
		}

		return resultado;
	}
    
	private void showAlertMessage(String msg) {
		new AlertDialog.Builder(this).setMessage(msg)
        .setNeutralButton("OK", new DialogInterface.OnClickListener() {
            public void onClick(DialogInterface dialog, int which) {
				
            } }).show();  
	}


	public void onClick(View arg0) {
		
		LuaState L = LuaStateFactory.newLuaState();
		L.openLibs();
		L.setTop(0);
		String name = "";
		for (DynaView dv : dynaViews) {
			if (arg0.getTag().equals(new Integer(dv.id))) {
				name = dv.onClickScript;
				break;
			}
		}
		
		AssetManager am = getAssets();
		try {
			String path = name + ".jet";

			InputStream is = am.open("app/" + name + ".lua");
			byte[] bytes = readAll(is);
			String codigo = "luajava.loadLib(\"org.thecodebakers.aamo.AamoDroidActivity\", \"modulo1\")\r\n"
					+ "luajava.loadLib(\"org.thecodebakers.aamo.AamoDroidActivity\", \"modulo2\")\r\n"
					+ (new String(bytes));
			L.LloadString(codigo);
			int ok = L.pcall(0, 0, 0);
			if (ok == 0) {
				return;
			}
			
		} catch (Exception e) {
			ByteArrayOutputStream os = new ByteArrayOutputStream();
			e.printStackTrace(new PrintStream(os));
			L.pushString("Cannot load module "+name+":\n"+os.toString());
			
		}
		

		
	}
	
	//**** Fun›es a serem invocadas pelo c—digo Lua
	public static int modulo1(LuaState L) throws LuaException
	{
	  L.newTable();
	  L.pushValue(-1);
	  L.setGlobal("aamo");

	  L.pushString("getTextField");

	  L.pushJavaFunction(new JavaFunction(L) {

	    public int execute() throws LuaException
	    {  
	      if (L.getTop() > 1)
	      {
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
	
	public static int modulo2(LuaState L) throws LuaException
	{
	  L.newTable();
	  L.pushValue(-1);
	  L.getGlobal("aamo");

	  L.pushString("showMessage");

	  L.pushJavaFunction(new JavaFunction(L) {

	    public int execute() throws LuaException
	    {  
	      if (L.getTop() > 1)
	      {
	    	  LuaObject msg = getParam(2);
	    	  showMessageBox(msg);
	      }

	      return 0;
	    }
	  });
	  
	  L.setTable(-3);

	  return 1;
	}
	
	
	protected static void showMessageBox(LuaObject msg) {
		selfRef.showAlertMessage(msg.toString());
		
	}

	private static byte[] readAll(InputStream input) throws Exception {
		ByteArrayOutputStream output = new ByteArrayOutputStream(4096);
		byte[] buffer = new byte[4096];
		int n = 0;
		while (-1 != (n = input.read(buffer))) {
			output.write(buffer, 0, n);
		}
		return output.toByteArray();
	}

}