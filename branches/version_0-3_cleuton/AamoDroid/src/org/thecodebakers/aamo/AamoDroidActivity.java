package org.thecodebakers.aamo;

import java.io.ByteArrayOutputStream;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintStream;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.MissingResourceException;
import java.util.PropertyResourceBundle;
import java.util.ResourceBundle;
import java.util.Stack;

import org.keplerproject.luajava.LuaState;
import org.keplerproject.luajava.LuaStateFactory;
import org.xmlpull.v1.XmlPullParser;
import org.xmlpull.v1.XmlPullParserException;
import org.xmlpull.v1.XmlPullParserFactory;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.res.AssetManager;
import android.os.Bundle;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.Window;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.CompoundButton;
import android.widget.CompoundButton.OnCheckedChangeListener;
import android.widget.EditText;
import android.widget.RelativeLayout;
import android.widget.RelativeLayout.LayoutParams;
import android.widget.TextView;
import android.widget.ViewFlipper;

public class AamoDroidActivity extends Activity implements OnClickListener {
	
	public static final double VERSION = 0.3;
	public static final int MACRO_UI = 1;
	public static final int  MACRO_ELEMENT = 2;
	public static final String AAMOL10N = "aamol10n";
	public static final String AAMOL10N_MARKER = "l10n::";
	protected List<DynaView> dynaViews;
	
	protected ScreenData screenData;

    String currentStringValue;
    String currentElementName;
    int currentMacro;
    DynaView currentElement;
    protected RelativeLayout dvLayout;
    protected ViewFlipper baseLayout;
    protected static AamoDroidActivity selfRef;
    
    // Screen and controls stacks
    
    protected Stack<ScreenData> screenStack;
    protected Stack<List<DynaView>> controlsStack;
    
    // Lua
    
    protected LuaState L;
    
    // L10N
    
