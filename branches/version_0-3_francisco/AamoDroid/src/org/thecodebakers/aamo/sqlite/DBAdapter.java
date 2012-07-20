package org.thecodebakers.aamo.sqlite;

import java.util.List;

import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;

public class DBAdapter implements IDBAdapter {
	
	private SQLiteDatabase db = null;
	private DBHelper dbHelper= null;
	private static final String TAG = "DBAdapter";
	
	private Context ctx;
	
	public DBAdapter(Context context) {
        dbHelper = new DBHelper(context);
        this.ctx = context;
    }
	
	
	public Cursor query(String sql, List<String> params) {
		String[] args = null;
		if (params != null){
			args = formatParams (params);
		}
		
		this.db = dbHelper.getReadableDatabase();   
        Cursor cursor = db.rawQuery(sql, args);
        cursor.moveToFirst();
        
        return cursor;
	}
	
	public void execSQL (String sql, List<String> params){ 
		String[] args = null;
		if (params != null){
			args = formatParams (params);
		}
		
		this.db = dbHelper.getWritableDatabase();
		db.execSQL(sql, args);
		db.close();
		
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