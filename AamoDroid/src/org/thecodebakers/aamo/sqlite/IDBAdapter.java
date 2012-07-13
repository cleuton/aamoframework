package org.thecodebakers.aamo.sqlite;

import android.database.SQLException;

/**
 * Interface para uso do DAO de alto nível.
 * 
 * @author Cleuton Sampaio e Francisco Rogrigues - thecodebakers@gmail.com
 *
 */
public interface IDBAdapter {

	/**
	 * insere um registro na base de dados 
	 * @param uuid  - id de controle do registro
	 * @param lob	- dados para carregar o campo blob
	 * @return		- long com o retorno da operação. Se -1 ocorreu algum erro.
	 * @throws SQLException
	 */
	public abstract long insert(String uuid, byte[] lob) throws SQLException;
	/**
	 * atualiza um registro na base
//	 * @param uid - id de controle do registro
	 * @param lob - dados para carregar o campo blob
	 * @return    - int com o retorno da operação. 
	 * @throws SQLException
	 */
	public abstract int update(String uid, byte[] lob) throws SQLException;
     /**
      * Exclui um registro na base
      * @param Se -1 ocorreu algum erro.
      * @return  - int com o retorno da operação. 
      * @throws SQLException
      */
	public abstract int delete(String uid)throws SQLException;
	
	/**lista todos os registros
	 * 
	 * @return
	 */
	
	
	public int getDatabaseVersion();
	//public List<Agregador> listSource () throws SQLiteException ;
	
	/**
	 * Atualiza a nova lista no banco, após deletar todos os registros existentes.
	 * @param lista Nova lista de elementos.
	 * @param newKey Nova chave.
	 * @return True ok.
	 */
	//public boolean updateNewList(List<Elemento> lista, String newKey);
}