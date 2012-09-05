package org.thecodebakers.aamo.sqlite.model;

import java.util.List;

public class Table {
	
	private String name;
	private List<Column> columnsList;
	
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
	public List<Column> getColumnsList() {
		return columnsList;
	}
	public void setColumnsList(List<Column> columnsList) {
		this.columnsList = columnsList;
	}
	
}