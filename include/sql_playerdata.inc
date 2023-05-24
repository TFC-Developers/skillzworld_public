#if defined _player_api_included
  #endinput
#endif
#define _player_api_included

#pragma reqlib "api_player"

/////////////////////////////////////////////////////////
// Player flags from database                          //
/////////////////////////////////////////////////////////
//#define FLAG_UNUSED (1<<0)     // unused
//#define FLAG_UNUSED	(1<<1)     // unused 
#define FLAG_SKILLSBAN (1<<2)    // runs wont be counted
//#define FLAG_UNUSED	(1<<3)     // unused 
#define FLAG_NOXMAS		(1<<4)     // won't see any xmas stuff
#define FLAG_NOCHAT		(1<<5)     // can't chat
#define FLAG_NOVOICE	(1<<6)     // can't use voice
//#define FLAG_UNUSED (1<<7)     // unused
#define FLAG_GLOWCONCS	(1<<8)   // concs will glow
//#define FLAG_UNUSED (1<<9)     // unused
//#define FLAG_UNUSED (1<<10)    // unused
//#define FLAG_UNUSED (1<<11)    // unused  
//#define FLAG_UNUSED (1<<12)    // unused
//#define FLAG_UNUSED (1<<13)    // unused
#define FLAG_IGNORESKINS (1<<14) // custom skins won't be shown
/////////////////////////////////////////////////////////


enum ePlayerStruct_t 
{
  mPD_iPlayerID = 0,            // [SQL] Player ID (unique)
  mPD_iPlayerFlags,             // [SQL] Player flags
  mPD_iPlayerLevel,             // [SQL] Player level
  mPD_szFirstName[64],          // [SQL] Player first name
  mPD_szFirstSeen[64],          // [SQL] Player first seen date
  mPD_szSteamID[64],            // [SQL] Player SteamID
  Float:mPD_ftTime,             // [SQL] Player total time
  mPD_iPlayerID,                // [INTERNAL] Player ID (1-32)
  Float:mPD_ftLastPTUpdate      // [INTERNAL] Last player time update in the database (float) will be set to gametime upon connect and every 5 minutes
}