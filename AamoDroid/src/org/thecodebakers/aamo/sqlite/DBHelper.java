package org.thecodebakers.aamo.sqlite;

import java.util.List;

import org.thecodebakers.aamo.AamoException;
import org.thecodebakers.aamo.sqlite.model.Column;
import org.thecodebakers.aamo.sqlite.model.Database;
import org.thecodebakers.aamo.sqlite.model.Table;

import android.content.Context;
import android.database.SQLException;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;
import android.util.Log;

public class DBHelper extends SQLiteOpenHelper {
	
	    private static String databaseName; // = "contatos.db";;
	    public  int databaseVersion; 		// = 1;
	    private String tableName;		    // = "contato";
	    private Context context;
	    Database database;
	    static String[] colunas;
	    private static final String TAG = "AAMO";
	    private SQLiteDatabase db;
	    
	    /*
		public DBHelper(Context context) {
			super(context, databaseName, null, databaseVersion);
			this.context = context;
		}*/
		
		public DBHelper(Context context, Database database) {
			super(context, database.getName(), null, database.getVersion());
			this.context = context;
			this.database = database;
		}
		
		@Override
        public void onCreate(SQLiteDatabase db) {
             Log.d(TAG, "onCreate...");
             
             /*
             db.execSQL("CREATE TABLE " + tableName + " (id INTEGER PRIMARY KEY, nome varchar(50), " +
            		  	 " endereco varchar(50), email varchar(50))");
              
             Log.d(TAG, " Inserindo dados na tabela : " + tableName);
              
             db.execSQL("insert into " +  tableName + " (id,nome, endereco,email) " +
            		     " values (NULL, 'Aamo db', 'rua 1 qda 2', 'fcmr@aamo.com')");
            
             Log.d(TAG, " Dados insetidos com sucesso tabela : " + tableName);*/
             
             onCreateDB (db);
        }
		 
		
		private void onCreateDB(SQLiteDatabase db) {
			 Log.d(TAG, "Creating tables ");
			 StringBuilder sb = new StringBuilder();
			 
			 try{
				 
				 //db = SQLiteDatabase.openOrCreateDatabase(database.getName() + ".db", null);
				 Log.d(TAG, "database is open? " + db.isOpen());
				 List<Table> tables = database.getTablesList();
				 
				 for (Table table : tables) {
					
					 String name   = table.getName();
					 sb.append("CREATE TABLE ");
					 sb.append(name);
					 sb.append ("( ");
					 
					 List<Column> columns = table.getColumnsList();
					 String separador = ",";
					 int numberOfColumns = columns.size();
					 int count = 1;
					 for (Column colunas : columns) {
						 String columnName = colunas.getName();
						 sb.append(columnName + " ");
						 String type = colunas.getType() ;
						 sb.append(type + " ");
						 //PK
						 if (colunas.isPrimaryKey()){
							 sb.append(" PRIMARY KEY ");
						 }	
						 //not null
						 if (colunas.isNotNull()){
							 sb.append(" Not Null ");
						 }else {
							 sb.append(" Null ");
						 }
						 //comma ","
						 if (count < numberOfColumns){
							 sb.append(separador);
						 }
						 count ++;
					 }

					 sb.append (" )");
					 db.execSQL(sb.toString());
				 }
				 
			     
			 }catch(SQLException e)
			 {
				 Log.d(TAG, e.getMessage());
			 }
			 
			 
		}
		
		@Override
		public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
		     Log.d(TAG, "updating the database");
		    
		     if ((newVersion - oldVersion) > 2) {
		    	 Log.d(TAG, "the database will be update");
		    	 db.execSQL("DROP TABLE IF EXISTS " + tableName);
		    	 onCreate(db);
		     }
		     else {
		    	 Log.d(TAG, "the update of the database is not necessary");
		     }
		     
		}
}
