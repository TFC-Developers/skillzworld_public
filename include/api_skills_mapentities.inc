#if defined _api_skills_mapentities
  #endinput
#endif
#define _api_skills_mapentities

#pragma reqlib "api_skills_mapentities"

/* 
 * 	Defines
*/

#define MAX_CHECKPOINTS 2048 // max number of checkpoints
#define MAX_COURSES 128 // max number of courses
#define MAX_COURSE_NAME 32 // max length of the course name
#define MAX_COURSE_DESCRIPTION 64 // max length of the course description
#define LEGACY_MODEL "models/skillzworld/checkpoint2.mdl"

#define SRFLAG_TEAMBLUE   (1<<0)
#define SRFLAG_TEAMRED    (1<<1)
#define SRFLAG_TEAMYELLOW (1<<2)
#define SRFLAG_TEAMGREEN  (1<<3)


#define MAPFLAG_SURFMODE (1<<0)
#define MAPFLAG_BHOPMODE (1<<1)


/* 
 * 	Structs
*/

//this enum is used to store the checkpoint data parsed from file or 
//from the mysql database
enum eCheckPoints_t
{
    mCP_iID,                      // [INTERNAL] checkpoint id
    mCP_iType,                    // [SQL]      checkpoint type (0 = start, 1 = checkpoint, 2 = finish)
    mCP_iCourseID,                // [INTERNAL] course id (foreign key)
    Float:mCP_fOrigin[3],           // [SQL]      checkpoint origin
    mCP_iEntID,                     // [INTERNAL] entity id
    mCP_sqlCourseID,                // [SQL]      sql course id (foreign key)
}


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

/*
  * 	Natives
*/

native api_get_mapdifficulty(iIndex);                 //params: iIndex - course index
native api_is_team_allowed(playerid, cp_entid);       //params: playerid - player id, cp_entid - checkpoint entity id
native api_get_coursename(id, name[], len);           //params: id - course id, name[] - course name, len - max length of the course name
native api_get_coursedescription(id, desc[], len);    //params: id - course id, desc[] - course description, len - max length of the course description
native api_get_totalcps(id);                          //params: id - course id
native api_legacycheck();                             //params: none
native api_registercourse( Buffer[] );                //params: Buffer[] - course data 
native api_registercheckpoint( Buffer[] );            //params: Buffer[] - checkpoint data
native api_spawnallcourses();                         //params: none  
native api_get_course_mysqlid(id);                    //params: id - course id
native api_get_number_courses();                      //params: none  
native api_get_player_course(id);                     //params: id - player id
native api_process_mapflags(flags);                   //params: flags - map flags
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang2057\\ f0\\ fs16 \n\\ par }
*/
