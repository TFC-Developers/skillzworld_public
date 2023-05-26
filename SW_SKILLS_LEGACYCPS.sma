/* 
 *  Plugin:
 *  This plugin is part of the skillsrun functionality.
 *  Author: MrKoala & Ilup
    *  Version: 1.0
    *  Description: 
 *
 * 	Changelog:  
 *     16.05.2023 Initial release: This plugin will load the checkpoints from a file and spawn them in the world.
*/

#include "include/global"
#include "include/api_skills_mapentities"   // include file belonging to this plugin
#include "include/api_skills_mysql"         // include file belonging the plugin SW_SKILLS_MYSQL
#include <engine>
#include <fakemeta>
#include "include/utils"
#include <file>



/* 
 * 	global variables
*/

new Array: g_Checkpoints = Invalid_Array;                  // array to store the checkpoints
new Array: g_Courses = Invalid_Array;                      // array to store the courses
new g_iCPCount;                                            // number of checkpoints    
new g_iModelID;                                            // model id of the goal model   
new g_bWorldSpawned;                                       // true if the worldspawn entity has been spawned
new g_iPlayerInCourse[32];                                 //array to store the player's course id
new g_iLegacyCourse = -1;                                  //course id of the legacy course
new g_bHopMode = false;                                    //true if the map is in bhop mode
new g_iCvarBhopmode;                                   // Cvar for the bhopmode

/* 
 * 	Functions
*/

public plugin_natives() {
    register_native("api_get_mapdifficulty", "Native_GetMapDifficulty");  
    register_native("api_get_coursedescription", "Native_GetCourseDescription");
    register_native("api_get_coursename", "Native_GetCourseName");
    register_native("api_is_team_allowed", "Native_IsTeamAllowed");
    register_native("api_get_totalcps", "Native_GetTotalCPS");
    register_native("api_legacycheck", "Native_LegacyCheck");
    register_native("api_registercourse", "Native_RegisterCourse");
    register_native("api_registercheckpoint", "Native_RegisterCP");
    register_native("api_spawnallcourses", "Native_SpawnAllCourses");
    register_native("api_get_course_mysqlid", "Native_GetCourseMySQLID");
    register_native("api_get_number_courses", "Native_GetNumberCourses");
    register_native("api_get_player_course", "Native_GetPlayerCourse");
    register_native("api_process_mapflags", "Native_ProcessMapFlags");
    register_library("api_skills_mapentities");
    register_forward(FM_Spawn,"fm_spawn");
    g_bWorldSpawned = false;
    g_iCPCount = 0;
    g_Checkpoints = ArrayCreate(eCheckPoints_t);
    g_Courses = ArrayCreate(eCourseData_t);
}

public plugin_init() {
    RegisterPlugin();
    g_iCvarBhopmode = create_cvar("sw_bhopmode","0",FCVAR_EXTDLL);
}

public plugin_unload() {
    ArrayDestroy(g_Checkpoints);
    ArrayDestroy(g_Courses);
}   

public plugin_precache() {
    g_iModelID = precache_model(LEGACY_MODEL);
}

public client_putinserver(id) {
    DebugPrintLevel(0, "Client %d connected", id);
    set_task(4.0, "set_player_course", id);
    set_player_course(id, g_iLegacyCourse);
}
public client_disconnect(id) {
    g_iPlayerInCourse[id] = -1;
}

public set_player_course_connect(id) {          //nasty workaround to set the player's course after he has connected
    set_player_course(id, g_iLegacyCourse);
}
public set_player_course(id, course) {
    if (course <= 0) {
        return;
    }
    g_iPlayerInCourse[id] = course;
    //only print if team > 0 and < 5
    if (get_user_team(id) > 0 && get_user_team(id) < 5) {
        client_print(id, print_chat, "* You are now in course %d (%s)", course, get_course_name(course));
    }
}
public Native_ProcessMapFlags(iPlugin, iParams) {
    new iFlags = get_param(1); //get the mapflags
    if (iFlags & MAPFLAG_SURFMODE) {
        DebugPrintLevel(0, "Surfmode enabled");
        set_cvar_float("sv_airaccelerate", 100.0);
    } else {
        DebugPrintLevel(0, "Surfmode disabled");
        set_cvar_float("sv_airaccelerate", 10.0);
    }

    if (iFlags & MAPFLAG_BHOPMODE) {
        g_bHopMode = true;
    }
}
//called by mysql plugin after the database has been loaded
//and no legacy courses have been found
public Native_LegacyCheck() {
    parse_skillsconfig();
}
public Native_GetPlayerCourse(iPlugin, iParams) {
    new id = get_param(1);
    return g_iPlayerInCourse[id];
}
public fm_spawn(id) {
    if (g_bWorldSpawned) { return; } //worldspawn has already been spawned
    
    new szClassname[32]; entity_get_string(id, EV_SZ_classname, szClassname, charsmax(szClassname));
    if (equali(szClassname, "worldspawn")) {
        g_bWorldSpawned = true;
    }
}

