package org.thecodebakers.aamo.sqlite;

import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

import org.thecodebakers.aamo.AamoException;
import org.thecodebakers.aamo.sqlite.model.Column;
import org.thecodebakers.aamo.sqlite.model.Database;
import org.thecodebakers.aamo.sqlite.model.Table;
import org.xmlpull.v1.XmlPullParser;
import org.xmlpull.v1.XmlPullParserException;
import org.xmlpull.v1.XmlPullParserFactory;

import android.content.Context;
import android.util.Log;

public class DBParser {
	
	private Context ctx;
	private String currentStringValue;
	private String currentElementName;
	private int currentMacro;
	
	private Table tableElement;
	private Column column;
	private Database db;
	
	private static final int  MACRO_BD = 1;		//aamo-bd
	private static final int  MACRO_ELEMENT = 2; //table
	private static final int  MACRO_COLUMNS = 3; //columns
	private static final int  MACRO_COLUMN = 4;  //column	
	
	private static final String  PATH_XML = "app/bd/bd.xml";
	
	private List<Table> tables = new ArrayList<Table>();
	private List<Column> columns;
	
	public DBParser (Context ctx){
		 this.ctx = ctx;
	}
	
	public Database readXMLDatabase(Context ctx) throws AamoException {
		
		InputStream xml;
		
		try {
		
			db = new Database();
			xml = ctx.getApplicationContext().getAssets().open(PATH_XML);
			
			XmlPullParserFactory factory = XmlPullParserFactory.newInstance(); 
			factory.setNamespaceAware(true); 
			XmlPullParser xpp = factory.newPullParser(); 
			xpp.setInput(xml, "UTF-8");
			
			int eventType = xpp.getEventType();
			while (eventType != XmlPullParser.END_DOCUMENT) {
         		if(eventType == XmlPullParser.START_DOCUMENT) {
	        		 //continue;
	        	} 
	        	else if(eventType == XmlPullParser.START_TAG) {
	        	    
	        		currentElementName = xpp.getName();
	        	    
	        	    if (currentElementName.equals("aamo-bd")){
	        	        db.setTablesList(null);
	        	        currentMacro = MACRO_BD;
	        	    }
	        	    else if (currentElementName.equals("table")) {
	        	    	tableElement = new Table();
	        	    	tables.add(tableElement);	
	        	    	currentMacro = MACRO_ELEMENT;
	        	    }
	        	    else if (currentElementName.equals("columns")){
	        	    	columns = new ArrayList<Column>();
	        	    	currentMacro = MACRO_COLUMNS;
	        	    	tableElement.setColumnsList(columns);
	        	    }
	        	    else if (currentElementName.equals("column")){
	        	    	column = new Column();
	        	    	columns.add(column);
	        	    	currentMacro = MACRO_COLUMN;
	        	    }

	        	} 
	        	else if(eventType == XmlPullParser.END_TAG) {
	        	     if (xpp.getName().equals("aamo-bd") ||
	        	    	xpp.getName().equals("table") ||
	        	    	xpp.getName().equals("columns")) {
	        	    	eventType = xpp.next();
	        	    	continue;
	        	     }
	        	     if (currentMacro == MACRO_BD) {
	        	            if (currentElementName.equals("name")) {
	        	            	db.setName(currentStringValue.trim());
	        	            }
	        	            else if (currentElementName.equals("version")) {
	        	            	db.setVersion(Integer.parseInt(currentStringValue.trim()));
	        	            }
	        	            
	        	     }else if (currentMacro == MACRO_ELEMENT) {  //tables
	        	            
	        	    	    if (currentElementName.equals("name")) {
	        	                tableElement.setName(currentStringValue.trim());
	        	            }
	        	            
	        	     }
	        	     else if (currentMacro == MACRO_COLUMNS) {  
	        	    	 Log.d("XML", "columns...");
	        	     }
	        	     else if (currentMacro == MACRO_COLUMN) {  
	        	            
	        	    	   if (currentElementName.equals("primarykey")) {
	        	          	  column.setPrimaryKey(true);
	        	           }
	        	           else if (currentElementName.equals("name")) {
	        	          	  column.setName(currentStringValue.trim());
	        	           }
	        	           else if (currentElementName.equals("type")) {
	        	          	  column.setType(currentStringValue.trim());
	        	           }
	        	           else if (currentElementName.equals("notnull")) {
	        	          	  column.setNotNull(true);
	        	           }
	        	    	   //columns.add(column);
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
			throw new AamoException (e);
		} catch (XmlPullParserException e) {
			Log.d("XML", e.getMessage());
			throw new AamoException (e);
		}
		
		db.setTablesList(tables);
		return db;
	}
	
}
