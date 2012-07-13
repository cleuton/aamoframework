package org.thecodebakers.aamo.sqlite;

import android.content.Context;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;
import android.util.Log;

public class DBHelper extends SQLiteOpenHelper {
	
	    private static String databaseName;
	    public static  int databaseVersion;
	    private static String tableName;

		
	    private static String[] colunas;
	    
		public DBHelper(Context context) {
		    super(context, databaseName, null, databaseVersion);
		}
				 
		@Override
		public void onCreate(SQLiteDatabase db) {
			 Log.d("HPPFree", "Criando a tabela no banco de dados.");
		     db.execSQL("CREATE TABLE " + tableName + "(uid TEXT, textoSecreto BLOB)");
		}
		
		@Override
		public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
		     Log.d("HPPFree", "Verificando atualização do banco de dados.");
		     if ((newVersion - oldVersion) > 2) {
		    	 Log.d("HPPFree", "Há necessidade de atualizar o banco.");
		    	 db.execSQL("DROP TABLE IF EXISTS " + tableName);
		    	 onCreate(db);
		     }
		     else {
		    	 Log.d("HPPFree", "A versão do banco de dados é praticamente a mesma. Os registros serão preservados.");
		     }
		     
		}
}
