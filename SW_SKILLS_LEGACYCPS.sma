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
#include "include/api_skills_mapentities"
#include <engine>
#include <fakemeta>
#include "include/utils"
#include <file>

/* 
 * 	Defines
*/

#define MAX_CHECKPOINTS 2048 // max number of checkpoints
#define MAX_COURSES 128 // max number of courses
#define MAX_COURSE_NAME 32 // max length of the course name
#define MAX_COURSE_DESCRIPTION 64 // max length of the course description
#define LEGACY_MODEL "models/skillzworld/checkpoint2.mdl"

/* 
 * 	Structs
*/

//this enum is used to store the checkpoint data parsed from file or 
//from the mysql database
enum eCheckPoints_t
{
    m_iCPID,                      // checkpoint id
    m_iCPType,                    // checkpoint type (0 = start, 1 = checkpoint, 2 = finish)
    m_iCPCourseID,                // course id (foreign key)
    Float:m_fOrigin[3],           // checkpoint origin
    m_iEntID                      // entity id

}


//this enum is used to store the course data parsed from file or
//from the mysql database
enum eCourseData_t 
{
    m_iCourseID,                                          // course id
    m_szCourseName[MAX_COURSE_NAME],               // course name (e.g. "Easy")
    m_szCourseDescription[MAX_COURSE_DESCRIPTION],  // course description (e.g. "Easy")
    m_iNumCheckpoints,                              // number of checkpoints
    m_iDifficulty,                                  // difficulty (value between 0 - 100) if set to -1, the difficulty is not set
    m_szGoalTeams[16]                               // teams that can reach the goal (e.g. "BRGY"), here for legacy reasons
}

/* 
 * 	global variables
*/

new Array: g_Checkpoints = Invalid_Array;                  // array to store the checkpoints
new Array: g_Courses = Invalid_Array;                      // array to store the courses
new g_iCPCount;                                     // number of checkpoints    
new g_iModelID;                                         // model id of the goal model   
new g_bWorldSpawned;                                    // true if the worldspawn entity has been spawned

/* 
 * 	Functions
*/

public plugin_natives() {
    register_native("api_get_mapdifficulty", "Native_GetMapDifficulty");  
    register_native("api_get_coursedescription", "Native_GetCourseDescription");
    register_native("api_get_coursename", "Native_GetCourseName");
    register_native("api_is_team_allowed", "Native_IsTeamAllowed");
    register_native("api_get_totalcps", "Native_GetTotalCPS");
    register_library("api_skills_mapentities");
    register_forward(FM_Spawn,"fm_spawn");
    g_bWorldSpawned = false;
    g_iCPCount = 0;
    g_Checkpoints = ArrayCreate(eCheckPoints_t);
    g_Courses = ArrayCreate(eCourseData_t);
}

public plugin_init() {
    RegisterPlugin();

    register_clcmd("say /loadfile", "parse_skillsconfig");
    register_clcmd("say /spawncheckpoint", "debug_spawncheckpoint");
    register_clcmd("say /cp", "debug_spawncheckpoint");
    register_clcmd("say /listcps", "debug_list_all_cps_in_world");

}

public plugin_unload() {
    ArrayDestroy(g_Checkpoints);
    ArrayDestroy(g_Courses);
}   

public plugin_precache() {
    g_iModelID = precache_model(LEGACY_MODEL);
}


public fm_spawn(id) {
    if (g_bWorldSpawned) { return; } //worldspawn has already been spawned
    
    new szClassname[32]; entity_get_string(id, EV_SZ_classname, szClassname, charsmax(szClassname));
    if (equali(szClassname, "worldspawn")) {
        parse_skillsconfig();
        g_bWorldSpawned = true;
    }
}

//function to return the description of the course by its id
public get_course_description(id) {
    new iCount = ArraySize(g_Courses);
    new szDescription[MAX_COURSE_DESCRIPTION];
    new Buffer[eCourseData_t];
    //initialize the string
    formatex(szDescription, charsmax(szDescription), "__Unknown");

    for (new i = 0; i < iCount; i++) {
        ArrayGetArray(g_Courses, i, Buffer);
        if (Buffer[m_iCourseID] == id) {
            formatex(szDescription, charsmax(szDescription), "%s", Buffer[m_szCourseName]);
        }
    }
    return szDescription;
}

