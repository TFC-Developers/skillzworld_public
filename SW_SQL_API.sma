// code by watch/fm see https://github.com/ben-watch/feckinmad, modified by MrKoala & Ilup in order to migrate skillzworld 
// from the c++ metamod plugin to amxmodx

#include "include/global"
#include "include/api_sql"

#include <fakemeta> // register_forward()

new const g_sSqlConfig[] = "sw_sql.cfg"
new Handle:g_SqlTuple = Empty_Handle

new g_pCvarHostname, g_pCvarUsername, g_pCvarDatabase, g_pCvarPassword
new g_pCvarEnabled, g_pCvarTimeout
//new g_pCvarFailMax, g_iConnectionFailCount // See notes on Native_CheckFailLimit()

new g_iForward

public plugin_precache()
{
	g_pCvarHostname = register_cvar("sw_sql_hostname", "")
	g_pCvarUsername = register_cvar("sw_sql_username", "")
	g_pCvarDatabase = register_cvar("sw_sql_database", "")
	g_pCvarPassword = register_cvar("sw_sql_password", "")

	g_pCvarEnabled = register_cvar("sw_sql_enabled", "0")
	g_pCvarTimeout = register_cvar("sw_sql_timeout", "3")

	if (ExecuteSQLFile() && get_pcvar_num(g_pCvarEnabled))
	{
		CreateSQLTuple()
	}
}

ExecuteSQLFile()
{
	DebugPrintLevel(1, "ExecuteSQLFile()")

	new sFile[128]; BuildAMXFilePath(g_sSqlConfig, sFile, charsmax(sFile), "amxx_configsdir")
	if (!file_exists(sFile))
	{
		WarningLog("Failed to exec \"%s\"", sFile)
		log_amx("File: \"%s\" is missing. Failed to create database tuple", sFile)
		return 0
	}

	server_cmd("exec \"%s\"", sFile)	
	server_exec()

	return 1
}

CreateSQLTuple()
{
	new sHostname[64], sUsername[32], sPassword[32], sDatabase[128]

	get_pcvar_string(g_pCvarHostname, sHostname, charsmax(sHostname))
	get_pcvar_string(g_pCvarUsername, sUsername, charsmax(sUsername))
	get_pcvar_string(g_pCvarPassword, sPassword, charsmax(sPassword))
	get_pcvar_string(g_pCvarDatabase, sDatabase, charsmax(sDatabase))

	g_SqlTuple = SQL_MakeDbTuple(sHostname, sUsername, sPassword, sDatabase, get_pcvar_num(g_pCvarTimeout))	
	log_amx("Database tuple created. Host: \"%s\"", sHostname)

	if (!g_iForward)
	{
		g_iForward = register_forward(FM_Sys_Error, "plugin_end")
	}
}


public plugin_init()
{
	RegisterPlugin()
	register_concmd("admin_reloadtuple", "Admin_ReloadTuple", ADMIN_KICK, "")
}

public Admin_ReloadTuple(id, iLevel, iCommand)
{
	if (g_SqlTuple != Empty_Handle)
	{
		FreeSQLTuple()
	}

	if (ExecuteSQLFile() && get_pcvar_num(g_pCvarEnabled))
	{
		CreateSQLTuple()
	}

	return PLUGIN_HANDLED
}

FreeSQLTuple()
{
	SQL_FreeHandle(g_SqlTuple)
	g_SqlTuple = Empty_Handle
}

public plugin_end() 
{
	if (g_SqlTuple != Empty_Handle)
	{
		FreeSQLTuple()
	}
}

public plugin_natives()
{	
	register_native("api_SQLGetHandle", "Native_GetSqlHandle")
	register_native("api_SQLCheckFailLimit", "Native_CheckFailLimit")
	register_library(g_sSQLModule)	
}

public Native_GetSqlHandle() 
{
	return _:g_SqlTuple
}

public Native_CheckFailLimit()
{
	// Workaround for issues with SQL failures and threaded queries stacking up in the SQLX module
	// No longer needed, replaced by FM_SQL_TQUERY for better threaded query management
	// Leave this forward in until all plugins updated to use new method.
	/*fm_DebugPrintLevel(1, "Native_CheckFailLimit()")

	if (g_SqlTuple != Empty_Handle && ++g_iConnectionFailCount >= get_pcvar_num(g_pCvarFailMax))
	{
		fm_WarningLog("Database tuple destroyed. Connection fail limit reached")	
		FreeSQLTuple()
		
		return 1
	}*/
	return 0
}



