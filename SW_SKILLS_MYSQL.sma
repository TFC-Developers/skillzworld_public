
#include "include/api_skills_mysql"             // Include file for this plugin source
#include "include/global"                       // Include file for general functions
#include "include/sql_tquery"                   // Include file for threaded queries
#include <engine>
#include <fakemeta>
#include "include/utils"                        // Include file for utility functions
#include "include/sql_dbqueries"                // Include file for database queries (provides the strings)
#include "include/effects"                      // Include file for effects
#include "include/api_skills_mapentities"       // Include file for map entities

//global variables
new g_pCvarOldRanks; new g_pCvarOldRuns;            // Cvars for the old ranks and runs table
new bool:g_bInRequest[32];                          // Array to check if a player is already requesting data
new g_iRequestFor[32];                                 // Array to check for which player the request is
new g_iRequest[32];                                   // Array to check which request is being made 
new bool:g_bLegacyFound;                                   // Boolean to check if a legacy course was found in the database
new bool:g_bReloaded = false;                          // Boolean to check if the courses were reloaded
//array of requests number => description
new const g_szRequest[3][32] = { "Retrieve legacy stats", "","" };
//end global variables

//strings
new const g_szPleaseWait[] = "* Requesting data from database, please wait...";
new const g_szNoData[] = "* No data found in the database.";
new const g_szError[] = "* Failed to load the statistics from the database. Please try again later.";
new const g_szWait[] = "* Please wait for the previous request to finish.";
//end strings
/*
DEBUG: [SW_SKILLS_MYSQL.amxx] Column 0 (id) = 5
DEBUG: [SW_SKILLS_MYSQL.amxx] Column 1 (course_id) = 1
DEBUG: [SW_SKILLS_MYSQL.amxx] Column 2 (player_id) = 18787
DEBUG: [SW_SKILLS_MYSQL.amxx] Column 3 (time) = 0
DEBUG: [SW_SKILLS_MYSQL.amxx] Column 4 (created_at) = 2023-05-24 12:22:04
DEBUG: [SW_SKILLS_MYSQL.amxx] Column 5 (player_class) = 11
DEBUG: [SW_SKILLS_MYSQL.amxx] Column 6 (steamid) = STEAM_0:1:14778066
DEBUG: [SW_SKILLS_MYSQL.amxx] Column 7 (most_used_nickname) = Ilupuusikuniluusi*/
enum eSpeedTop_t
{
	m_iTopPlayerIdent,                          // The player's ident (sql player id)
	m_sTopPlayerAuthid[MAX_AUTHID_LEN],         // The player's authid
	m_sTopPlayerName[MAX_NAME_LEN],             // The player's name
	Float:m_fTime,                              // The player's time
	m_iCourseID,                                // The course id (Mysql ID not local id)
	m_CreatedAt[64],                            // The date the run was created
	m_iPlayerClass,                             // The player's class
}
new Array:g_TopList = Invalid_Array;            // Array for the top 100 players
new Array:g_GroupedTopList = Invalid_Array;		// Array for the grouped top 100 players
new g_iGroupedTopCount = -1;
new g_iTopCount = -1;
#define MAX_MOTD_RANKS 20
#define RECORD_SOUND "Trumpet1.wav" 		// The sound played when the all time speedrun record is broken

#define define_inrequest { if(g_bInRequest[id]) { client_print(id, print_chat, g_szWait); return; } }
#define define_sql_error { if(SQLCheckThreadedError(iFailState, hQuery, sError, iError)) { client_print(id, print_chat, g_szError); g_bInRequest[id] = false; return PLUGIN_HANDLED; } }

public plugin_natives() {
    register_native("api_sql_insertcourse", "SQLNative_InsertCourse");
    register_native("api_sql_insertlegacycps", "SQLNative_InsertLegacyCPs");
    register_native("api_sql_insertrun", "SQLNative_InsertRun");
    register_native("api_sql_reloadcourses", "SQLNative_ReloadCourses");
    register_native("api_sql_updatemapflags", "SQLNative_UpdateMapFlags");
    register_library("sw_sql_skills");
}

public plugin_init()
{
	RegisterPlugin();
	register_clcmd("say /oldtop5", "cmd_oldtop5");                              // Shows the old top5
	register_clcmd("say /oldstatsme", "cmd_oldstatsme");                        // Shows the old stats of the player
	register_clcmd("say /oldstats", "menu_deploy");                             // Shows the old stats menu
	register_clcmd("say /debugeffect", "cmd_effect");                               // Shows the old top menu
	register_clcmd("say", "Handle_Say");                                        // Handle the say command
	register_clcmd("say_team", "Handle_Say");                                   // Handle the say_team command
	g_pCvarOldRanks = register_cvar("sw_sqloldranks", "climb_oldranks")         // Cvar for the old ranks table
	g_pCvarOldRuns = register_cvar("sw_sqloldruns", "climb_oldrunstable")       // Cvar for the old runs table
	g_bLegacyFound = false;                                                     // Set the legacy found boolean to false
	g_TopList = ArrayCreate(eSpeedTop_t);                                       // Create the array for the top 100 players
	g_GroupedTopList = ArrayCreate(eSpeedTop_t);                                // Create the array for the grouped top 100 players
}  
public cmd_effect(id) {
    api_firework(id,5);
}
public plugin_end()
{
	ArrayDestroy(g_TopList);                                                    // Destroy the array for the top 100 players
	ArrayDestroy(g_GroupedTopList);                                             // Destroy the array for the grouped top 100 players
}