public parse_skillsconfig() {

    new mapname[32];  get_mapname(mapname, charsmax(mapname));                          // get the map name
    new filename[32]; formatex(filename, charsmax(filename), "skills/%s.cfg", mapname); // get the filename
    new path[128]; BuildAMXFilePath(filename, path, charsmax(path), "amxx_configsdir"); // get the full path to the file

    new tempCourseData[eCourseData_t];  // temp array to store the course data
    new Float:startCP[3];               // temp array to store the start checkpoint origin
    new Float:endCP[3];                 // temp array to store the end checkpoint origin
    new Array:tempCheckpoints = ArrayCreate(eCheckPoints_t);          // temp array to store the checkpoints

    //set the tempCourseData difficulty to -1
    tempCourseData[m_iDifficulty] = -1;

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

            //check if key is "sv_difficulty" and set the difficulty
            if (equali(szKey, "sv_difficulty")) {
                tempCourseData[m_iDifficulty] = str_to_num(szValue);
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
                formatex(tempCourseData[m_szGoalTeams], charsmax(tempCourseData[m_szGoalTeams]), "%s", szValue);
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
                aCP[m_iCPID] = -1; //not set
                aCP[m_iCPType] = 1; //checkpoint
                aCP[m_iCPCourseID] = -1; //not set
                aCP[m_fOrigin] = tempOrigin;

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
        if (tempCourseData[m_iDifficulty] == -1) {
            DebugPrintLevel(0, "No difficulty found in file %s", path);
            ArrayDestroy(tempCheckpoints);
            return;
        }

        //check if goal teams are set and set them to "BRGY" if not
        if (equal(tempCourseData[m_szGoalTeams], "__Undefined")) {
            formatex(tempCourseData[m_szGoalTeams], charsmax(tempCourseData[m_szGoalTeams]), "BRGY");
        }

        //set the name of the course to "Legacy Course"
        formatex(tempCourseData[m_szCourseName], charsmax(tempCourseData[m_szCourseName]), "Legacy Course");

        //set the Description to "Legacy course imported from the file on <date>"
        new szDate[32];
        //format_time(output[], len, const format[], time = -1);
        format_time(szDate, charsmax(szDate), "%d.%m.%Y", get_systime());
        formatex(tempCourseData[m_szCourseDescription], charsmax(tempCourseData[m_szCourseDescription]), "Legacy course imported from the file on %s", szDate);

        new iNextCourseID = ArraySize(g_Courses);
        DebugPrintLevel(0, "Current  courses ID: %d", iNextCourseID);

        //set the course id
        tempCourseData[m_iCourseID] = (iNextCourseID + 1);
        DebugPrintLevel(0, "Course ID: %d", tempCourseData[m_iCourseID]);

        ArrayPushArray(g_Courses, tempCourseData);

        debug_coursearray();
        //add the start cp to the tempCheckpoints array
        new aStartCP[eCheckPoints_t];
        aStartCP[m_iCPID] = -1; //not set
        aStartCP[m_iCPType] = 0; //start
        aStartCP[m_iCPCourseID] = -1; //not set
        aStartCP[m_fOrigin] = startCP;
        ArrayPushArray(tempCheckpoints, aStartCP);

        //add the end cp to the tempCheckpoints array
        new aEndCP[eCheckPoints_t];
        aEndCP[m_iCPID] = -1; //not set
        aEndCP[m_iCPType] = 2; //finish
        aEndCP[m_iCPCourseID] = -1; //not set
        aEndCP[m_fOrigin] = endCP;
        ArrayPushArray(tempCheckpoints, aEndCP);

        //cycle through all tempcheckpoints and call push_checkpoint_array
        new iCount = ArraySize(tempCheckpoints);
        new Buffer[eCheckPoints_t];
        for (new i; i < iCount; i++) {
            ArrayGetArray(tempCheckpoints, i, Buffer);
            Buffer[m_iCPCourseID] = tempCourseData[m_iCourseID];
            push_checkpoint_array(Buffer, tempCourseData[m_iCourseID]);
        }

        ArrayDestroy(tempCheckpoints);

        spawn_checkpoints_of_course(tempCourseData[m_iCourseID]);
        
    }
} 

