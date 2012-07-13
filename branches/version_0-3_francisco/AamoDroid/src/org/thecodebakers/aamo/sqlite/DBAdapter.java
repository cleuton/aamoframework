package org.thecodebakers.aamo.sqlite;

import java.util.List;

import android.content.ContentValues;
import android.content.Context;
import android.database.SQLException;
import android.database.sqlite.SQLiteDatabase;
import android.util.Log;

public class DBAdapter implements IDBAdapter {
	
	private SQLiteDatabase db = null;
	private DBHelper dbHelper= null;
	private static final String TAG = "DBAdapter";
	

	
	public DBAdapter(Context context) {
        dbHelper = new DBHelper(context);
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
	
	public List listAll (){ 
	    return null;  
	}
	
	public int getDatabaseVersion() {
		return DBHelper.databaseVersion;
	}

	
}