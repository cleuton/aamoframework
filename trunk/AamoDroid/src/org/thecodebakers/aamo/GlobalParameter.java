package org.thecodebakers.aamo;

import org.keplerproject.luajava.LuaObject;

public class GlobalParameter {
	private String name;
	private LuaObject object;
	private Object javaObject;
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
	
	public Object getJavaObject() {
		return javaObject;
	}
	public void setJavaObject(Object javaObject) {
		this.javaObject = javaObject;
	}
	@Override
	public boolean equals(Object o) {
		GlobalParameter gp = (GlobalParameter) o;
		return this.getName().equals(gp.getName());
	}
	@Override
	public int hashCode() {
		return this.getName().hashCode();
	}
	@Override
	public String toString() {
		return "[" + this.getName() + "]";
	}
	
}
