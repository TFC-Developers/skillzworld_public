
#include "include/global"
#include "include/sql_tquery"
#include <engine>
#include <fakemeta>
#include "include/utils"
#include "include/api_skills_mapentities"



new bool:g_bInRequest[32];

new const g_szOldRunsTable[] = "climb_oldrunstable";
new const g_szOldRunsRanktable[] = "climb_oldranks";
new const g_szPleaseWait[] = "* Requesting data from database, please wait...";
new const g_szNoData[] = "* No data found in the database.";
new const g_szError[] = "* Failed to load the statistics from the database. Please try again later.";
new const g_szWait[] = "* Please wait for the previous request to finish.";


#define define_inrequest { if(g_bInRequest[id]) { client_print(id, print_chat, g_szWait); return; } }
#define define_sql_error { if(SQLCheckThreadedError(iFailState, hQuery, sError, iError)) { client_print(id, print_console, g_szError); g_bInRequest[id] = false; return PLUGIN_HANDLED; } }

public plugin_init()
{
    RegisterPlugin();
    register_clcmd("say /oldtop5", "cmd_oldtop5"); // Shows the old top5 
}

public player_connect(id)
{
    g_bInRequest[id] = false;

}

public player_disconnected(id)
{
    g_bInRequest[id] = false;

}   

//will give top 10 anyways
public cmd_oldtop5(id) {
    define_inrequest
    /* old query: 	resultRanks = dbi_query(dbcSkills,"SELECT nickNames, primaryRank,nFinnished FROM `skillrank` WHERE nFinnished>=%i ORDER BY primaryRank DESC LIMIT 5",uberCount) */
    new szQuery[256]; formatex(szQuery, charsmax(szQuery), "SELECT nickNames, primaryRank,nFinnished FROM %s WHERE nFinnished>=100 ORDER BY primaryRank DESC LIMIT 10", g_szOldRunsRanktable);
    g_bInRequest[id] = true;
    new sData[2]; sData[0] = id; sData[1] = 1;

    api_SQLAddThreadedQuery(szQuery, "Handle_QueryOldTop5", QUERY_DISPOSABLE, PRIORITY_NORMAL, sData, 2);
    client_print(id, print_console, g_szPleaseWait);

}

public sql_getoldtop_highrank(id) {
    new szQuery[256]; formatex(szQuery, charsmax(szQuery), "SELECT nickNames, primaryRank FROM %s ORDER BY `primaryRank` DESC LIMIT 10", g_szOldRunsRanktable);
    new sData[2]; sData[0] = id; sData[1] = 2;
    api_SQLAddThreadedQuery(szQuery, "Handle_QueryOldTop5", QUERY_DISPOSABLE, PRIORITY_NORMAL, sData, 2);

}
public sql_getoldtop_mapcount(id) {
    new szQuery[256]; formatex(szQuery, charsmax(szQuery), "SELECT * FROM %s ORDER BY `nFinnished` DESC LIMIT 10", g_szOldRunsRanktable);
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
            SQL_NextRow(hQuery);
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

public show_hud(id) {

}