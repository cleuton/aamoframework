package org.thecodebakers.aamo.sqlite;

import java.util.List;

import org.thecodebakers.aamo.AamoException;
import org.thecodebakers.aamo.sqlite.model.Database;

import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.util.Log;

public class DBAdapter implements IDBAdapter {
	
	private static SQLiteDatabase db = null;
	private DBHelper dbHelper= null;
	private static final String TAG = "DBAdapter";
	private static Context ctx = null;
	
	public DBAdapter(Context context) {
		//Database database = readXML (context);
		
		ctx = context;
    }
	
	private Database readXML(Context context){
		
		DBParser parser = new DBParser(context);
		Database database = null;
		try {
			database = parser.readXMLDatabase(context);
		} catch (AamoException e) {
			Log.d(TAG, e.getMessage());
		} catch (Exception ex){
			Log.d(TAG, ex.getMessage());
		}
		parser = null;
		
		return database;
	}
	
	public Cursor query(String sql, List<String> params) {
		String[] args = null;
		if (params != null){
			args = formatParams (params);
		}
		
		//db = dbHelper.getReadableDatabase();   
        Cursor cursor = db.rawQuery(sql, args);
        cursor.moveToFirst();
        
        return cursor;
	}
	
	public void execSQL (String sql, List<String> params){ 
		String[] args = null;
		if (params != null){
			args = formatParams (params);
		}
		
		//db = dbHelper.getWritableDatabase();
		db.execSQL(sql, args);
		//db.close();
		
	}
	
	public void openDatabase (String nome){
		Database database = readXML (ctx);
		dbHelper = new DBHelper(ctx, database);
		db = dbHelper.getWritableDatabase();
	}
		
	private String[] formatParams(List<String> params){
		String[] args = null;
		if (params != null){
			args = new String [params.size()];
			for (int i = 0; i < params.size(); i++) {
				args[i] = params.get(i);
			}
		}
		
		return args;
	}
	
	public int getDatabaseVersion() {
		return DBHelper.databaseVersion;
	}

	
}