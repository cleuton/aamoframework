package org.thecodebakers.aamo;

import java.util.List;

import android.widget.RelativeLayout;

public class ScreenData {
	public int uiid;
    public String title;
    public String onLoadScript;
    public String onEndScript; 
    public String onLeaveScript;
    public String onBackScript;
    public RelativeLayout dvLayout;
    public List<String> menuOptions;
    public String onMenuSelected;
}
