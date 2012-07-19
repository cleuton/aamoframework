package org.thecodebakers.aamo.sqlite;

import java.util.List;

import org.keplerproject.luajava.LuaState;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.SQLException;
import android.database.sqlite.SQLiteDatabase;
import android.util.Log;

public class DBAdapter implements IDBAdapter {
	
	private SQLiteDatabase db = null;
	private DBHelper dbHelper= null;
	private static final String TAG = "DBAdapter";
	
	private Context ctx;
	
	public DBAdapter(Context context) {
        dbHelper = new DBHelper(context);
        this.ctx = context;
    }
	
	/* (non-Javadoc)
	 * @see br.com.thecodebakers.hppfree.persistence.IDBAdapter#insert(byte[])
	 */
	public long insert(String uuid, byte[] lob) throws SQLException{
		this.db = dbHelper.getWritableDatabase();
		ContentValues cv = new ContentValues();  
		cv.put("uid", uuid);  
        cv.put("textoSecreto", lob);  
        long retorno = db.insert("elemento", null, cv);  
        db.close();
        Log.i(TAG, "Registro criado com sucesso.");
	    return retorno;
	    
	}
	
	/* (non-Javadoc)
	 * @see br.com.thecodebakers.hppfree.persistence.IDBAdapter#update(java.lang.String, byte[])
	 */
	public int update (String uid,byte[] lob) throws SQLException{
		this.db = dbHelper.getWritableDatabase(); 
		ContentValues cv = new ContentValues();  
        cv.put("uid", uid);  
        cv.put("textoSecreto", lob);  
        int retorno = db.update("elemento", cv, "uid = ?", new String[]{ uid });
        db.close();
        Log.i(TAG, "Registro atualizado com sucesso.");
		return retorno;
		   
	}
	
	/* (non-Javadoc)
	 * @see br.com.thecodebakers.hppfree.persistence.IDBAdapter#delete(java.lang.String)
	 */
	public int delete(String uid)throws SQLException{ 
		this.db = dbHelper.getWritableDatabase();
		int retorno = db.delete("elemento", "uid = ?", new String[]{ uid }); 
		db.close();
		Log.i(TAG, "Registro excluido com sucesso.");
		return  retorno;
    }  
	
	/**
	 * execute a query 
	 * @param sql - sql command
	 * @param params - parameters
	 * @return cursor
	 */
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
	
	/**
	 * Execute a SQL statement  
	 * @param sql
	 * @param params
	 */
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