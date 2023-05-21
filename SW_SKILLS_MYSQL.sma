
#include "include/api_skills_mysql"             // Include file for this plugin source
#include "include/global"                       // Include file for general functions
#include "include/sql_tquery"                   // Include file for threaded queries
#include <engine>
#include <fakemeta>
#include "include/utils"                        // Include file for utility functions
#include "include/sql_dbqueries"                // Include file for database queries (provides the strings)

//global variables
new g_pCvarOldRanks; new g_pCvarOldRuns;            // Cvars for the old ranks and runs table
new bool:g_bInRequest[32];                          // Array to check if a player is already requesting data
new g_iRequestFor[32];                                 // Array to check for which player the request is
new g_iRequest[32];                                   // Array to check which request is being made 
//array of requests number => description
new const g_szRequest[3][32] = { "Retrieve legacy stats", "","" };
//end global variables

//strings
new const g_szPleaseWait[] = "* Requesting data from database, please wait...";
new const g_szNoData[] = "* No data found in the database.";
new const g_szError[] = "* Failed to load the statistics from the database. Please try again later.";
new const g_szWait[] = "* Please wait for the previous request to finish.";
//end strings


#define define_inrequest { if(g_bInRequest[id]) { client_print(id, print_chat, g_szWait); return; } }
#define define_sql_error { if(SQLCheckThreadedError(iFailState, hQuery, sError, iError)) { client_print(id, print_chat, g_szError); g_bInRequest[id] = false; return PLUGIN_HANDLED; } }

public plugin_natives() {
    register_native("api_sql_insertcourse", "SQLNative_InsertCourse");
    register_native("api_sql_insertlegacycps", "SQLNative_InsertLegacyCPs");
    register_library("sw_sql_skills");
}

public plugin_init()
{
	RegisterPlugin();
	register_clcmd("say /oldtop5", "cmd_oldtop5");                              // Shows the old top5
	register_clcmd("say /oldstatsme", "cmd_oldstatsme");                        // Shows the old stats of the player
	register_clcmd("say /oldstats", "menu_deploy");                             // Shows the old stats menu
	g_pCvarOldRanks = register_cvar("sw_sqloldranks", "climb_oldranks")         // Cvar for the old ranks table
	g_pCvarOldRuns = register_cvar("sw_sqloldruns", "climb_oldrunstable")       // Cvar for the old runs table
}

// logic; sql_loadcourses -> api_registercourse 
//              |-done-> load all cps for map (done in Handle_QueryLoadCourses)                    
public plugin_precache() {
    sql_loadcourses();
}
//loads all courses from the database
public sql_loadcourses() {
    new szMapname[64]; get_mapname(szMapname, charsmax(szMapname));
    new szQuery[512]; formatex(szQuery, charsmax(szQuery), sql_selectcourses, szMapname);
    api_SQLAddThreadedQuery(szQuery, "Handle_QueryLoadCourses", QUERY_DISPOSABLE, PRIORITY_HIGHEST);
}