public SQLNative_UpdateMapFlags(iPlugin, iParams) {
    new iFlags[1];
    iFlags[0] = get_param(1);
    new szMapname[64]; get_mapname(szMapname, charsmax(szMapname));
    new szQuery[256]; formatex(szQuery, charsmax(szQuery), sql_insertmap, szMapname);
    api_SQLAddThreadedQuery(szQuery, "Handle_UpdateMapFlags", QUERY_NOT_DISPOSABLE, PRIORITY_HIGHEST, iFlags, 1);
}
public Handle_UpdateMapFlags(iFailState, Handle:hQuery, sError[], iError, Data[], iLen, Float:fQueueTime, iQueryIdent) {
    if(SQLCheckThreadedError(iFailState, hQuery, sError, iError)) { 
        DebugPrintLevel(0, "Failed to update map flags: %s", sError);
    }

    new iFlags = 0;
    if (iLen > 0) {
        iFlags = Data[0];
    }
    new szMapname[64]; get_mapname(szMapname, charsmax(szMapname));
    new szQuery[256]; formatex(szQuery, charsmax(szQuery), sql_updatemapflags, iFlags, szMapname);
    api_SQLAddThreadedQuery(szQuery, "Handle_UpdateMapFlagsTWO", QUERY_NOT_DISPOSABLE, PRIORITY_HIGHEST);
}
public Handle_UpdateMapFlagsTWO(iFailState, Handle:hQuery, sError[], iError, Data[], iLen, Float:fQueueTime, iQueryIdent) {
    if(SQLCheckThreadedError(iFailState, hQuery, sError, iError)) { 
        DebugPrintLevel(0, "Failed to update map flags: %s", sError);
    }
}
public SQLNative_ReloadCourses() {
    // set a task of 5 seconds to reload the courses
   // native set_task(Float:time, const function[], id = 0, const any:parameter[] = "", len = 0, const flags[] = "", repeat = 0);
   if (g_bReloaded == true) { return; }
   g_bReloaded = true;
   client_print(0, print_chat, "* Reloading the map in 30 seconds due to the import of the legacy courses");
   set_task(15.0, "reload_map", 1407, "");
}

public reload_map() {
	client_print(0, print_chat, "* Reloading the map in 15 seconds due to the import of the legacy courses");
	set_task(15.0, "reload_map2", 1408, "");
}

public reload_map2()
{
	new szMap[64]; get_mapname(szMap, charsmax(szMap));
	server_cmd("changelevel %s\n", szMap)
}
// logic; sql_loadcourses -> api_registercourse 
//              |-done-> load all cps for map (done in Handle_QueryLoadCourses) and check there if a legacy course was if not call the api function to load the cps from file                   
public plugin_precache() {
	precache_sound(RECORD_SOUND);
	sql_loadcourses();
	sql_loadruns();
	sql_loadgroupedruns();
}
//loads all courses from the database
public sql_loadcourses() {
    new szMapname[64]; get_mapname(szMapname, charsmax(szMapname));
    new szQuery[512]; formatex(szQuery, charsmax(szQuery), sql_selectcourses, szMapname);
    api_SQLAddThreadedQuery(szQuery, "Handle_QueryLoadCourses", QUERY_NOT_DISPOSABLE, PRIORITY_HIGHEST);

    new szQuery2[512]; formatex(szQuery2, charsmax(szQuery2), sql_retrievemapflags, szMapname);
    api_SQLAddThreadedQuery(szQuery2, "Handle_QueryLoadMapFlags", QUERY_NOT_DISPOSABLE, PRIORITY_HIGHEST);
}

public Handle_QueryLoadMapFlags(iFailState, Handle:hQuery, sError[], iError, Data[], iLen, Float:fQueueTime, iQueryIdent) {
	if(SQLCheckThreadedError(iFailState, hQuery, sError, iError)) { 
		DebugPrintLevel(0, "Failed to load map flags: %s", sError);
	}
	new iFlags = 0;
	if (SQL_NumResults(hQuery) > 0) {	
		if (SQL_FieldNameToNum(hQuery,"flags") >= 0) { iFlags = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"flags")); }
	} else {
		DebugPrintLevel(0, "No map flags found for current map");
	}
	api_process_mapflags(iFlags);
}

