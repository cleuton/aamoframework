package org.thecodebakers.aamo.sqlite;

import java.util.List;

import android.database.Cursor;

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
	
	/**
	 * open the database
	 * @param nome
	 */
	public void openDatabase (String nome);
	
	/**
	 * close the database
	 * @param nome
	 */
	public void closeDatabase (String nome);
	
}