public push_checkpoint_array( Buffer[eCheckPoints_t], id ) {

    if (Buffer[m_iCPID] == -1) {
        g_iCPCount++;
        Buffer[m_iCPID] = g_iCPCount;
    }

    if (Buffer[m_iCPCourseID] == -1) {
        Buffer[m_iCPCourseID] = id;
    }
    DebugPrintLevel(0, "Pushing checkpoint %d (%f, %f, %f) of course %s to array", Buffer[m_iCPID], Buffer[m_fOrigin][0], Buffer[m_fOrigin][1], Buffer[m_fOrigin][2], get_course_description(id));
    ArrayPushArray(g_Checkpoints, Buffer);
}


public debug_coursearray() {
    new iCount = ArraySize(g_Courses);
    DebugPrintLevel(0, "Number of courses: %d", iCount);
    new Buffer[eCourseData_t];
    for (new i; i < iCount; i++) {
        ArrayGetArray(g_Courses, i, Buffer);
        DebugPrintLevel(0, "-------------------");
        DebugPrintLevel(0, "Course ID: %d", Buffer[m_iCourseID]);
        DebugPrintLevel(0, "Course Name: %s", Buffer[m_szCourseName]);
        DebugPrintLevel(0, "Course Description: %s", Buffer[m_szCourseDescription]);
        DebugPrintLevel(0, "Difficulty: %d", Buffer[m_iDifficulty]);
        DebugPrintLevel(0, "Goal Teams: %s", Buffer[m_szGoalTeams]);
        DebugPrintLevel(0, "Number of Checkpoints: %d", Buffer[m_iNumCheckpoints]);
    }
}

/*
* Natives
*/

// native to get the map difficulty
public Native_GetMapDifficulty(iPluign, iParams) {
    return 0;
}

public Native_GetCourseDescription(iPluign, iParams) {
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
        if (Buffer[m_iCourseID] == id) {
            formatex(szReturn, charsmax(szReturn), "%s", Buffer[m_szCourseDescription]);
        }
    }
    set_string(2, szReturn, get_param(3));
}