public Handle_QueryLoadCourses(iFailState, Handle:hQuery, sError[], iError, Data[], iLen, Float:fQueueTime, iQueryIdent) {
	if(SQLCheckThreadedError(iFailState, hQuery, sError, iError)) { 
		DebugPrintLevel(0, "Failed to insert course into database: %s", sError);
	}
	new Buffer[eCourseData_t];
	if (SQL_NumResults(hQuery) == 0) {
		//no courses... call the api function to load the cps from file
		api_legacycheck();
		return;
	}
	while (SQL_MoreResults(hQuery)) {
		if (SQL_FieldNameToNum(hQuery,"id") >= 0) { Buffer[mC_sqlCourseID] = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"id")); }
		if (SQL_FieldNameToNum(hQuery,"creator_id") >= 0) { Buffer[mC_iCreatorID] = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"creator_id")); }
		if (SQL_FieldNameToNum(hQuery,"name") >= 0) { SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"name"), Buffer[mC_szCourseName], charsmax(Buffer[mC_szCourseName])); }
		if (SQL_FieldNameToNum(hQuery,"description") >= 0) { SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"description"), Buffer[mC_szCourseDescription], charsmax(Buffer[mC_szCourseDescription])); }
		if (SQL_FieldNameToNum(hQuery,"legacy") >= 0) { Buffer[mC_bLegacy] = bool:SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"legacy")); }
		if (Buffer[mC_bLegacy]) { g_bLegacyFound = true; }
		if (SQL_FieldNameToNum(hQuery,"difficulty") >= 0) { Buffer[mC_iDifficulty] = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"difficulty")); }
		if (SQL_FieldNameToNum(hQuery,"active") >= 0) { Buffer[mC_bSQLActive] = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"active")); }
		if (SQL_FieldNameToNum(hQuery,"flags") >= 0) { Buffer[mC_iFlags] = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"flags")); }
		if (SQL_FieldNameToNum(hQuery,"created_at") >= 0) { SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"created_at"), Buffer[mC_szCreated_at], charsmax(Buffer[mC_szCreated_at])); }
		if (SQL_FieldNameToNum(hQuery,"creator_name") >= 0) { SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"creator_name"), Buffer[mC_szCreatorName], charsmax(Buffer[mC_szCreatorName])); }
		DebugPrintLevel(0, "Loaded course: CourseID #%d Name:%s Description:%s Legacy:%d Difficulty:%d Active:%d Flags:%d Created_at:%s CreatorID:%d CreatorName:%s",
			Buffer[mC_sqlCourseID], Buffer[mC_szCourseName], Buffer[mC_szCourseDescription],
			Buffer[mC_bLegacy], Buffer[mC_iDifficulty], Buffer[mC_bSQLActive], Buffer[mC_szGoalTeams],
			Buffer[mC_szCreated_at], Buffer[mC_iCreatorID], Buffer[mC_szCreatorName]
		);
		api_registercourse(Buffer);
		SQL_NextRow(hQuery);
	}
	new szMapname[64]; get_mapname(szMapname, charsmax(szMapname));
	new szQuery[512]; formatex(szQuery, charsmax(szQuery), sql_loadcps, szMapname);
	api_SQLAddThreadedQuery(szQuery, "Handle_QueryLoadCheckpoints", QUERY_NOT_DISPOSABLE, PRIORITY_HIGHEST);
}
public Handle_QueryLoadCheckpoints(iFailState, Handle:hQuery, sError[], iError, Data[], iLen, Float:fQueueTime, iQueryIdent) {
    if(SQLCheckThreadedError(iFailState, hQuery, sError, iError)) { 
        DebugPrintLevel(0, "Failed to insert course into database: %s", sError);
    }
    new Buffer[eCheckPoints_t];
    while (SQL_MoreResults(hQuery)) {
        if (SQL_FieldNameToNum(hQuery,"course_id") >= 0) { Buffer[mCP_sqlCourseID] = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"course_id")); }
        if (SQL_FieldNameToNum(hQuery,"x") >= 0) { SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"x"),Buffer[mCP_fOrigin][0]); }
        if (SQL_FieldNameToNum(hQuery,"y") >= 0) { SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"y"),Buffer[mCP_fOrigin][1]); }
        if (SQL_FieldNameToNum(hQuery,"z") >= 0) { SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"z"),Buffer[mCP_fOrigin][2]); }
        if (SQL_FieldNameToNum(hQuery,"checkpoint_type") >= 0) { Buffer[mCP_iType] = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"checkpoint_type")); }
    	api_registercheckpoint(Buffer);
        SQL_NextRow(hQuery);
    }
    api_spawnallcourses(); // only called ONCE because it iterated through all cps already for the

    if (!g_bLegacyFound) {
        DebugPrintLevel(0, "No legacy course found in the database, loading from file...");
        api_legacycheck();
    }


}
public player_connect(id)
{
    g_bInRequest[id] = false;
    g_iRequestFor[id] = -1;
    g_iRequest[id] = 0;

}
public player_disconnected(id)
{
    g_bInRequest[id] = false;
    g_iRequestFor[id] = -1;
    g_iRequest[id] = 0;
}   
public cmd_oldstatsme(id) {
    define_inrequest
    sql_requestoldstats(id, id);
}

public menu_deploy(id) {
    new iCurrentRequest = g_iRequest[id];
    new szMenu[128]; formatex(szMenu, charsmax(szMenu), "\\y%s\\d\n\nChoose a player:", g_szRequest[iCurrentRequest]);
    new menu = menu_create( szMenu, "skillsmenu_clicked" );
    new szName[ 32 ], szTempid[ 10 ];
    new szMenuStr[32];
    for (new i = 1; i <= get_maxplayers(); i++)
    {
        if (is_connected_user(i)) {
        get_user_name( i, szName, 31 );
        num_to_str( i, szTempid, 9 );
        //formatex(szMenuStr, charsmax(szMenuStr), "\\y%s\\d.\\w %s\n", szTempid, szName);
        formatex(szMenuStr, charsmax(szMenuStr), "\\w %s\n", szName); 
        menu_additem( menu, szMenuStr, szTempid, 0 );
        }
    }
    menu_display( id, menu ); //time out after 60 seconds
    return PLUGIN_HANDLED;
}
public skillsmenu_clicked( const id, const menu, const item )
{
    if( item == MENU_EXIT )
    {
        menu_destroy( menu );
        return PLUGIN_HANDLED;
    }

    new data[ 6 ], iName[ 64 ];
    new access, callback;
    menu_item_getinfo( menu, item, access, data,5, iName, 63, callback );

    new tempid = str_to_num( data );
    if( !is_user_bot( tempid ) ) {
        new szName[32]; get_user_name( tempid, szName, 31 );
        //case according to the actions in this plugin
        switch(g_iRequest[id]) {
            case 0: //old stats
            {
                sql_requestoldstats(tempid,id);
            }
               
        }
    }

    menu_destroy( menu );
    return PLUGIN_HANDLED;
}
public sql_requestoldstats(id, id2) {
    new szRunsTable[128]; get_pcvar_string(g_pCvarOldRuns, szRunsTable, charsmax(szRunsTable));
    new szRanksTable[128]; get_pcvar_string(g_pCvarOldRanks, szRanksTable, charsmax(szRanksTable));

    new szSteamID[32]; get_user_authid(id, szSteamID, charsmax(szSteamID));
    new szQuery[1024]; formatex(szQuery, charsmax(szQuery), sql_oldStatsme,szRanksTable,szRanksTable,szRunsTable,szRunsTable,szRunsTable,szRanksTable, szSteamID);
    //write_file("debug.txt", szQuery);
    g_bInRequest[id] = true;
    new sData[2]; sData[0] = id; sData[1] = id2;
    api_SQLAddThreadedQuery(szQuery, "Handle_QueryOldStatsme", QUERY_NOT_DISPOSABLE, PRIORITY_NORMAL, sData, 2);  
    client_print(id, print_console, g_szPleaseWait);    
}
public Handle_QueryOldStatsme(iFailState, Handle:hQuery, sError[], iError, Data[], iLen, Float:fQueueTime, iQueryIdent) {
	new id; if (iLen > 0) { id = Data[0]; }                                             // Get the player id (whose stats we are requesting)
	new id2; if (iLen > 1) { id2 = Data[1]; }                                           // Get the player id (for the display_motd)
	if (!is_connected_user(id2)) { g_bInRequest[id] = false; return PLUGIN_HANDLED; }   // If the player is not connected anymore, return
	define_sql_error                                                                    // Check for SQL errors
	if (SQL_NumResults(hQuery) == 0) { client_print(id, print_console, g_szNoData); g_bInRequest[id] = false; return PLUGIN_HANDLED; } // If no data is found, return
	
	send_motd(id2, "<<<================= [ LEGACY STATS ] =================>>>\n\n");
	new szSteamID[32];
	while(SQL_MoreResults(hQuery))
	{
		//dump for debugging purposes
		dump_sqldata(hQuery);
		new iFieldNumSteamID = SQL_FieldNameToNum(hQuery,"steamId");
		new iFieldNumPrimaryRank = SQL_FieldNameToNum(hQuery,"primaryRank");
		new iFieldNumNFinnished = SQL_FieldNameToNum(hQuery,"nFinnished");
		new iFieldNumPosition = SQL_FieldNameToNum(hQuery,"position");
		new iFieldNumPosMax = SQL_FieldNameToNum(hQuery,"posmax");
		new iFieldNumMapFinishes = SQL_FieldNameToNum(hQuery,"mapFinishes");
		if (iFieldNumSteamID >= 0 && iFieldNumPrimaryRank >= 0 && iFieldNumNFinnished >= 0 && iFieldNumPosition >= 0 && iFieldNumPosMax >= 0 && iFieldNumMapFinishes >= 0) {
			SQL_ReadResult(hQuery, iFieldNumSteamID, szSteamID, charsmax(szSteamID));
			new szPrimaryRank[32]; SQL_ReadResult(hQuery, iFieldNumPrimaryRank, szPrimaryRank, charsmax(szPrimaryRank));
			new szNFinnished[32]; SQL_ReadResult(hQuery, iFieldNumNFinnished, szNFinnished, charsmax(szNFinnished));
			new szPosition[32]; SQL_ReadResult(hQuery, iFieldNumPosition, szPosition, charsmax(szPosition));
			new szPosMax[32]; SQL_ReadResult(hQuery, iFieldNumPosMax, szPosMax, charsmax(szPosMax));
			new szMapFinishes[32]; SQL_ReadResult(hQuery, iFieldNumMapFinishes, szMapFinishes, charsmax(szMapFinishes));
			send_motd(id2, "Their average difficulty of finished maps = %s\n",szPrimaryRank);
			send_motd(id2, "They were on place [%s] of [%s] ubers.\nHarder maps = more uber :)\n",szPosition,szPosMax);
			send_motd(id2, "They finished [%s] maps, the most finished map is [%s] times finished.\n",szNFinnished,szMapFinishes);
		}
		SQL_NextRow(hQuery);
	}
	send_motd(id2, "\n\nStats up to july 2023\nsee all legacy stats at http://stats.skillzworld.eu")
	display_motd(id2,"Legcy stats for %s",szSteamID);
	g_bInRequest[id] = false;
	return PLUGIN_HANDLED;
}
public cmd_oldtop5(id) {
    define_inrequest
    new szRunsTable[64]; get_pcvar_string(g_pCvarOldRanks, szRunsTable, charsmax(szRunsTable));
    new szQuery[256]; formatex(szQuery, charsmax(szQuery), "SELECT nickNames, primaryRank,nFinnished FROM %s WHERE nFinnished>=100 ORDER BY primaryRank DESC LIMIT 10", szRunsTable);
    g_bInRequest[id] = true;
    new sData[2]; sData[0] = id; sData[1] = 1;
    api_SQLAddThreadedQuery(szQuery, "Handle_QueryOldTop5", QUERY_NOT_DISPOSABLE, PRIORITY_NORMAL, sData, 2);
    client_print(id, print_console, g_szPleaseWait);

}

