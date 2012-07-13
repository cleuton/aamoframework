package org.thecodebakers.aamo.sqlite;

import java.util.List;

public class Database {
	
	private String name;
	private int version;
	private List<Table> tablesList;
	
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
	public int getVersion() {
		return version;
	}
	public void setVersion(int version) {
		this.version = version;
	}
	public List<Table> getTablesList() {
		return tablesList;
	}
	public void setTablesList(List<Table> tablesList) {
		this.tablesList = tablesList;
	}
	
		
	
}
