package org.thecodebakers.aamo;

import android.view.View;

public class DynaView {
	public int id;
	public int type;
    /*
     1 - Textbox
     2 - Label
     3 - Button
     4 - Checkbox
     */
	public float percentTop;
	public float percentLeft;
	public float percentHeight;
	public float percentWidth;
	public boolean  checked;
	public String text;
	public String onCompleteScript;
	public String onChangeScript;
	public String onClickScript;
	public View view;

}
