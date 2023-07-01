/*
 * entity use command plugin for SkillzWorld
 *
 * This plugin adds santa hats to players in Team Fortress Classic
 * during the specified holiday season (December 1st to January 2nd).
 *
 * Written for AMX Mod X by skillzworld / MrKoala
 */

#include <amxmodx>
#include <messages>

#define STATUSTEXT 84

new g_lookingAt[MAX_PLAYERS];

public plugin_init() 
{
    register_plugin( "Show Aim Plugin", "1.0", "Skillzworld / Vancold.at"  );
    register_event( "StatusValue", "EventStatusValue_PlayerID", "b", "1=2", "2>0" );
    register_message( STATUSTEXT, "update_text");

}

public EventStatusValue_PlayerID ( playerId ) {
    g_lookingAt[playerId] = read_data( 2 );
}


public update_text( msg_id, msg_dest, playerId) {
    console_print(0,"lol");
    console_print(0,"number of args: %d",get_msg_args());
}