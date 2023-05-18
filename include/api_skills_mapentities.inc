#if defined _api_skills_mapentities
  #endinput
#endif
#define _api_skills_mapentities

#pragma reqlib "api_skills_mapentities"

native api_get_mapdifficulty(iIndex); //course id
native api_is_team_allowed(playerid, cp_entid);
native api_get_coursename(id, name[], len); 
native api_get_coursedescription(id, desc[], len);
native api_get_totalcps(id);