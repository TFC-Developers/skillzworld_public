#if defined _sql_queries_included
  #endinput
#endif
#define _sql_queries_included

#pragma reqlib "sw_sql_skills"

/* 
 * 	Includes
*/
#include "include/api_skills_mapentities"           // Include file for map entities (SW_SKILLS_LEGACYCPS)

native api_sql_insertcourse( Data[] = "" );         // Insert a course into the database
native api_sql_insertlegacycps( Data[] = "" );      // Insert a legacy CPS into the database
native api_sql_insertrun(id, Float:fTime, course, cpsused);  // Insert a run into the database
native api_sql_reloadcourses();                     // Reload the courses from the database