//function to return the description of the course by its id
public get_course_description(id) {
    new iCount = ArraySize(g_Courses);
    new szDescription[MAX_COURSE_DESCRIPTION];
    new Buffer[eCourseData_t];
    formatex(szDescription, charsmax(szDescription), "__Unknown");

    for (new i = 0; i < iCount; i++) {
        ArrayGetArray(g_Courses, i, Buffer);
        if (Buffer[mC_iCourseID] == id) {
            formatex(szDescription, charsmax(szDescription), "%s", Buffer[mC_szCourseDescription]);
        }
    }
    return szDescription;
}
//function to return the description of the course by its id
public get_course_name(id) {
    new iCount = ArraySize(g_Courses);
    new szDescription[MAX_COURSE_NAME];
    new Buffer[eCourseData_t];
    formatex(szDescription, charsmax(szDescription), "__Unknown");

    for (new i = 0; i < iCount; i++) {
        ArrayGetArray(g_Courses, i, Buffer);
        if (Buffer[mC_iCourseID] == id) {
            formatex(szDescription, charsmax(szDescription), "%s", Buffer[mC_szCourseName]);
        }
    }
    return szDescription;
}
public parse_skillsconfig() {
    DebugPrintLevel(0, "Parsing skills config..");
    new mapname[32];  get_mapname(mapname, charsmax(mapname));                          // get the map name
    new filename[32]; formatex(filename, charsmax(filename), "skills/%s.cfg", mapname); // get the filename
    new path[128]; BuildAMXFilePath(filename, path, charsmax(path), "amxx_configsdir"); // get the full path to the file

    new tempCourseData[eCourseData_t];  // temp array to store the course data
    new Float:startCP[3];               // temp array to store the start checkpoint origin
    new Float:endCP[3];                 // temp array to store the end checkpoint origin
    new Array:tempCheckpoints = ArrayCreate(eCheckPoints_t);          // temp array to store the checkpoints
    new iTempMapFlags = 0;                                             // temp int to store the mapflags    

    //set the tempCourseData difficulty to -1
    tempCourseData[mC_iDifficulty] = -1;

    if (file_exists(path)) // check if the file exists
    {
        new szLineData[256], iLine       // line data and line number
        new file = fopen(path, "rt")    // open the file for reading

        if (!file) return;              // file could not be opened

        while (!feof(file))             // loop until the end of file
        {
            fgets(file, szLineData, charsmax(szLineData)); // read a line from the file            
            trim(szLineData);                              // remove spaces from the beginning and end of the string
            
            if (szLineData[0] == ';' || !szLineData[0] || szLineData[0] == '*') continue // skip comments and empty lines      

            new szKey[64], szValue[128];                                                 // key and value strings
            strtok2(szLineData, szKey, charsmax(szKey), szValue, charsmax(szValue));    // split the line into key and value

            //check if map is a surf map
            if (equali(szKey, "surfmode") || equali(szKey, "surfs")) {
                DebugPrintLevel(0, "Map is a surf map");
                iTempMapFlags |= MAPFLAG_SURFMODE;
            }

            //check wether the map is a bhop map
            if (equali(szKey, "bhops")) {
                DebugPrintLevel(0, "Map is a bhop map");
                iTempMapFlags |= MAPFLAG_BHOPMODE;
            }

            //check if key is "sv_difficulty" and set the difficulty
            if (equali(szKey, "sv_difficulty")) {
                tempCourseData[mC_iDifficulty] = str_to_num(szValue);
            }

            //check if the key is x_start and set the origin to startCP
            if (equali(szKey, "x_start")) {
                startCP[0] = str_to_float(szValue);
            }

            //check if the key is y_start and set the origin to startCP
            if (equali(szKey, "y_start")) {
                startCP[1] = str_to_float(szValue);
            }

            //check if the key is z_start and set the origin to startCP
            if (equali(szKey, "z_start")) {
                startCP[2] = str_to_float(szValue);
            }

            // check if the key is x_goal and set the origin to endCP
            if (equali(szKey, "x_goal")) {
                endCP[0] = str_to_float(szValue);
            }

            // check if the key is y_goal and set the origin to endCP
            if (equali(szKey, "y_goal")) {
                endCP[1] = str_to_float(szValue);
            }

            // check if the key is z_goal and set the origin to endCP
            if (equali(szKey, "z_goal")) {
                endCP[2] = str_to_float(szValue);
            }            

            //check if the key is sv_goalteams and set the goal teams
            if (equali(szKey, "sv_goalteams")) {
                formatex(tempCourseData[mC_szGoalTeams], charsmax(tempCourseData[mC_szGoalTeams]), "%s", szValue);
            }

            //check if key is skillcheckpoint and parse the checkpoint data
            if (equali(szKey, "skillcheckpoint")) {              
                new Float:tempOrigin[3]; 
                new szOriginValue[128];
                //split the value into three substrings and convert them to float
                strtok2(szValue, szOriginValue, charsmax(szOriginValue), szValue, charsmax(szValue));
                tempOrigin[0] = str_to_float(szOriginValue);

                strtok2(szValue, szOriginValue, charsmax(szOriginValue), szValue, charsmax(szValue));
                tempOrigin[1] = str_to_float(szOriginValue);

                strtok2(szValue, szOriginValue, charsmax(szOriginValue), szValue, charsmax(szValue));
                tempOrigin[2] = str_to_float(szOriginValue);

                new aCP[eCheckPoints_t];
                aCP[mCP_iID] = -1; //not set
                aCP[mCP_iType] = 1; //checkpoint
                aCP[mCP_iCourseID] = -1; //not set
                aCP[mCP_fOrigin] = tempOrigin;
                aCP[mCP_sqlCourseID] = -100;  //workaround for legacy courses

                //push to tempCheckpoints
                ArrayPushArray(tempCheckpoints, aCP);

            }

                       
            iLine++
        }
        
        DebugPrintLevel(0, "Parsed %d lines", iLine);

        // close the file
        fclose(file)

        //check if startCP is set by comparing the float values
        if (startCP[0] == 0.0 && startCP[1] == 0.0 && startCP[2] == 0.0) {
            DebugPrintLevel(0, "No start position found in file %s", path);
            ArrayDestroy(tempCheckpoints);
            return;
        }

        //check if endCP is set by comparing the float values
        if (endCP[0] == 0.0 && endCP[1] == 0.0 && endCP[2] == 0.0) {
            DebugPrintLevel(0, "No end position found in file %s", path);
            ArrayDestroy(tempCheckpoints);
            return;
        }

        //check if difficulty is set
        if (tempCourseData[mC_iDifficulty] == -1) {
            DebugPrintLevel(0, "No difficulty found in file %s", path);
            ArrayDestroy(tempCheckpoints);
            return;
        }

        //check if goal teams are set and set them to "BRGY" if not
        if (equal(tempCourseData[mC_szGoalTeams], "__Undefined")) {
            formatex(tempCourseData[mC_szGoalTeams], charsmax(tempCourseData[mC_szGoalTeams]), "BRGY");
        }

        formatex(tempCourseData[mC_szCourseName], charsmax(tempCourseData[mC_szCourseName]), "Legacy course");
        new szDate[32]; format_time(szDate, charsmax(szDate), "%d.%m.%Y %H:%M:%S", get_systime());
        formatex(tempCourseData[mC_szCourseDescription], charsmax(tempCourseData[mC_szCourseDescription]), "Legacy course imported into the database (%s)", szDate);

        tempCourseData[mC_iCreatorID] = -1;         //set the creator id to -1 (SYSTEM)
        tempCourseData[mC_bLegacy] = true;          //set the legacy flag to true
        tempCourseData[mC_iFlags] = 0;              //set the flags to 0
        tempCourseData[mC_sqlCourseID] = -100;     //workaround for legacy courses

        new iFlags = 0;
        if (containi(tempCourseData[mC_szGoalTeams],"B") >= 0) { iFlags |= SRFLAG_TEAMBLUE; }
        if (containi(tempCourseData[mC_szGoalTeams],"R") >= 0) { iFlags |= SRFLAG_TEAMRED; }
        if (containi(tempCourseData[mC_szGoalTeams],"G") >= 0) { iFlags |= SRFLAG_TEAMGREEN; }
        if (containi(tempCourseData[mC_szGoalTeams],"Y") >= 0) { iFlags |= SRFLAG_TEAMYELLOW; }
        tempCourseData[mC_iFlags] = iFlags; 

        new iNextCourseID = ArraySize(g_Courses);                   //get the next course id (if no course this is 0 or the amount of courses)
        tempCourseData[mC_iCourseID] = iNextCourseID + 1;           //set the course id to the next course id by adding 1 to the current amount of courses
        api_sql_insertcourse( tempCourseData );                     //insert the course into the database

        new aStartCP[eCheckPoints_t];                               //array to store the start cp
        aStartCP[mCP_iID] = -1;                                     //not set, will be set by push_checkpoint_array
        aStartCP[mCP_iType] = 0; //start                            //start (0 = start, 1 = checkpoint, 2 = finish)
        aStartCP[mCP_iCourseID] = tempCourseData[mC_iCourseID];     //course id
        aStartCP[mCP_fOrigin] = startCP;                            //origin
        aStartCP[mCP_sqlCourseID] = -100;                           //workaround for legacy courses
        api_sql_insertlegacycps( aStartCP );                        //insert the cp into the database

        new aEndCP[eCheckPoints_t];                                 //array to store the end cp
        aEndCP[mCP_iID] = -1;                                       //not set, will be set by push_checkpoint_array
        aEndCP[mCP_iType] = 2;                                      //finish (0 = start, 1 = checkpoint, 2 = finish)
        aEndCP[mCP_iCourseID] = tempCourseData[mC_iCourseID];       //course id
        aEndCP[mCP_fOrigin] = endCP;                                //origin
        aEndCP[mCP_sqlCourseID] = -100;                             //workaround for legacy courses  
        api_sql_insertlegacycps( aEndCP );                          //insert the cp into the database

        new iCount = ArraySize(tempCheckpoints);                    //get the number of checkpoints loaded from the file
        new Buffer[eCheckPoints_t];                                 //array to store the checkpoint data
        for (new i; i < iCount; i++) {                              //loop through the checkpoints loaded from the file
            ArrayGetArray(tempCheckpoints, i, Buffer);              //get the checkpoint data
            Buffer[mCP_iCourseID] = tempCourseData[mC_iCourseID]    //set the course id to the course id of the course
            api_sql_insertlegacycps( Buffer );                      //insert the cp into the database
        }
        ArrayDestroy(tempCheckpoints);                              //destroy the temp array
        api_sql_updatemapflags( iTempMapFlags );                    //update the map flags (if needed)
        api_sql_reloadcourses();                                    //reload the courses from the database
        
    }
} 