public sql_getoldtop_highrank(id) {
    new szRunsTable[64]; get_pcvar_string(g_pCvarOldRanks, szRunsTable, charsmax(szRunsTable));
    new szQuery[256]; formatex(szQuery, charsmax(szQuery), "SELECT nickNames, primaryRank FROM %s ORDER BY `primaryRank` DESC LIMIT 10", szRunsTable);
    new sData[2]; sData[0] = id; sData[1] = 2;
    api_SQLAddThreadedQuery(szQuery, "Handle_QueryOldTop5", QUERY_NOT_DISPOSABLE, PRIORITY_NORMAL, sData, 2);

}
public sql_getoldtop_mapcount(id) {
    new szRunsTable[64]; get_pcvar_string(g_pCvarOldRanks, szRunsTable, charsmax(szRunsTable));
    new szQuery[256]; formatex(szQuery, charsmax(szQuery), "SELECT * FROM %s ORDER BY `nFinnished` DESC LIMIT 10", szRunsTable);
    new sData[2]; sData[0] = id; sData[1] = 3;
    api_SQLAddThreadedQuery(szQuery, "Handle_QueryOldTop5", QUERY_NOT_DISPOSABLE, PRIORITY_NORMAL, sData, 2);
}

public Handle_QueryOldTop5(iFailState, Handle:hQuery, sError[], iError, Data[], iLen, Float:fQueueTime, iQueryIdent)
{
	new id; if (iLen > 0) { id = Data[0]; }                                     // Get the player id
	new iState; if (iLen > 1) { iState = Data[1]; }                             // Get the state (1 = UBER, 2 = Highrank)
	define_sql_error
	
	switch (iState) {
	case 3: {
		send_motd(id, "\n<<<================= [ MOST FINISHED MAPS ] =================>>>\n"); 
		if (SQL_NumResults(hQuery) == 0) { send_motd(id, "No map data available.\n");  } 
		new iCount = 1;
		while(SQL_MoreResults(hQuery))
		{
			new szNickNames[256]; new nFinnished;
			SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"nickNames"), szNickNames, charsmax(szNickNames));
			nFinnished = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"nFinnished"));
			send_motd(id, "%i. %s = %d maps\n", iCount, szNickNames, nFinnished);
			iCount++;
		}    
		display_motd(id, "Old statistics up to july 2023")  
		g_bInRequest[id] = false;
	} case 2: {
		send_motd(id, "\n<<<================= [ HIGHRANKS ] =================>>>\n"); 
		if (SQL_NumResults(hQuery) == 0) { send_motd(id, "No Highranks data available.\n");  } 
		new iCount = 1;
		while(SQL_MoreResults(hQuery)) {
			new szNickNames[256]; new iPrimaryRank;
			SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"nickNames"), szNickNames, charsmax(szNickNames));
			iPrimaryRank = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"primaryRank"));
			send_motd(id, "%i. %s = %d avg. points\n", iCount, szNickNames, iPrimaryRank);
			iCount++;
			SQL_NextRow(hQuery);
		}
		sql_getoldtop_mapcount(id);
	} case 1: {
		send_motd(id, "<<<================= [ UBERS ] =================>>>\n");
		if (SQL_NumResults(hQuery) == 0) { send_motd(id, "No UBER data available.\n");  } 
		new iCount = 1;
		while(SQL_MoreResults(hQuery))
		{
			new szNickNames[256]; new iPrimaryRank; new iFinnished;
			SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"nickNames"), szNickNames, charsmax(szNickNames));
			iPrimaryRank = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"primaryRank"));
			iFinnished = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"nFinnished"));
			send_motd(id, "%i. %s = %d avg. points (%d maps finished)\n", iCount, szNickNames, iPrimaryRank,iFinnished);
			iCount++;
			SQL_NextRow(hQuery);
		}
		sql_getoldtop_highrank(id);
	}}
	return PLUGIN_HANDLED
}

