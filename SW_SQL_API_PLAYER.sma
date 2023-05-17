#include "include/global"
#include "include/sql_playerdata"
#include "include/sql_tquery"

/*
%f - float
%d - integer
%i - integer
%s - string
%c - character
%L - multilingual*/

enum ePlayer_t
{
    m_iUserID,          // the id stored in the database
    m_iUserlevel,
    m_iBanned,
    m_iFirstconnect,
    m_iTotaltime,
    m_sAuthid[MAX_AUTHID_LEN],
    m_iTimer,
    m_sFirstName[MAX_NAME_LEN],
    m_sSkin[32],
    m_iPlayerQueryIndex  
}

new g_ePlayerdata[33][ePlayer_t];
new g_sQuery[256];


new const g_sConnectQuery[] = "SELECT id,firstnick, userlevel, banned, firstconnected, totaltime FROM players WHERE steamid ='%s'";

public plugin_natives()
{
	/*register_native("fm_AddAdminInfo", "Native_AddAdminInfo")
	register_native("fm_ClearAdminInfo", "Native_ClearAdminInfo")
	register_native("fm_InfoAdminUpdated", "Native_InfoAdminUpdated")
	
	register_native("fm_GetAdminInfoByIndex", "Native_GetAdminInfoByIndex")
	register_native("fm_GetAdminInfoByIdent", "Native_GetAdminInfoByIdent") 
	register_native("fm_GetAdminCount", "Native_GetAdminCount") // Returns the number of admins in the array
	*/

	register_library("api_player")
}


public plugin_init() 
{
	RegisterPlugin();
}


public client_putinserver(id)
{
	if (is_user_bot(id) || is_user_hltv(id))
	{
		return PLUGIN_CONTINUE	
	}
	
	new sAuthid[MAX_AUTHID_LEN]; get_user_authid(id, sAuthid, charsmax(sAuthid))
	if (equal(sAuthid, "STEAM_ID_PENDING"))
	{
		WarningLog("STEAM_ID_PENDING in client_putinserver")
		return PLUGIN_CONTINUE
	}

	new Data[ePlayer_t]; Data[m_iPlayerQueryIndex] = id
	copy(Data[m_sAuthid], MAX_AUTHID_LEN - 1, sAuthid)
	formatex(g_sQuery, charsmax(g_sQuery), g_sConnectQuery, sAuthid);
	//formatex(g_sQuery, charsmax(g_sQuery), "SELECT id,firstnick, from_unixtime(firstconnected,'\%d-\%m-\%Y - \%H:\%i:\%S') AS 'firstcon', TIME_FORMAT(SEC_TO_TIME(totaltime),'\%Hhours \%iminutes') AS 'total' FROM Player WHERE steamid ='%s'", sAuthid);
	api_SQLAddThreadedQuery(g_sQuery,"Handle_ConnectQuery", QUERY_NOT_DISPOSABLE, PRIORITY_HIGH, Data, ePlayer_t);
	//api_SQLAddThreadedQuery(g_sQuery, "Handle_ConnectQuery", QUERY_NOT_DISPOSABLE, PRIORITY_HIGH, Data, ePlayer_t)

	return PLUGIN_CONTINUE
}

public Handle_ConnectQuery(iFailState, Handle:hQuery, sError[], iError, Data[], iLen, Float:fQueueTime, iQueryIdent)
{
	DebugPrintLevel(1, "Handle_ConnectQuery: %f", fQueueTime)

	new id = Data[m_iPlayerQueryIndex]

	if(SQLCheckThreadedError(iFailState, hQuery, sError, iError))
	{
		WarningLog("Failed to load player data for <%s> from database", Data[m_sAuthid])
		return PLUGIN_HANDLED
	}
	
	// Check that the EXACT player who originally called the query is still connected
	new sAuthid[MAX_AUTHID_LEN]; get_user_authid(id, sAuthid, charsmax(sAuthid));

	if (!equal(sAuthid, Data[m_sAuthid]))
	{
		DebugPrintLevel(2, "Aborted loading player data for <%s> from database as they are no longer connected", Data[m_sAuthid])
		return PLUGIN_HANDLED
	}

	if (SQL_NumResults(hQuery) > 0)	
	{	
	new sFirstNick[33], sFirstConnect[32], sTotalTime[64];
	SQL_ReadResult(hQuery,1,sFirstNick,charsmax(sFirstNick));
	//SQL_ReadResult(hQuery,2,sFirstConnect,charsmax(sFirstConnect));
	//SQL_ReadResult(hQuery,3,sTotalTime,charsmax(sTotalTime));
	console_print(0,"DBID: %d, firstnick: %s", SQL_ReadResult(hQuery, 0),sFirstNick);
	g_ePlayerdata[id][m_iUserID] = SQL_ReadResult(hQuery, 0);
	SQL_ReadResult(hQuery,1,g_ePlayerdata[id][m_sFirstName],charsmax(g_ePlayerdata[][m_sFirstName]));
	
	
	//g_ePlayerdata[id][m_sFirstName] = SQL_ReadResult(hQuery, 1);
	//g_iPlayerIdent[id] = SQL_ReadResult(hQuery, 0)
	//fm_DebugPrintLevel(2, "Loaded player ident for <%s> from database: #%d", Data[m_sPlayerQueryAuthid], g_iPlayerIdent[id])
	
	//if (!g_iPlayerIdent[id])
	//{
	//	fm_WarningLog("Player ident for <%s> from database is 0!", Data[m_sPlayerQueryAuthid])
	//	return 0
	//}
	
	//CachePlayerIdent(id, Data[m_sPlayerQueryAuthid])
	//ExecutePlayerIdentForward(id)
	}
	else
	{	
	console_print(0,"No Results from Database");
		//formatex(g_sQuery, charsmax(g_sQuery), "INSERT INTO players (player_authid) VALUES ('%s');", Data[m_sPlayerQueryAuthid])
		//g_iPlayerQuery[id] = fm_SQLAddThreadedQuery(g_sQuery, "Handle_InsertPlayerId", QUERY_DISPOSABLE, PRIORITY_NORMAL, Data, iLen)
	}

	return PLUGIN_HANDLED
}