public Native_GetCourseName(iIndex) {
    new id = get_param(1);
    DebugPrintLevel(0, "Getting course name for id %d", id);
    new szReturn[MAX_COURSE_NAME];
    formatex(szReturn, charsmax(szReturn), "__Undefined");

    new iCount = ArraySize(g_Courses);
    if (id > iCount) {
        return;
    }

    new Buffer[eCourseData_t];
    for (new i; i < iCount; i++) {
        ArrayGetArray(g_Courses, i, Buffer);
        if (Buffer[m_iCourseID] == id) {
            formatex(szReturn, charsmax(szReturn), "%s", Buffer[m_szCourseName]);
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
        if (Buffer[m_iCPCourseID] == id) {
            iTotal++;
        }
    }
    return iTotal;
}

// native to check if a team is allowed to reach the goal
// called through api_is_team_allowed(playerid, cp_entid);
public Native_IsTeamAllowed(iPluign, iParams) {
    new id = get_param(1);
    new startent = get_param(2);

    new iCountCPs = ArraySize(g_Checkpoints);
    new iCourseID = -1;
    new Buffer[eCheckPoints_t];
    for (new i; i < iCountCPs; i++) {
        ArrayGetArray(g_Checkpoints, i, Buffer);
        //DebugPrintLevel(0, "Checking checkpoint %d with entid %d against ent id %d", Buffer[m_iCPID], Buffer[m_iEntID], startent);
        if (Buffer[m_iEntID] == startent) {
            // found the start checkpoint now check the course id and break the loop
            iCourseID = Buffer[m_iCPCourseID];
            break;
        }
    }

    if (iCourseID == -1) {
        DebugPrintLevel(0, "[ERROR] Could not find course id for start checkpoint %d", startent);
        return false;
    }

    //now check if the team is allowed to reach the goal
    new iCount = ArraySize(g_Courses);
    new Buffer2[eCourseData_t];
    for (new i; i < iCount; i++) {
        ArrayGetArray(g_Courses, i, Buffer2);

        if (equali(Buffer2[m_szGoalTeams], "BRGY")) {                                           
            return true;
        } else {
            if ((containi(Buffer2[m_szGoalTeams], "B") > -1) && get_user_team(id) == 1) {            
                return true;
            } else if ((containi(Buffer2[m_szGoalTeams], "R") > -1) && get_user_team(id) == 2) { 
                return true;
            } else if ((containi(Buffer2[m_szGoalTeams], "G") > -1) && get_user_team(id) == 3) {
                return true;
            } else if ((containi(Buffer2[m_szGoalTeams], "Y") > -1)&& get_user_team(id) == 4) {
                return true;
            } else {
                return false;
            }
        }
        
    }
    return false;
}

/*
* Spawn the entities
*/

//function: spawns a checkpoint
//params: checkpoint id

public spawn_checkpoint(id) {

    new Buffer[eCheckPoints_t];
    ArrayGetArray(g_Checkpoints, id, Buffer);
    DebugPrintLevel(0, "Attempting to spawn checkpoint %d (%f, %f, %f) of course %s", Buffer[m_iCPID], Buffer[m_fOrigin][0], Buffer[m_fOrigin][1], Buffer[m_fOrigin][2], get_course_description(Buffer[m_iCPCourseID]));

    new entity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
    entity_set_string(entity, EV_SZ_classname, "sw_checkpoint");
    engfunc(EngFunc_SetModel, entity, LEGACY_MODEL);   
    
    new Float:origin[3]
    origin[0] = Buffer[m_fOrigin][0];
    origin[1] = Buffer[m_fOrigin][1];   
    origin[2] = Buffer[m_fOrigin][2];


    if (Buffer[m_iCPType] == 0) {
        entity_set_int(entity, EV_INT_skin, 2);
    } else if (Buffer[m_iCPType] == 1) {
        entity_set_int(entity, EV_INT_skin, 3);
    } else {
        entity_set_int(entity, EV_INT_skin, 1);
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

    entity_set_int(entity, EV_INT_iuser1, Buffer[m_iCPType]); //set the m_iCPType of the checkpoint (0 = start, 1 = checkpoint, 2 = finish)
    entity_set_int(entity, EV_INT_iuser2, Buffer[m_iCPCourseID]); //set the m_iCPCourseID of the checkpoint

    //set the m_iEntID of the checkpoint
    Buffer[m_iEntID] = entity;

    //DebugPrintLevel(0, "Spawned checkpoint at %f, %f, %f (EntID: %d)", origin[0], origin[1], origin[2], Buffer[m_iEntID]);

    ArraySetArray(g_Checkpoints, id, Buffer); //update the array
}

//function to spawn all checkpoints of a course
//params: course id
public spawn_checkpoints_of_course(id) { 
    new iCount = ArraySize(g_Checkpoints);
    new Buffer[eCheckPoints_t];
    for (new i; i < iCount; i++) {
        ArrayGetArray(g_Checkpoints, i, Buffer);
        if (Buffer[m_iCPCourseID] == id) {
            DebugPrintLevel(0, "Spawning checkpoint %d of course %s", Buffer[m_iCPID], get_course_description(id));
            spawn_checkpoint(i);
        }
    }
}
//spawns a checkpoint at the players location
public debug_spawncheckpoint(id) {
    if (!is_connected_admin(id)) {
        client_print(id, print_chat, "> You are not an admin.");
        return PLUGIN_HANDLED;
    }

    new entity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
    entity_set_string(entity, EV_SZ_classname, "sw_checkpoint");
    engfunc(EngFunc_SetModel, entity, LEGACY_MODEL);   
    
    new Float:origin[3]
    pev(id,pev_origin,origin) //get the origin of the player

    entity_set_vector(entity, EV_VEC_origin, origin);
    entity_set_vector(entity, EV_VEC_angles, Float:{0.0, 0.0, 0.0});
    entity_set_float(entity, EV_FL_nextthink, (get_gametime() + 0.1));
    entity_set_int(entity, EV_INT_skin, 3);
    entity_set_int(entity, EV_INT_solid, SOLID_TRIGGER);
    entity_set_int(entity, EV_INT_rendermode, 5);
    entity_set_int(entity, EV_INT_renderfx, 0);
    entity_set_float(entity, EV_FL_renderamt, 255.0);
    entity_set_float(entity, EV_FL_framerate, 0.5);
    entity_set_int(entity, EV_INT_sequence, 0);	
    entity_set_float(entity, EV_FL_health, 100000.0);

    //DebugPrintLevel(0, "Spawning checkpoint at %f, %f, %f", origin[0], origin[1], origin[2]);
    return PLUGIN_HANDLED
}

public debug_list_all_cps_in_world() {
    new ent = -1;
    while ((ent = find_ent_by_class(ent,"sw_checkpoint"))) {
        new Float:origin[3];
        entity_get_vector(ent, EV_VEC_origin, origin);
        DebugPrintLevel(0, "Found Checkpoint at %f, %f, %f", origin[0], origin[1], origin[2]);
    }
}