stock dump_sqldata(Handle:hQuery) {
        new iColumns = SQL_NumColumns(hQuery); 
        DebugPrintLevel(0, "---------------------------------\nSQL_NumResults: %d", SQL_NumResults(hQuery));
        if (iColumns == 0) { DebugPrintLevel(0, "No columns found."); return; }
        new szColumns[256];
        for(new i = 0; i < iColumns; i++)
        {
            SQL_FieldNumToName(hQuery, i, szColumns, charsmax(szColumns));
            new szValue[256];
            SQL_ReadResult(hQuery, i, szValue, charsmax(szValue));
            DebugPrintLevel(0, "Column %d (%s) = %s", i, szColumns, szValue);  
        }
        DebugPrintLevel(0, "---------------------------------");
}


public SQLNative_InsertCourse(Data[]) {
    new Buffer[eCourseData_t];
    get_array(1, Buffer, sizeof(Buffer));
    new szCourseName[MAX_COURSE_NAME]; new szCourseDescription[MAX_COURSE_DESCRIPTION]; new iNumCheckpoints; new iDifficulty; new bool:bLegacy; new iCreatorID;
    if (strlen(Buffer[mC_szCourseName]) == 0) { formatex(szCourseName, charsmax(szCourseName), "Unknown"); } else { formatex(szCourseName, charsmax(szCourseName), Buffer[mC_szCourseName]); }
    if (strlen(Buffer[mC_szCourseDescription]) == 0) { formatex(szCourseDescription, charsmax(szCourseDescription), "No description provided."); } else { formatex(szCourseDescription, charsmax(szCourseDescription), Buffer[mC_szCourseDescription]); }
    iDifficulty = Buffer[mC_iDifficulty]; if (iDifficulty < 0) { iDifficulty = 0; } else if (iDifficulty > 100) { iDifficulty = 100; }
    iCreatorID = Buffer[mC_iCreatorID]; if (iCreatorID < -1) { iCreatorID = -1; }
    bLegacy = Buffer[mC_bLegacy];
    new iFlags = 0;
    if (containi(Buffer[mC_szGoalTeams],"B") >= 0) { iFlags |= SRFLAG_TEAMBLUE; }
    if (containi(Buffer[mC_szGoalTeams],"R") >= 0) { iFlags |= SRFLAG_TEAMRED; }
    if (containi(Buffer[mC_szGoalTeams],"G") >= 0) { iFlags |= SRFLAG_TEAMGREEN; }
    if (containi(Buffer[mC_szGoalTeams],"Y") >= 0) { iFlags |= SRFLAG_TEAMYELLOW; }

    new szMapname[64]; get_mapname(szMapname, charsmax(szMapname));
    new szPreQuery[1024]; formatex(szPreQuery, charsmax(szPreQuery), sql_insertmap, szMapname); // insert map if it doesn't exist
    new szQuery[1024]; formatex(szQuery, charsmax(szQuery), sql_insertcourse, szMapname, iCreatorID, szCourseName, szCourseDescription, bLegacy, iDifficulty, 1, iFlags);
    new szFinalQuery[1024]; formatex(szFinalQuery, charsmax(szFinalQuery), "%s %s", szPreQuery, szQuery);
    write_file("debug.txt", szFinalQuery);
    api_SQLAddThreadedQuery(szFinalQuery, "Handle_QueryInsertCourse", QUERY_NOT_DISPOSABLE, PRIORITY_NORMAL);
}   //http://database.gruk.io:9000/index.php
public Handle_QueryInsertCourse(iFailState, Handle:hQuery, sError[], iError, Data[], iLen, Float:fQueueTime, iQueryIdent)
{
    if(SQLCheckThreadedError(iFailState, hQuery, sError, iError)) { 
        DebugPrintLevel(0, "Failed to insert course into database: %s", sError);
    }

    return PLUGIN_HANDLED;
}

public SQLNative_InsertLegacyCPs( Data[] ) {
    new Buffer[eCheckPoints_t];
    get_array(1, Buffer, sizeof(Buffer));
    //prepare the query
    //new const sql_insertlegacycps[] = "INSERT INTO checkpoints(course_id, x, y, z, checkpoint_type) VALUES ( (SELECT c.id FROM courses c JOIN maps m ON m.id = c.map_id WHERE m.name = '%s' AND c.legacy = TRUE), %f, %f, %f, %f);"
    //get mapname
    new szMapname[64]; get_mapname(szMapname, charsmax(szMapname));
    new Float:x, Float:y, Float:z; x = Buffer[mCP_fOrigin][0]; y = Buffer[mCP_fOrigin][1]; z = Buffer[mCP_fOrigin][2];
    new szQuery[1024]; formatex(szQuery, charsmax(szQuery), sql_insertlegacycps, szMapname, x, y, z, Buffer[mCP_iType]);
    api_SQLAddThreadedQuery(szQuery, "Handle_QueryInsertLegacyCPs", QUERY_NOT_DISPOSABLE, PRIORITY_NORMAL);
}