public push_checkpoint_array( Buffer[eCheckPoints_t], id ) {

    if (Buffer[mCP_iID] == -1) {
        g_iCPCount++;
        Buffer[mCP_iID] = g_iCPCount;
    }

    if (Buffer[mCP_iCourseID] == -1) {
        Buffer[mCP_iCourseID] = id;
    }
    DebugPrintLevel(0, "Pushing checkpoint %d (%f, %f, %f) of course %s to array", Buffer[mCP_iID], Buffer[mCP_fOrigin][0], Buffer[mCP_fOrigin][1], Buffer[mCP_fOrigin][2], get_course_name(id));
    api_sql_insertlegacycps( Buffer );
    ArrayPushArray(g_Checkpoints, Buffer);
}


public debug_coursearray() {
    new iCount = ArraySize(g_Courses);
    DebugPrintLevel(0, "Number of courses: %d", iCount);
    new Buffer[eCourseData_t];
    for (new i; i < iCount; i++) {
        ArrayGetArray(g_Courses, i, Buffer);
        DebugPrintLevel(0, "-------------------");
        DebugPrintLevel(0, "Course ID: %d", Buffer[mC_iCourseID]);
        DebugPrintLevel(0, "Course Name: %s", Buffer[mC_szCourseName]);
        DebugPrintLevel(0, "Course Description: %s", Buffer[mC_szCourseDescription]);
        DebugPrintLevel(0, "Difficulty: %d", Buffer[mC_iDifficulty]);
        DebugPrintLevel(0, "Goal Teams: %s", Buffer[mC_szGoalTeams]);
        DebugPrintLevel(0, "Number of Checkpoints: %d", Buffer[mC_iNumCheckpoints]);
        DebugPrintLevel(0, "Creator ID: %d", Buffer[mC_iCreatorID]);
        DebugPrintLevel(0, "Legacy: %d", Buffer[mC_bLegacy]);
        DebugPrintLevel(0, "Flags: %d", Buffer[mC_iFlags]);
        DebugPrintLevel(0, "Sql Active: %d", Buffer[mC_bSQLActive]);
        DebugPrintLevel(0, "Sql ID: %d", Buffer[mC_iCourseID]);
        DebugPrintLevel(0, "-------------------");
    }
}

