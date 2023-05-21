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

#define SRFLAG_TEAMBLUE (1<<0)
#define SRFLAG_TEAMRED (1<<1)
#define SRFLAG_TEAMYELLOW (1<<2)
#define SRFLAG_TEAMGREEN (1<<3)



/* 
 * 	Structs
*/

//this enum is used to store the checkpoint data parsed from file or 
//from the mysql database
enum eCheckPoints_t
{
    m_iCPID,                      // [INTERNAL] checkpoint id
    m_iCPType,                    // [SQL]      checkpoint type (0 = start, 1 = checkpoint, 2 = finish)
    m_iCPCourseID,                // [INTERNAL] course id (foreign key)
    Float:m_fOrigin[3],           // [SQL]      checkpoint origin
    m_iEntID,                     // [INTERNAL] entity id
    m_sqlCourseID,                // [SQL]      sql course id (foreign key)

}


//this enum is used to store the course data parsed from file or
//from the mysql database
enum eCourseData_t 
{
    m_iCourseID,                                    // [INTERNAL] course id
    m_sqlCourseID,                                  // [SQL]      sql course id  (foreign key)
    m_szCourseName[MAX_COURSE_NAME],                // [SQL]      course name (e.g. "Easy")
    m_szCourseDescription[MAX_COURSE_DESCRIPTION],  // [SQL]      course description (e.g. "Easy")
    m_iNumCheckpoints,                              // [INTERNAL] number of checkpoints
    m_iDifficulty,                                  // [SQL]      difficulty (value between 0 - 100) if set to -1, the difficulty is not set
    m_szGoalTeams[16],                              // [INTERNAL] teams that can reach the goal (e.g. "BRGY"), here for legacy reasons
    bool:m_bLegacy,                                 // [SQL]      legacy course (true/false)
    m_iCreatorID,                                   // [SQL]      creator id
    m_iFlags,                                       // [SQL]      flags
    m_szCreated_at[32],                             // [SQL]      creation date
    m_bSQLActive,                                   // [SQL]      course flagged as active (true/false) in database
    m_szCreatorName[32]                             // [SQL]      creator name
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