public Handle_QueryInsertLegacyCPs(iFailState, Handle:hQuery, sError[], iError, Data[], iLen, Float:fQueueTime, iQueryIdent) {
    if(SQLCheckThreadedError(iFailState, hQuery, sError, iError)) { 
        DebugPrintLevel(0, "Failed to insert course into database: %s", sError);
    }

    return PLUGIN_HANDLED;
}
public SQLNative_InsertRun(iPluign, iParams) {
	new id = get_param(1); new Float:fTime = get_param_f(2); new course = get_param(3); new iCpsUsed = get_param(4);
	if (course <= 0) { DebugPrintLevel(0,"SQLNative_InsertRun <= 0 exception (course was %d)", course); return; }
	new szSteamID[32]; get_user_authid(id, szSteamID, charsmax(szSteamID));
	new iClass = pev(id,pev_playerclass);
	//requires %d/courseid %f/runtime %d/class %s/steamid
	//new const sql_insertrunquery[] = "INSERT INTO runs (course_id, player_id, time, player_class) SELECT %d, players.id, %f, %d FROM players WHERE players.steamid = %s;"
	new szQuery[1024]; formatex(szQuery, charsmax(szQuery), sql_insertrunquery, course, fTime, iClass, iCpsUsed, szSteamID);
	api_SQLAddThreadedQuery(szQuery, "Handle_QueryInsertRun", QUERY_NOT_DISPOSABLE, PRIORITY_NORMAL);

	// check if run is the best run for this map

	new bool:bIsBestRun = false;
	if ((ArraySize(g_TopList) == 0) && (fTime > 0.0)) { bIsBestRun = true; }
	else if (fTime > 0.0) {
		new Buffer[eSpeedTop_t]; ArrayGetArray(g_TopList,0,Buffer);
		new Float:fBestTime = Buffer[m_fTime];
		if (fTime < fBestTime) { bIsBestRun = true; }
	}

	if (bIsBestRun) { // announce to server
		new szPlayerName[32]; get_user_name(id, szPlayerName, charsmax(szPlayerName));
		new sTime[32]; formatex(sTime, charsmax(sTime), "%02d:%02d.%02d", floatround(fTime /60.0, floatround_floor), floatround(fTime, floatround_floor) % 60, floatround(fTime*100.0, floatround_floor) % 100);
		new szMessage[128]; formatex(szMessage, charsmax(szMessage), "New record by %s with a time of %s!",  szPlayerName, sTime);
		client_print(0, print_chat, szMessage);
		client_cmd(0,"play %s",RECORD_SOUND);
		api_firework(id, 3);
	}

}
public Handle_QueryInsertRun(iFailState, Handle:hQuery, sError[], iError, Data[], iLen, Float:fQueueTime, iQueryIdent) {
	if(SQLCheckThreadedError(iFailState, hQuery, sError, iError)) { 
		DebugPrintLevel(0, "Failed to insert run into database: %s", sError);
	}
	//reload the top list
	ArrayDestroy(g_TopList);
	g_TopList = ArrayCreate(eSpeedTop_t);
	g_iTopCount = 0;
	sql_loadruns();

	ArrayDestroy(g_GroupedTopList);
	g_GroupedTopList = ArrayCreate(eSpeedTop_t);
	g_iGroupedTopCount = 0;
	sql_loadgroupedruns();

	return PLUGIN_HANDLED;
}

public sql_loadruns() {
    new szMapName[64]; get_mapname(szMapName, charsmax(szMapName));
    new szQuery[1024]; formatex(szQuery, charsmax(szQuery), sql_getrunsformap, szMapName);
    api_SQLAddThreadedQuery(szQuery, "Handle_QueryLoadRuns", QUERY_NOT_DISPOSABLE, PRIORITY_NORMAL);
}

public Handle_QueryLoadRuns(iFailState, Handle:hQuery, sError[], iError, Data[], iLen, Float:fQueueTime, iQueryIdent) {
	if(SQLCheckThreadedError(iFailState, hQuery, sError, iError)) { 
		DebugPrintLevel(0, "Failed to load runs: %s", sError);
	}
	new Buffer[eSpeedTop_t];
	g_iTopCount = 0;    // plugin is now ready to process requests
	/*eSpeedTop_t*/
	while(SQL_MoreResults(hQuery)) {
		new iFieldNumSteamID = SQL_FieldNameToNum(hQuery,"steamid");
		new iFieldNumTime = SQL_FieldNameToNum(hQuery,"time");
		new iFieldNumClass = SQL_FieldNameToNum(hQuery,"player_class");
		new iFieldNumNickname = SQL_FieldNameToNum(hQuery,"most_used_nickname");
		new iFieldNumCourseID = SQL_FieldNameToNum(hQuery,"course_id");
		new iFieldNumID = SQL_FieldNameToNum(hQuery,"id");
		new iFieldNumCreatedAt = SQL_FieldNameToNum(hQuery,"created_at");
		new iFieldNumPlayerID = SQL_FieldNameToNum(hQuery,"player_id");
		if (iFieldNumSteamID == -1 || iFieldNumTime == -1 || iFieldNumClass == -1 || iFieldNumNickname == -1 || iFieldNumCourseID == -1 || iFieldNumID == -1 || iFieldNumCreatedAt == -1 || iFieldNumPlayerID == -1) {
			DebugPrintLevel(0, "Failed to load runs: %s", "Missing field in query");
			return PLUGIN_HANDLED;
		}
		//now load the data into the struct
		Buffer[m_iTopPlayerIdent] = SQL_ReadResult(hQuery, iFieldNumPlayerID);
		SQL_ReadResult(hQuery, iFieldNumSteamID, Buffer[m_sTopPlayerAuthid], charsmax(Buffer[m_sTopPlayerAuthid]));
		SQL_ReadResult(hQuery, iFieldNumNickname, Buffer[m_sTopPlayerName], charsmax(Buffer[m_sTopPlayerName]));
		SQL_ReadResult(hQuery, iFieldNumTime,Buffer[m_fTime]);
		Buffer[m_iCourseID] = SQL_ReadResult(hQuery, iFieldNumCourseID);
		SQL_ReadResult(hQuery, iFieldNumCreatedAt, Buffer[m_CreatedAt], charsmax(Buffer[m_CreatedAt]));
		Buffer[m_iPlayerClass] = SQL_ReadResult(hQuery, iFieldNumClass);
		//now add the run to the list
		ArrayPushArray(g_TopList, Buffer);
		g_iTopCount++;
		SQL_NextRow(hQuery);
	}

	return PLUGIN_HANDLED;
}

