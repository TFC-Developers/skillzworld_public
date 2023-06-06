// code by watch/fm see https://github.com/ben-watch/feckinmad, modified by MrKoala & Ilup in order to migrate skillzworld 
// from the c++ metamod plugin to amxmodx

#if defined _sql_included
  #endinput
#endif
#define _sql_included

#include <sqlx>
#include "include/global" // fm_WarningLog()

#pragma reqlib api_sql

stock const g_sSQLModule[] = "api_sql"

native api_SQLCheckFailLimit()
native Handle:api_SQLGetHandle()

stock Handle:fm_BlockingQuery(const sQuery[])
{
	new Handle:SqlTuple = api_SQLGetHandle()
	if (SqlTuple == Empty_Handle)
		return Empty_Handle

	new sError[256], iError
	new Handle:SqlConnection = SQL_Connect(SqlTuple, iError, sError, charsmax(sError))
	if(SqlConnection == Empty_Handle)
	{
		WarningLog("Could not connect to database: (#%d) %s", iError, sError)
		api_SQLCheckFailLimit()
		return Empty_Handle
	}

	new Handle:hQuery = SQL_PrepareQuery(SqlConnection, sQuery)
	if(!SQL_Execute(hQuery))
	{
		iError = SQL_QueryError(hQuery, sError, charsmax(sError))
		WarningLog("Query failed: (#%d) %s.", iError, sError)
	
		SQL_FreeHandle(hQuery)
		SQL_FreeHandle(SqlConnection)	
		return Empty_Handle
	}
	SQL_FreeHandle(SqlConnection)
	return hQuery
}

stock fm_SQLMakeStringSafe(sString[], iLen)
{
	replace_all(sString, iLen, "\\", "\\\\")
	replace_all(sString, iLen, "'", "\\'")
	sString[iLen] = 0
}