public Handle_QueryLoadCourses(iFailState, Handle:hQuery, sError[], iError, Data[], iLen, Float:fQueueTime, iQueryIdent) {
	if(SQLCheckThreadedError(iFailState, hQuery, sError, iError)) { 
		DebugPrintLevel(0, "Failed to insert course into database: %s", sError);
	}
	new Buffer[eCourseData_t];
	while (SQL_MoreResults(hQuery)) {
		dump_sqldata(hQuery);
        /*
DEBUG: [SW_SKILLS_MYSQL.amxx] Column 0 (id) = 19
DEBUG: [SW_SKILLS_MYSQL.amxx] Column 1 (map_id) = 1
DEBUG: [SW_SKILLS_MYSQL.amxx] Column 2 (creator_id) = -1
DEBUG: [SW_SKILLS_MYSQL.amxx] Column 3 (name) = Legacy course
DEBUG: [SW_SKILLS_MYSQL.amxx] Column 4 (description) = Legacy course imported into the database (20.05.2023 17:47:50)
DEBUG: [SW_SKILLS_MYSQL.amxx] Column 5 (legacy) = 1
DEBUG: [SW_SKILLS_MYSQL.amxx] Column 6 (difficulty) = 75
DEBUG: [SW_SKILLS_MYSQL.amxx] Column 7 (active) = 1
DEBUG: [SW_SKILLS_MYSQL.amxx] Column 8 (flags) = 14
DEBUG: [SW_SKILLS_MYSQL.amxx] Column 9 (created_at) = 2023-05-20 15:47:48
DEBUG: [SW_SKILLS_MYSQL.amxx] ---------------------------------
//this enum is used to store the course data parsed from file or
//from the mysql database
enum eCourseData_t 
{
    mC_iCourseID,                                    // [INTERNAL] course id
    mC_sqlCourseID,                                  // [SQL]      sql course id  (foreign key)
    mC_szCourseName[MAX_COURSE_NAME],                // [SQL]      course name (e.g. "Easy")
    mC_szCourseDescription[MAX_COURSE_DESCRIPTION],  // [SQL]      course description (e.g. "Easy")
    mC_iNumCheckpoints,                              // [INTERNAL] number of checkpoints
    mC_iDifficulty,                                  // [SQL]      difficulty (value between 0 - 100) if set to -1, the difficulty is not set
    mC_szGoalTeams[16],                              // [INTERNAL] teams that can reach the goal (e.g. "BRGY"), here for legacy reasons
    bool:mC_bLegacy,                                 // [SQL]      legacy course (true/false)
    mC_iCreatorID,                                   // [SQL]      creator id
    mC_iFlags,                                       // [SQL]      flags
    mC_szCreated_at[32],                             // [SQL]      creation date
    mC_bSQLActive,                                   // [SQL]      course flagged as active (true/false) in database
    mC_szCreatorName[32]                             // [SQL]      creator name
}

*/
		
		DebugPrintLevel(0, "1 -->: CourseID: %d CourseID #%d Name:%s", Buffer[mC_iCourseID], Buffer[mC_sqlCourseID], Buffer[mC_szCourseName]);
		if (SQL_FieldNameToNum(hQuery,"id") >= 0) { Buffer[mC_sqlCourseID] = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"id")); }
		DebugPrintLevel(0, "2 -->: CourseID: %d CourseID #%d Name:%s", Buffer[mC_iCourseID], Buffer[mC_sqlCourseID], Buffer[mC_szCourseName]);
		if (SQL_FieldNameToNum(hQuery,"creator_id") >= 0) { Buffer[mC_iCreatorID] = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"creator_id")); }
		DebugPrintLevel(0, "3 -->: CourseID: %d CourseID #%d Name:%s", Buffer[mC_iCourseID], Buffer[mC_sqlCourseID], Buffer[mC_szCourseName]);
		if (SQL_FieldNameToNum(hQuery,"name") >= 0) { SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"name"), Buffer[mC_szCourseName], charsmax(Buffer[mC_szCourseName])); }
		DebugPrintLevel(0, "4 -->: CourseID: %d CourseID #%d Name:%s", Buffer[mC_iCourseID], Buffer[mC_sqlCourseID], Buffer[mC_szCourseName]);
		if (SQL_FieldNameToNum(hQuery,"description") >= 0) { SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"description"), Buffer[mC_szCourseDescription], charsmax(Buffer[mC_szCourseDescription])); }
		if (SQL_FieldNameToNum(hQuery,"legacy") >= 0) { Buffer[mC_bLegacy] = bool:SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"legacy")); }
		if (SQL_FieldNameToNum(hQuery,"difficulty") >= 0) { Buffer[mC_iDifficulty] = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"difficulty")); }
		if (SQL_FieldNameToNum(hQuery,"active") >= 0) { Buffer[mC_bSQLActive] = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"active")); }
		if (SQL_FieldNameToNum(hQuery,"flags") >= 0) { Buffer[mC_szGoalTeams] = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"flags")); }
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
	//now load all cps for the map^
	//new const sql_loadcps[] = "SELECT cp.* FROM checkpoints cp JOIN courses c ON cp.course_id = c.id JOIN maps m ON m.id = c.map_id WHERE  m.name = '%s';"
	new szMapname[64]; get_mapname(szMapname, charsmax(szMapname));
	new szQuery[512]; formatex(szQuery, charsmax(szQuery), sql_loadcps, szMapname);
	api_SQLAddThreadedQuery(szQuery, "Handle_QueryLoadCheckpoints", QUERY_DISPOSABLE, PRIORITY_HIGHEST);
}
public Handle_QueryLoadCheckpoints(iFailState, Handle:hQuery, sError[], iError, Data[], iLen, Float:fQueueTime, iQueryIdent) {
    if(SQLCheckThreadedError(iFailState, hQuery, sError, iError)) { 
        DebugPrintLevel(0, "Failed to insert course into database: %s", sError);
    }
    new Buffer[eCheckPoints_t];
    while (SQL_MoreResults(hQuery)) {
        /*
DEBUG: [SW_SKILLS_MYSQL.amxx] Column 0 (id) = 47
DEBUG: [SW_SKILLS_MYSQL.amxx] Column 1 (course_id) = 19
DEBUG: [SW_SKILLS_MYSQL.amxx] Column 2 (x) = -669.169
DEBUG: [SW_SKILLS_MYSQL.amxx] Column 3 (y) = -843.361
DEBUG: [SW_SKILLS_MYSQL.amxx] Column 4 (z) = -3757.97
DEBUG: [SW_SKILLS_MYSQL.amxx] Column 5 (checkpoint_type) = 0
enum eCheckPoints_t
{
    mCP_iID,                      // [INTERNAL] checkpoint id
    mCP_iType,                    // [SQL]      checkpoint type (0 = start, 1 = checkpoint, 2 = finish)
    mCP_iCourseID,                // [INTERNAL] course id (foreign key)
    Float:mCP_fOrigin[3],           // [SQL]      checkpoint origin
    mCP_iEntID,                     // [INTERNAL] entity id
    mCP_sqlCourseID,                // [SQL]      sql course id (foreign key)
}
*/
        //fil the data
        if (SQL_FieldNameToNum(hQuery,"course_id") >= 0) { Buffer[mCP_sqlCourseID] = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"course_id")); }
        if (SQL_FieldNameToNum(hQuery,"x") >= 0) { SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"x"),Buffer[mCP_fOrigin][0]); }
        if (SQL_FieldNameToNum(hQuery,"y") >= 0) { SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"y"),Buffer[mCP_fOrigin][1]); }
        if (SQL_FieldNameToNum(hQuery,"z") >= 0) { SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"z"),Buffer[mCP_fOrigin][2]); }
        if (SQL_FieldNameToNum(hQuery,"checkpoint_type") >= 0) { Buffer[mCP_iType] = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"checkpoint_type")); }
        //DebugPrintLevel(0, "Loaded CP: CourseID #%d xyz:{%f, %f, %f} type:%d", Buffer[mCP_iCourseID], Buffer[mCP_fOrigin][0], Buffer[mCP_fOrigin][1], Buffer[mCP_fOrigin][2], Buffer[mCP_iType]);
    	api_registercheckpoint(Buffer);
        SQL_NextRow(hQuery);
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
    api_SQLAddThreadedQuery(szQuery, "Handle_QueryOldStatsme", QUERY_DISPOSABLE, PRIORITY_NORMAL, sData, 2);  
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
    api_SQLAddThreadedQuery(szQuery, "Handle_QueryOldTop5", QUERY_DISPOSABLE, PRIORITY_NORMAL, sData, 2);
    client_print(id, print_console, g_szPleaseWait);

}