/*
* Natives
*/

// native to get the map difficulty
public Native_RegisterCourse(iPlugin, iParams) {
    new Buffer[eCourseData_t];
    get_array(1, Buffer, eCourseData_t);
    //validate the data
    //if difficulty out of bounds (0-100) set to boundary
    if (Buffer[mC_iDifficulty] < 0) { Buffer[mC_iDifficulty] = 0; } else if (Buffer[mC_iDifficulty] > 100) { Buffer[mC_iDifficulty] = 100; }
    if (equal(Buffer[mC_szCourseName], "")) { formatex(Buffer[mC_szCourseName], charsmax(Buffer[mC_szCourseName]), "Undefined"); }
    if (equal(Buffer[mC_szCourseDescription], "")) { formatex(Buffer[mC_szCourseDescription], charsmax(Buffer[mC_szCourseDescription]), "Undefined"); }
    if (equal(Buffer[mC_szCreatorName], "")) { formatex(Buffer[mC_szCreatorName], charsmax(Buffer[mC_szCreatorName]), "SYSTEM"); }
    if (equal(Buffer[mC_szCreated_at], "")) { formatex(Buffer[mC_szCreated_at], charsmax(Buffer[mC_szCreated_at]), "<no time available>"); }
    new iNextCourseID = ArraySize(g_Courses);
    Buffer[mC_iCourseID] = (iNextCourseID + 1); 
    DebugPrintLevel(0, "Registering course [%s] with internal id %d, mysql id %d (flags: %d)", Buffer[mC_szCourseName], Buffer[mC_iCourseID], Buffer[mC_sqlCourseID], Buffer[mC_iFlags]);

    ArrayPushArray(g_Courses, Buffer);      //push the course to the array
}