    public ResourceBundle res;
	
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        selfRef =this;
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,WindowManager.LayoutParams.FLAG_FULLSCREEN);
        setContentView(R.layout.main);
        
        screenStack = new Stack<ScreenData>();
        controlsStack = new Stack<List<DynaView>>();
             
        baseLayout = (ViewFlipper) this.findViewById(R.id.vflipper);
        
        // Setup library
        
        AamoLuaLibrary.selfRef = this;
		
		// Load xml for the base ui
        
        try {
			loadUI(1);
		} catch (AamoException e) {
			e.printStackTrace();
		}
        
        // Format it's subviews
        
        formatSubviews();
        
    }
    
	protected void formatSubviews() {
		
		RelativeLayout.LayoutParams rlParams = new RelativeLayout.LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT);
        dvLayout = new RelativeLayout(this.getApplicationContext());
        dvLayout.setLayoutParams(rlParams);
        
		DisplayMetrics metrics = new DisplayMetrics();
		getWindowManager().getDefaultDisplay().getMetrics(metrics);
		int screenHeight = metrics.heightPixels;
		int screenWidth = metrics.widthPixels;
	    for(DynaView dv : dynaViews) {
	    	
	        int height = (int) Math.round((dv.percentHeight / 100.00f) * (float)screenHeight);
	        int width =  (int) Math.round((dv.percentWidth / 100.00f) * (float)screenWidth);
	        int top = (int) Math.round((dv.percentTop / 100.00f) * (float)screenHeight);
	        int left = (int) Math.round((dv.percentLeft / 100.00f) * (float)screenWidth);
	        
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
	                if (dv.text != null) {
	                	tv.setText(checkL10N(dv.text));
	                }
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
	                    lv.setText(checkL10N(dv.text));
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
	                bv.setText(checkL10N(dv.text));

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
	                if (dv.onChangeScript != null && dv.onChangeScript.length() > 0) {
	                	final String codigo = dv.onChangeScript;
	                	sv.setOnCheckedChangeListener(new OnCheckedChangeListener() {
	              
							public void onCheckedChanged(CompoundButton arg0,
									boolean arg1) {
								
								execLua(codigo);
							}
	                		
	                		
	                	});
	                }
	                break;
	            }
	                
	        }
	        
	    }
	    
	    baseLayout.addView(dvLayout);
        baseLayout.setDisplayedChild(baseLayout.getChildCount() - 1);
	    screenData.dvLayout = dvLayout;
	    screenStack.push(screenData);
	    
	    // Check "onLoadScreen" event:
	    
	    if (screenData.onLoadScript != null && screenData.onLoadScript.length() > 0) {
			execLua(screenData.onLoadScript);
	    }

	}

	protected boolean loadUI(int screenId) throws AamoException {
		
		/***************************************************************
		 * Falta testar se já existe uma tela com esse id na pilha....
		 ***************************************************************/
		
		InputStream istr;
		boolean resultado = true;
		try {
			dynaViews = new ArrayList<DynaView>();
			screenData = new ScreenData();
			if (screenId == 1) {
				istr = this.getApplicationContext().getAssets().open("app/ui.xml");
			}
			else {
				istr = this.getApplicationContext().getAssets().open("app/ui_" + screenId + ".xml");
			}
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
	        	        screenData.uiid = 1;
	        	        screenData.title = "AAMO v." +VERSION;
	        	        screenData.onLoadScript = null;
	        	        screenData.onEndScript = null;
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
	        	                        String mensagem = "WRONG XML VERSION. MUST BE 0.2";
	        	                        showAlertMessage(mensagem);
	        	                    }
	        	                }
	        	            }
	        	            else if (currentElementName.equals("uiid")) {
	        	            	screenData.uiid = Integer.parseInt(currentStringValue.trim());
	        	            }
	        	            else if (currentElementName.equals("title")) {
	        	            	screenData.title = currentStringValue.trim();
	        	            }
	        	            else if (currentElementName.equals("onLoadScript")) {
	        	            	screenData.onLoadScript = currentStringValue.trim();
	        	            }
	        	            else if (currentElementName.equals("onEndScript")) {
	        	            	screenData.onEndScript = currentStringValue.trim();
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
			
	        // Coloca o dynaViews na pilha
	        controlsStack.push(dynaViews);
			
		} catch (IOException e) {
			Log.d("XML", "IOException");
			resultado = false;
			throw new AamoException (e);
		} catch (XmlPullParserException e) {
			Log.d("XML", e.getMessage());
			resultado = false;
			throw new AamoException (e);
		}

		return resultado;
	}
    
	protected void showAlertMessage(String msg) {
		new AlertDialog.Builder(this).setMessage(msg)
        .setNeutralButton("OK", new DialogInterface.OnClickListener() {
            public void onClick(DialogInterface dialog, int which) {
				
            } }).show();  
	}


	public void onClick(View arg0) {
		
		
		String name = "";
		for (DynaView dv : dynaViews) {
			if (arg0.getTag().equals(new Integer(dv.id))) {
				name = dv.onClickScript;
				execLua(name);
				break;
			}
		}

	}
	
	protected void execLua (String script) {
		AssetManager am = getAssets();
		try {
			if (L == null) {
				L = LuaStateFactory.newLuaState();
				L.openLibs();
				L.setTop(0);
			}
			
			String codigo = this.getResources().getString(R.string.loadlibs);
			
			if (script.indexOf("lua::") < 0) {
				InputStream is = am.open("app/" + script + ".lua");
				byte[] bytes = readAll(is);
				codigo += (new String(bytes));
			}
			else {
				codigo += script.substring(5);  // after "lua::"
				
			}
			
			
			L.LloadString(codigo);
			int ok = L.pcall(0, 0, 0);
			if (ok == 0) {
				return;
			}
			else {
				String msg = L.toString(-1);
				Log.d("AAMO::Lua",msg);
			}

			
		} catch (Exception e) {
			ByteArrayOutputStream os = new ByteArrayOutputStream();
			e.printStackTrace(new PrintStream(os));
			L.pushString("Cannot load module "+script+":\n"+os.toString());
			
		}
	}
	
	public ResourceBundle getBundle() {
		ResourceBundle res = null;
		String userLanguage = Locale.getDefault().getLanguage();
		String userCountry  = (Locale.getDefault().getCountry() == null) ? "" : "_" + Locale.getDefault().getCountry();
		AssetManager am = getAssets();
		String preferredName = AAMOL10N + "_" + userLanguage + userCountry + ".properties";
		int index = 0;
		String names[] = {
			preferredName,
			AAMOL10N + "_" + userLanguage + ".properties",
			AAMOL10N + ".properties"
		};
		boolean loading = true;
		do {
			try {
				InputStream is = am.open("app/" + names[index]);
				res = new PropertyResourceBundle(is);
				loading = false;
			} catch (Exception e) {
				index++;
				if (index > 2) {
					AamoLuaLibrary.errorCode = 100;
					loading = false;
				}
			}
			
		} while (loading);
		return res;
	}

	
	// This solution, to read scripts from the Assets folder, came from Michal Kottman's project "Androlua" (https://github.com/mkottman/AndroLua)
	protected static byte[] readAll(InputStream input) throws Exception {
		ByteArrayOutputStream output = new ByteArrayOutputStream(4096);
		byte[] buffer = new byte[4096];
		int n = 0;
		while (-1 != (n = input.read(buffer))) {
			output.write(buffer, 0, n);
		}
		return output.toByteArray();
	}

	public String checkL10N(String texto) {
		String saida = texto;
		int pos = -1;
		if ((pos = texto.indexOf(AAMOL10N_MARKER)) >= 0) {
			saida = getL10N(texto.substring(pos + AAMOL10N_MARKER.length()));
		}
		return saida;
	}

	public String getL10N(String substring) {
		String result = null;
		if (res == null) {
			res = getBundle();
		}
		try {
			result = res.getString(substring);	
		}
		catch (MissingResourceException mre) {
			result = "??????";
		}
		
		return res.getString(substring);
	}
}