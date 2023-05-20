
#include "include/global"
#include "include/sql_tquery"
#include <engine>
#include <fakemeta>
#include "include/utils"
#include "include/api_skills_mapentities"
#include "include/sql_dbqueries"

//global variables
new g_pCvarOldRanks; new g_pCvarOldRuns;            // Cvars for the old ranks and runs table
new bool:g_bInRequest[32];                          // Array to check if a player is already requesting data
new g_iRequestFor[32];                                 // Array to check for which player the request is
new g_iRequest[32];                                   // Array to check which request is being made 
//array of requests number => description
new const g_szRequest[3][32] = { "Retrieve legacy stats" };
//end global variables

//strings
new const g_szPleaseWait[] = "* Requesting data from database, please wait...";
new const g_szNoData[] = "* No data found in the database.";
new const g_szError[] = "* Failed to load the statistics from the database. Please try again later.";
new const g_szWait[] = "* Please wait for the previous request to finish.";
//end strings


#define define_inrequest { if(g_bInRequest[id]) { client_print(id, print_chat, g_szWait); return; } }
#define define_sql_error { if(SQLCheckThreadedError(iFailState, hQuery, sError, iError)) { client_print(id, print_chat, g_szError); g_bInRequest[id] = false; return PLUGIN_HANDLED; } }

public plugin_init()
{
    RegisterPlugin();
    register_clcmd("say /oldtop5", "cmd_oldtop5");                              // Shows the old top5
    register_clcmd("say /oldstatsme", "cmd_oldstatsme");                        // Shows the old stats of the player
    register_clcmd("say /oldstats", "menu_deploy");                             // Shows the old stats menu
	g_pCvarOldRanks = register_cvar("sw_sqloldranks", "climb_oldranks")         // Cvar for the old ranks table
	g_pCvarOldRuns = register_cvar("sw_sqloldruns", "climb_oldrunstable")       // Cvar for the old runs table
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
    /*		len1 += format(statsMotd[len1], 2047-len1,"Your average difficulty of finished maps = %s^n",qryRankPrimaryRank)
		len1 += format(statsMotd[len1], 2047-len1,"Your on place [%i] of [%i] ubers.^nHarder maps = more uber :)^n^n^n",playersUberPosition,nUbers)
        
DEBUG: [SW_SKILLS_MYSQL.amxx] Column 0 (steamId) = STEAM_0:0:438030
DEBUG: [SW_SKILLS_MYSQL.amxx] Column 1 (primaryRank) = 54
DEBUG: [SW_SKILLS_MYSQL.amxx] Column 2 (nFinnished) = 118
DEBUG: [SW_SKILLS_MYSQL.amxx] Column 3 (position) = 73
DEBUG: [SW_SKILLS_MYSQL.amxx] Column 4 (posmax) = 95
DEBUG: [SW_SKILLS_MYSQL.amxx] Column 5 (mapFinishes) = 115
DEBUG: [SW_SKILLS_MYSQL.amxx] Column 6 (mostMapFinishes) = 3097
*/
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

    if (iState == 3) {
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
        return PLUGIN_HANDLED;
    }
    if (iState == 2) {
        send_motd(id, "\n<<<================= [ HIGHRANKS ] =================>>>\n"); 
        if (SQL_NumResults(hQuery) == 0) { send_motd(id, "No Highranks data available.\n");  } 
        new iCount = 1;
        while(SQL_MoreResults(hQuery))
        {
            new szNickNames[256]; new iPrimaryRank;
            SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"nickNames"), szNickNames, charsmax(szNickNames));
            iPrimaryRank = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"primaryRank"));
            send_motd(id, "%i. %s = %d avg. points\n", iCount, szNickNames, iPrimaryRank);
            iCount++;
            SQL_NextRow(hQuery);
        }
        sql_getoldtop_mapcount(id);    
        return PLUGIN_HANDLED;
    }
    if (iState == 1) {
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
        return PLUGIN_HANDLED;
    }

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