public Native_RegisterCP(iPlugin, iParams) {
    new Buffer[eCheckPoints_t];
    get_array(1, Buffer, eCheckPoints_t);
    internal_register_cp(Buffer);
}

/* TO DO: if there is NO legacy course on a map then the player won't be able to participate in any course for now */
public Native_SpawnAllCourses() {

    new iCount = ArraySize(g_Courses);
    new Buffer[eCourseData_t];
    for (new i; i < iCount; i++) {
        ArrayGetArray(g_Courses, i, Buffer);

        if (Buffer[mC_bLegacy] == 1) {
            g_iLegacyCourse = Buffer[mC_iCourseID];

        } 
        DebugPrintLevel(0, "Legacy course is now: %s", get_course_name(g_iLegacyCourse));
        spawn_checkpoints_of_course(Buffer[mC_iCourseID]);
    }
    set_legacy_course_for_all();
}
public set_legacy_course_for_all() {
    if (g_iLegacyCourse >= 0) {
    //loop through all connected players and set course
    for (new j = 0; j < MAX_PLAYERS; j++) {
        if (is_connected_user(j)) {
            set_player_course(j, g_iLegacyCourse);
        } 
    }
}
}
public Native_GetMapDifficulty(iPlugin, iParams) {
    new iCourseID = get_param(1);  new iCount = ArraySize(g_Courses); new iDifficulty = 0; new Buffer[eCourseData_t];
    for (new i; i < iCount; i++) {
        ArrayGetArray(g_Courses, i, Buffer);
        if (Buffer[mC_iCourseID] == iCourseID) {
            iDifficulty = Buffer[mC_iDifficulty];
        }
    }
    return iDifficulty;
}

public Native_GetCourseDescription(iPlugin, iParams) {
    new id = get_param(1);
    new szReturn[MAX_COURSE_DESCRIPTION];
    formatex(szReturn, charsmax(szReturn), "__Undefined");

    new iCount = ArraySize(g_Courses);
    if (id > iCount) {
        return;
    }

    new Buffer[eCourseData_t];
    for (new i; i < iCount; i++) {
        ArrayGetArray(g_Courses, i, Buffer);
        if (Buffer[mC_iCourseID] == id) {
            formatex(szReturn, charsmax(szReturn), "%s", Buffer[mC_szCourseDescription]);
        }
    }
    set_string(2, szReturn, get_param(3));
}