public sql_loadgroupedruns() {
    new szMapName[64]; get_mapname(szMapName, charsmax(szMapName));
    new szQuery[1024]; formatex(szQuery, charsmax(szQuery), sql_getgroupedrunsformap, szMapName);
    api_SQLAddThreadedQuery(szQuery, "Handle_QueryLoadGroupedRuns", QUERY_NOT_DISPOSABLE, PRIORITY_NORMAL);
}

public Handle_QueryLoadGroupedRuns(iFailState, Handle:hQuery, sError[], iError, Data[], iLen, Float:fQueueTime, iQueryIdent) {
	if(SQLCheckThreadedError(iFailState, hQuery, sError, iError)) { 
		DebugPrintLevel(0, "Failed to load runs: %s", sError);
	}
	new Buffer[eSpeedTop_t];
	g_iGroupedTopCount = 0;    // plugin is now ready to process requests
	/*eSpeedTop_t*/
	while(SQL_MoreResults(hQuery)) {
		new iFieldNumSteamID = SQL_FieldNameToNum(hQuery,"steamid");
		new iFieldNumTime = SQL_FieldNameToNum(hQuery,"time");
		new iFieldNumClass = SQL_FieldNameToNum(hQuery,"player_class");
		new iFieldNumNickname = SQL_FieldNameToNum(hQuery,"most_used_nickname");
		new iFieldNumCourseID = SQL_FieldNameToNum(hQuery,"course_id");
		new iFieldNumID = SQL_FieldNameToNum(hQuery,"id");
		new iFieldNumCreatedAt = SQL_FieldNameToNum(hQuery,"created_at");
		new iFieldNumPlayerID = SQL_FieldNameToNum(hQuery,"player_id");
		if (iFieldNumSteamID == -1 || iFieldNumTime == -1 || iFieldNumClass == -1 || iFieldNumNickname == -1 || iFieldNumCourseID == -1 || iFieldNumID == -1 || iFieldNumCreatedAt == -1 || iFieldNumPlayerID == -1) {
			DebugPrintLevel(0, "Failed to load runs: %s", "Missing field in query");
			return PLUGIN_HANDLED;
		}
		//now load the data into the struct
		Buffer[m_iTopPlayerIdent] = SQL_ReadResult(hQuery, iFieldNumPlayerID);
		SQL_ReadResult(hQuery, iFieldNumSteamID, Buffer[m_sTopPlayerAuthid], charsmax(Buffer[m_sTopPlayerAuthid]));
		SQL_ReadResult(hQuery, iFieldNumNickname, Buffer[m_sTopPlayerName], charsmax(Buffer[m_sTopPlayerName]));
		SQL_ReadResult(hQuery, iFieldNumTime,Buffer[m_fTime]);
		Buffer[m_iCourseID] = SQL_ReadResult(hQuery, iFieldNumCourseID);
		SQL_ReadResult(hQuery, iFieldNumCreatedAt, Buffer[m_CreatedAt], charsmax(Buffer[m_CreatedAt]));
		Buffer[m_iPlayerClass] = SQL_ReadResult(hQuery, iFieldNumClass);
		//now add the run to the list
		ArrayPushArray(g_GroupedTopList, Buffer);
		g_iGroupedTopCount++;
		SQL_NextRow(hQuery);
	}

	return PLUGIN_HANDLED;
}


//modified from fm / benwatch
public ShowTop(id, iStart, iEnd, bool:bOnlyPBs)
{
	new top_count, Array:top_list
	if (bOnlyPBs) {
		top_list  = g_GroupedTopList
		top_count = g_iGroupedTopCount
	} else {
		top_list = g_TopList
		top_count = g_iTopCount
	}
	
	if (!top_count) {
		client_print(id, print_chat, "* No players have completed a speedrun on the current map")
		return
	}
	
	/// Ensure that iStart is in range [0, g_iTopCount), iEnd is in [iStart+1, g_iTopCount]
	/// iEnd is exclusive, so iEnd-iStart is the amount of items and is in range [1, g_iTopCount]
	/// This mirrors the way Python slicing works, except that some elements may be filtered out.
	iStart = clamp(iStart, 0, top_count - 1)
	iEnd   = clamp(iEnd, iStart+1, top_count)
	///
	console_print 0, "ShowTop bounds: %d - %d", iStart, iEnd

	static sBuffer[1024]
	new sCurrentMap[MAX_MAP_LEN]; get_mapname(sCurrentMap, charsmax(sCurrentMap))
	send_motd(id,"Speedruns ranks %d to %d for map %s\n", iStart + 1, iEnd, sCurrentMap)
	new iClass = pev(id, pev_playerclass);
	send_motd(id, "\nCurrently only showing the runs for your player class: %s\n\n", g_szClassNames[iClass]);
	
	new iPlayerCourse = api_get_player_course(id)
	new szCourseName[MAX_COURSE_NAME]; api_get_coursename(iPlayerCourse, szCourseName, charsmax(szCourseName));
	send_motd(id, "[ %s course ]", szCourseName);

	// Bug: Viewing the leaderboard as spectator doesn't work because of the class filter
	console_print id, "Your course ID:%d", iPlayerCourse
	new TopInfo[eSpeedTop_t], iPos = iStart + 1;
	for(new i = iStart, iAcquired; i < iEnd && iAcquired < MAX_MOTD_RANKS && i < top_count; ) {
		ArrayGetArray(top_list, i, TopInfo)
		i++
		console_print id, "Course's SQLid:%d, run course id:%d, dude's class:%d, run class:%d", api_get_mysqlid_by_course(iPlayerCourse), TopInfo[m_iCourseID], iClass, TopInfo[m_iPlayerClass]
		if (api_get_course_mysqlid(iPlayerCourse) != TopInfo[m_iCourseID]) continue; //only show runs for the current course by comparing the course ids (the mysql ids!)
		if (iClass != TopInfo[m_iPlayerClass]) continue;
		new Float:fTime = TopInfo[m_fTime];
		new sTime[32]; formatex(sTime, charsmax(sTime), "%02d:%02d.%02d",
			floatround(fTime /60.0, floatround_floor),
			floatround(fTime, floatround_floor) % 60,
			floatround(fTime*100.0, floatround_floor) % 100
		);
		send_motd(id, "\n%3d. [%s] %s <%s> \ton %s", iPos++, sTime, TopInfo[m_sTopPlayerName], TopInfo[m_sTopPlayerAuthid], TopInfo[m_CreatedAt]);
		iAcquired++
	}

	if (iEnd != top_count) send_motd(id, "\n\nClose this window and type \"/top %d-%d\" to view the next %d", iStart+1, iStart+MAX_MOTD_RANKS, MAX_MOTD_RANKS)
	if (!bOnlyPBs) send_motd(id,"\nTo remove duplicate steamids say \"/gtop\"\n");
	display_motd(id, "Speedrun Ranks")
	return
}