public sql_getoldtop_highrank(id) {
    new szRunsTable[64]; get_pcvar_string(g_pCvarOldRanks, szRunsTable, charsmax(szRunsTable));
    new szQuery[256]; formatex(szQuery, charsmax(szQuery), "SELECT nickNames, primaryRank FROM %s ORDER BY `primaryRank` DESC LIMIT 10", szRunsTable);
    new sData[2]; sData[0] = id; sData[1] = 2;
    api_SQLAddThreadedQuery(szQuery, "Handle_QueryOldTop5", QUERY_DISPOSABLE, PRIORITY_NORMAL, sData, 2);

}
public sql_getoldtop_mapcount(id) {
    new szRunsTable[64]; get_pcvar_string(g_pCvarOldRanks, szRunsTable, charsmax(szRunsTable));
    new szQuery[256]; formatex(szQuery, charsmax(szQuery), "SELECT * FROM %s ORDER BY `nFinnished` DESC LIMIT 10", szRunsTable);
    new sData[2]; sData[0] = id; sData[1] = 3;
    api_SQLAddThreadedQuery(szQuery, "Handle_QueryOldTop5", QUERY_DISPOSABLE, PRIORITY_NORMAL, sData, 2);
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
    new szCourseName[MAX_COURSE_NAME]; new szCourseDescription[MAX_COURSE_DESCRIPTION]; new szGoalTeams[16]; new iNumCheckpoints; new iDifficulty; new bool:bLegacy; new iCreatorID;
    if (strlen(Buffer[mC_szCourseName]) == 0) { formatex(szCourseName, charsmax(szCourseName), "Unknown"); } else { formatex(szCourseName, charsmax(szCourseName), Buffer[mC_szCourseName]); }
    if (strlen(Buffer[mC_szCourseDescription]) == 0) { formatex(szCourseDescription, charsmax(szCourseDescription), "No description provided."); } else { formatex(szCourseDescription, charsmax(szCourseDescription), Buffer[mC_szCourseDescription]); }
    if (strlen(Buffer[mC_szGoalTeams]) <= 0) { formatex(szGoalTeams, charsmax(szGoalTeams), "BRGY"); } else { formatex(szGoalTeams, charsmax(szGoalTeams), Buffer[mC_szGoalTeams]); }
    iDifficulty = Buffer[mC_iDifficulty]; if (iDifficulty < 0) { iDifficulty = 0; } else if (iDifficulty > 100) { iDifficulty = 100; }
    iCreatorID = Buffer[mC_iCreatorID]; if (iCreatorID < -1) { iCreatorID = -1; }
    bLegacy = Buffer[mC_bLegacy];
    new iFlags = 0;
    if (containi(szGoalTeams,"B")) { iFlags |= SRFLAG_TEAMBLUE; }
    if (containi(szGoalTeams,"R")) { iFlags |= SRFLAG_TEAMRED; }
    if (containi(szGoalTeams,"G")) { iFlags |= SRFLAG_TEAMGREEN; }
    if (containi(szGoalTeams,"Y")) { iFlags |= SRFLAG_TEAMYELLOW; }
    new szMapname[64]; get_mapname(szMapname, charsmax(szMapname));
    new szPreQuery[1024]; formatex(szPreQuery, charsmax(szPreQuery), sql_insertmap, szMapname); // insert map if it doesn't exist
    new szQuery[1024]; formatex(szQuery, charsmax(szQuery), sql_insertcourse, szMapname, iCreatorID, szCourseName, szCourseDescription, bLegacy, iDifficulty, 1, iFlags);
    new szFinalQuery[1024]; formatex(szFinalQuery, charsmax(szFinalQuery), "%s %s", szPreQuery, szQuery);
    write_file("debug.txt", szFinalQuery);
    api_SQLAddThreadedQuery(szFinalQuery, "Handle_QueryInsertCourse", QUERY_DISPOSABLE, PRIORITY_NORMAL);
}
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
    api_SQLAddThreadedQuery(szQuery, "Handle_QueryInsertLegacyCPs", QUERY_DISPOSABLE, PRIORITY_NORMAL);
}

public Handle_QueryInsertLegacyCPs(iFailState, Handle:hQuery, sError[], iError, Data[], iLen, Float:fQueueTime, iQueryIdent) {
    if(SQLCheckThreadedError(iFailState, hQuery, sError, iError)) { 
        DebugPrintLevel(0, "Failed to insert course into database: %s", sError);
    }

    return PLUGIN_HANDLED;
}
