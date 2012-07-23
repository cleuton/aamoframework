package org.thecodebakers.aamo;

import org.keplerproject.luajava.LuaObject;

public class GlobalParameter {
	private String name;
	private LuaObject object;
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
	public LuaObject getObject() {
		return object;
	}
	public void setObject(LuaObject object) {
		this.object = object;
	}
	
}