public ShowMapstats(id) {
    new szMapname[64]; get_mapname(szMapname, charsmax(szMapname));
    send_motd(id, "<<<=========== [ Mapstats - %s ] ===========>>>\n\n", szMapname);
    new iNumCourses = api_get_number_courses();

    if (iNumCourses == 0) {
        send_motd(id, "No courses found for this map.\n");
    } else {
        send_motd(id, "Found %d courses for this map:\n", iNumCourses);
        //iterate through all courses
        for (new i = 0; i < iNumCourses; i++) {
            new szCourseName[64]; api_get_coursename(i+1, szCourseName, charsmax(szCourseName));
            new szCourseDesc[128]; api_get_coursedescription(i+1, szCourseDesc, charsmax(szCourseDesc));
            new iDiff = api_get_mapdifficulty(i+1);
            send_motd(id, "%d. %s\n   Description: %s\n   Difficulty: %d\n", i, szCourseName, szCourseDesc, iDiff); 

        }
    }
    new szSteamID[32]; get_user_authid(id, szSteamID, charsmax(szSteamID));
    //check if player has completed any courses by iterating through g_TopList
    new iNumCompletedCourses = 0;
    new Buffer[eSpeedTop_t];
    for (new i = 0; i < g_iTopCount; i++) {
        ArrayGetArray(g_TopList, i, Buffer);
        //compare steamids
        if (i == 0) {           //record the top player
            new szRunTime[64]; format_seconds(szRunTime, Buffer[m_fTime], charsmax(szRunTime)); 
            formatex(szRunTime, charsmax(szRunTime), "%s, %d milliseconds", szRunTime, floatround(Buffer[m_fTime]*1000.0, floatround_floor) % 1000);
            send_motd(id, "\nSpeedrun record set by %s <%s>\n >>> %s\n\n", Buffer[m_sTopPlayerName], Buffer[m_sTopPlayerAuthid], szRunTime);
        }
        if (equal(Buffer[m_sTopPlayerAuthid], szSteamID)) {
            iNumCompletedCourses++;
            if (iNumCompletedCourses == 1) {
                new Float:fTime = Buffer[m_fTime];
                new sTime[32]; formatex(sTime, charsmax(sTime), "%02d:%02d.%02d", floatround(fTime /60.0, floatround_floor), floatround(fTime, floatround_floor) % 60, floatround(fTime*100.0, floatround_floor) % 100);
                send_motd(id, "\nYour best time on this map is: %s (%s) currently we only have legacy courses enabled.\n", sTime, Buffer[m_CreatedAt]);
            }
        }
    }
    if (iNumCompletedCourses == 0) {
        send_motd(id, "No one has completed any courses on this map.\n");
    } else {
        send_motd(id, "You have %d runs on this map :)\n", iNumCompletedCourses);
    }
    display_motd(id, "Mapstats");

}
public Handle_Say(id)
{
	new sArgs[192]; read_args(sArgs, charsmax(sArgs))
	remove_quotes(sArgs)
	
	if (!sArgs[0]) return PLUGIN_HANDLED
	
	/// Support these commands: /top 10, /top10, /top10-20
	new bool:bWantsTop  = false
	new bool:bWantsGTop = false
	if       (equali(sArgs, "/top", 4)) bWantsTop = true
	else if (equali(sArgs, "/gtop", 5)) bWantsTop = bWantsGTop = true
	console_print 0, "Wants top"
	if (bWantsTop) {
		new iOffset
		new iStart = strtol(sArgs[bWantsGTop ? 5 : 4], .endPos = iOffset, .base = 10)
		if (!iStart) iStart = 10
		for (; sArgs[iOffset]; iOffset++) { // Skip whitespace and the hyphen
			if (sArgs[iOffset] == '-') {
				iOffset++
				break
			}
		}
		new iEnd = str_to_num(sArgs[iOffset])
		console_print 0, "Parsed numbers: %d - %d", iStart, iEnd
		// iStart is an index, iEnd is an exclusive endpoint
		if (iEnd) ShowTop id, iStart - 1, iEnd, bWantsGTop // Of the format /top 10-20
		else       ShowTop id, 0, iStart, bWantsGTop        // Of the format /top 10 (which means 1-10)
		return PLUGIN_HANDLED
	}
	///
	
	if (equali(sArgs, "/mapstats", 9) || equali(sArgs, "/mapinfo", 8)) {			
		ShowMapstats(id);
		return PLUGIN_HANDLED
	} 
	
	if (equali(sArgs, "/diff", 5) || equali(sArgs, "/difficulty", 11)) {	
		new iInCourse = api_get_player_course(id);		
		new iDiff = api_get_mapdifficulty(iInCourse);
		new szCourseName[64]; api_get_coursename(iInCourse, szCourseName, charsmax(szCourseName));
		new szString[128]; formatex(szString, charsmax(szString), "* The difficulty for the course [%s] is %d", szCourseName, iDiff);
		client_print(id, print_chat, szString);
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}
