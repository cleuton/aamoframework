package org.thecodebakers.aamo;

public class AamoException extends Exception
{
	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;

	public AamoException(String str)
	{
		super(str);
	}
	
	
	public AamoException(Exception e)
	{
	   super((e.getCause() != null) ? e.getCause() : e);
	}
} 