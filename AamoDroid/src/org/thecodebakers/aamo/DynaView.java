package org.thecodebakers.aamo;

import android.view.View;

public class DynaView {
	public static int NOT_INITIALIZED = -1; 
	public int screenId = NOT_INITIALIZED;
	public int id = NOT_INITIALIZED;
	public int type = NOT_INITIALIZED;
    /*
     1 - Textbox
     2 - Label
     3 - Button
     4 - Checkbox
     */
	public float percentTop = NOT_INITIALIZED;
	public float percentLeft = NOT_INITIALIZED;
	public float percentHeight = NOT_INITIALIZED;
	public float percentWidth = NOT_INITIALIZED;
	public boolean  checked;
	public String text;
	public String onCompleteScript;
	public String onChangeScript;
	public String onClickScript;
	public View view;
}
