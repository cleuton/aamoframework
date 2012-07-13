package org.thecodebakers.aamo.sqlite;

import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

import org.thecodebakers.aamo.AamoException;
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
	
	Table tableElement;
	private Database db;
	
	public static final int  MACRO_BD = 1;		//aamo-bd
	public static final int  MACRO_ELEMENT = 2; //table
	public static final int  MACRO_COLUMNS = 3; //columns
	public static final int  MACRO_COLUMN = 4;  //column	
	
	private List<Table> tables = new ArrayList<Table>();
	
	public DBParser (Context ctx){
		
		 this.ctx = ctx;
		 
	}
	
	public boolean readXMLDatabase() throws AamoException {
		
		
		InputStream xml;
		boolean resultado = true;
		
		try {
		
			db = new Database();
			xml = ctx.getApplicationContext().getAssets().open("bd/bd.xml");
			
			XmlPullParserFactory factory = XmlPullParserFactory.newInstance(); 
			factory.setNamespaceAware(true); 
			XmlPullParser xpp = factory.newPullParser(); 
			xpp.setInput(xml, "UTF-8");
			
			int eventType = xpp.getEventType();
			
	        while (eventType != XmlPullParser.END_DOCUMENT) {
         		if(eventType == XmlPullParser.START_DOCUMENT) {
	        		 continue;
	        	} 
	        	else if(eventType == XmlPullParser.START_TAG) {
	        	    currentElementName = xpp.getName();
	        	    if (currentElementName.equals("aamo-bd")){
	        	        db.setName(null);
	        	        db.setTablesList(null);
	        	    	db.setVersion(0);
	        	    	currentMacro = MACRO_BD;
	        	    }
	        	    else if (currentElementName.equals("table")) {
	        	    	tableElement = new Table();
	        	    	tableElement.setColumn(null);
	        	    	tableElement.setPrimaryKey(false);
	        	    	tableElement.setSize(0);
	        	    	tableElement.setType(null);
	        	    	currentMacro = MACRO_ELEMENT;
	        	    }
	        	    else if (currentElementName.equals("columns")){
	        	       
	        	    	currentMacro = MACRO_COLUMNS;
	        	    }
	        	    else if (currentElementName.equals("column")){
	        	        
	        	    	currentMacro = MACRO_COLUMN;
	        	    }

	        	} 
	        	else if(eventType == XmlPullParser.END_TAG) {
	        	    if (xpp.getName().equals("aamo-bd") ||
	        	    	xpp.getName().equals("table")) {
	        	    	eventType = xpp.next();
	        	    	continue;
	        	     }
	        	     if (currentMacro == MACRO_BD) {
	        	            if (currentElementName.equals("aamo-bd")) {
	        	                if (currentElementName.equals("version")) {
	        	                    // version
	        	                    double version = Double.parseDouble(currentStringValue);
	        	                }
	        	            }
	        	            else if (currentElementName.equals("name")) {
	        	            	db.setName(currentStringValue.trim());
	        	            }
	        	            else if (currentElementName.equals("version")) {
	        	            	
	        	            	db.setVersion(Integer.parseInt(currentStringValue.trim()));
	        	            }
	        	            
	        	     }else if (currentMacro == MACRO_ELEMENT) {  //tables
	        	            
	        	    	    // entries.add(readEntry(parser));
	        	            if (currentElementName.equals("name")) {
	        	                tableElement.setName(currentStringValue.trim());
	        	            }
	        	            
	        	     }
	        	     else if (currentMacro == MACRO_COLUMN) {  
	        	            
	        	            if (currentElementName.equals("primarykey")) {
	        	                tableElement.setPrimaryKey(true);
	        	            }
	        	            else if (currentElementName.equals("name")) {
	        	                tableElement.setName(currentStringValue.trim());
	        	            }
	        	            else if (currentElementName.equals("type")) {
	        	                tableElement.setType(currentStringValue.trim());
	        	            }
	        	            else if (currentElementName.equals("size")) {
	        	            	tableElement.setSize(Integer.parseInt(currentStringValue.trim()));
	        	            }
	        	           
	        	    }     
	        		currentStringValue = null;
	           } 
	           else if(eventType == XmlPullParser.TEXT) {
	        		currentStringValue = xpp.getText().trim();
	           }
         	
         	   tables.add(tableElement);	
	           eventType = xpp.next();
	         }
			
	        
			
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
	
	private String readColumns (XmlPullParser parser) throws XmlPullParserException, IOException{
		String result = "";
		if (parser.next() == XmlPullParser.TEXT) {
		    result = parser.getText();
		    parser.nextTag();
		}
		return result;
	}
	
}