public Native_GetCourseName(iIndex) {
    new id = get_param(1);
    new szReturn[MAX_COURSE_NAME];
    formatex(szReturn, charsmax(szReturn), "__Undefined");

    new iCount = ArraySize(g_Courses);
    if (id > iCount) {
        return;
    }

    new Buffer[eCourseData_t];
    for (new i; i < iCount; i++) {
        ArrayGetArray(g_Courses, i, Buffer);
        if (Buffer[mC_iCourseID] == id) {
            formatex(szReturn, charsmax(szReturn), "%s", Buffer[mC_szCourseName]);
        }
    }
    set_string(2, szReturn, get_param(3));
}

//native to return the total number of checkpoints for a given course
public Native_GetTotalCPS(iPlugin, iParams) {
    new id = get_param(1);
    new iCount = ArraySize(g_Checkpoints);
    new iTotal = 0;
    new Buffer[eCheckPoints_t];
    for (new i; i < iCount; i++) {
        ArrayGetArray(g_Checkpoints, i, Buffer);
        if (Buffer[mCP_iCourseID] == id && Buffer[mCP_iType] == 1) {
            iTotal++;
        }
    }
    return iTotal;
}

// native to check if a team is allowed to reach the goal
// called through api_is_team_allowed(playerid, cp_entid);
// params: playerid, cp_entid
public Native_IsTeamAllowed(iPluign, iParams) {
    new id = get_param(1);
    new startent = get_param(2);
    new result = false;
    new iCountCPs = ArraySize(g_Checkpoints);
    new iCourseID = -1;
    new Buffer[eCheckPoints_t];

    for (new i; i < iCountCPs; i++) {
        ArrayGetArray(g_Checkpoints, i, Buffer);
        if (Buffer[mCP_iEntID] == startent) {
            iCourseID = Buffer[mCP_iCourseID];          // get the course id of the checkpoint
            break;
        }
    }

    if (iCourseID == -1) {
        DebugPrintLevel(0, "[ERROR] Could not find course id for start checkpoint %d", startent);
        return false;
    }
    //get course Buffer instead of iterating through them
    new CourseBuffer[eCourseData_t];
    new iCountCourses = ArraySize(g_Courses);
    for (new i; i < iCountCourses; i++) {
        ArrayGetArray(g_Courses, i, CourseBuffer);
        if (CourseBuffer[mC_iCourseID] == iCourseID) {
            break;
        }
    }
    new iTeam = get_user_team(id);    
    if (CourseBuffer[mC_iFlags] & SRFLAG_TEAMBLUE && iTeam == 1) { result = true; }
    if (CourseBuffer[mC_iFlags] & SRFLAG_TEAMRED && iTeam == 2) { result = true; } 
    if (CourseBuffer[mC_iFlags] & SRFLAG_TEAMGREEN && iTeam == 4) { result = true; }
    if (CourseBuffer[mC_iFlags] & SRFLAG_TEAMYELLOW && iTeam == 3) { result = true; } 
    return result;
}

public Native_GetCourseMySQLID(iPluign, iParams)  {
    new id = get_param(1);
    new iCount = ArraySize(g_Courses);
    new Buffer[eCourseData_t];
    for (new i; i < iCount; i++) {
        ArrayGetArray(g_Courses, i, Buffer);
        if (Buffer[mC_iCourseID] == id) {  
            return Buffer[mC_sqlCourseID];
        }
    }
    return -1;
}

public Native_GetNumberCourses(iPlugin, iParams) {
    return ArraySize(g_Courses);
}
/*
* Spawn the entities
*/

//function: spawns a checkpoint
//params: checkpoint id

