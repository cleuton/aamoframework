package org.thecodebakers.aamo.sqlite;

import java.util.List;

import android.database.Cursor;
import android.database.SQLException;

/**
 * DAO Interface.
 * 
 * @author thecodebakers@gmail.com
 *
 */
public interface IDBAdapter {
	
	/**
	 * execute a query
	 *  
	 * @param sql - sql command
	 * @param params - parameters query
	 * 
	 * @return cursor
	 */
	public abstract Cursor query(String sql, List<String> params);
		
	
	/**
	 * Execute a SQL statement  
	 * 
	 * @param sql  - sql command
	 * @param params - parameters query
	 */
	public void execSQL (String sql, List<String> params);
	
	/**
	 * Database version
	 * 
	 * @return int 
	 */
	public int getDatabaseVersion();
	
	public void openDatabase (String nome);
	
}