public spawn_checkpoint(id) {

    new Buffer[eCheckPoints_t];
    ArrayGetArray(g_Checkpoints, id, Buffer);
    //DebugPrintLevel(0, "Attempting to spawn checkpoint %d (%f, %f, %f) of course %s", Buffer[mCP_iID], Buffer[mCP_fOrigin][0], Buffer[mCP_fOrigin][1], Buffer[mCP_fOrigin][2], get_course_name(Buffer[mCP_iCourseID]));

    new entity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
    entity_set_string(entity, EV_SZ_classname, "sw_checkpoint");
    engfunc(EngFunc_SetModel, entity, LEGACY_MODEL);   
    
    new Float:origin[3]
    origin[0] = Buffer[mCP_fOrigin][0];
    origin[1] = Buffer[mCP_fOrigin][1];   
    origin[2] = Buffer[mCP_fOrigin][2];       //http://database.gruk.io:9000/index.php?route=/sql&pos=0&db=tfc_sw2023&table=courses
    
    switch( Buffer[mCP_iType] ) {
        case 0 : entity_set_int(entity, EV_INT_skin, 2)
        case 1 : entity_set_int(entity, EV_INT_skin, 3)
        default: entity_set_int(entity, EV_INT_skin, 1)
    }
    entity_set_vector(entity, EV_VEC_origin, origin);
    entity_set_vector(entity, EV_VEC_angles, Float:{0.0, 0.0, 0.0});
    entity_set_float(entity, EV_FL_nextthink, (get_gametime() + 0.1));  
    entity_set_int(entity, EV_INT_solid, SOLID_TRIGGER);
    entity_set_int(entity, EV_INT_rendermode, 5);
    entity_set_int(entity, EV_INT_renderfx, 0);
    entity_set_float(entity, EV_FL_renderamt, 255.0);
    entity_set_float(entity, EV_FL_framerate, 0.5);
    entity_set_int(entity, EV_INT_sequence, 0);	
    entity_set_float(entity, EV_FL_health, 100000.0); 

    entity_set_int(entity, EV_INT_iuser1, Buffer[mCP_iType]); //set the m_iCPType of the checkpoint (0 = start, 1 = checkpoint, 2 = finish)
    entity_set_int(entity, EV_INT_iuser2, Buffer[mCP_iCourseID]); //set the m_iCPCourseID of the checkpoint

    //set the m_iEntID of the checkpoint
    Buffer[mCP_iEntID] = entity;

    DebugPrintLevel(0, " -> Spawned checkpoint at %f, %f, %f (EntID: %d) of course #%d (%s)", origin[0], origin[1], origin[2], Buffer[mCP_iEntID], Buffer[mCP_iCourseID], get_course_name(Buffer[mCP_iCourseID]));

    ArraySetArray(g_Checkpoints, id, Buffer); //update the array
}

//function to spawn all checkpoints of a course
//params: course id
public spawn_checkpoints_of_course(id) { 
    new iCount = ArraySize(g_Checkpoints);
    new Buffer[eCheckPoints_t];
    new iTotal = 0;
    DebugPrintLevel(0, "Spawning checkpoints of course %s", get_course_name(id));
    for (new i; i < iCount; i++) {
        ArrayGetArray(g_Checkpoints, i, Buffer);
        if (Buffer[mCP_iCourseID] == id) {
            //DebugPrintLevel(0, "Spawning checkpoint %d of course %s", Buffer[mCP_iID], get_course_name(id));
            spawn_checkpoint(i);
            iTotal++;
        }
    }

    DebugPrintLevel(0, "Finished spawning checkpoints of course %s (total number of cps in course: %d)", get_course_name(id), iTotal);
}

public debug_list_all_cps_in_world() {
    new ent = -1;
    while ((ent = find_ent_by_class(ent,"sw_checkpoint"))) {
        new Float:origin[3];
        entity_get_vector(ent, EV_VEC_origin, origin);
        DebugPrintLevel(0, "Found Checkpoint at %f, %f, %f", origin[0], origin[1], origin[2]);
    }
}


public internal_register_cp( Buffer[eCheckPoints_t] ) {
      new CourseBuffer[eCourseData_t];                                    // temp array to store the course data
    new iCount = ArraySize(g_Courses);                                  // get the number of courses
    for (new i; i < iCount; i++) {                                      // loop through all courses
        ArrayGetArray(g_Courses, i, CourseBuffer);                      // get the course data^
        if (CourseBuffer[mC_sqlCourseID] == Buffer[mCP_sqlCourseID]) {     // if the sql course id matches
            Buffer[mCP_iCourseID] = CourseBuffer[mC_iCourseID];          // set the internal course id
        }
    }
    g_iCPCount++;
    Buffer[mCP_iID] = g_iCPCount;
    ArrayPushArray(g_Checkpoints, Buffer);
}
