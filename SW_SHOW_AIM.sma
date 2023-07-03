#include <amxmodx>
#include <engine>
#include <fakemeta>
#include "include/global"

new g_player_fps[ MAX_PLAYERS ];


public plugin_init( ) {

    register_plugin( "Show Aim Plugin", "1.0", "Skillzworld / Vancold.at"  );
    register_message( get_user_msgid( "StatusText" ), "ovewrite_statustext");

    for( new i = 0; i < MAX_PLAYERS; i++) {
        g_player_fps[ i ] = 0;
    }

}


public ovewrite_statustext( msg_id, msg_dest, playerId ) {

    new lookingAt = GetAimEntity(playerId);

    if(lookingAt > 0 && lookingAt < MAX_PLAYERS + 1) {

        new message[ 256 ], input[ 128 ], username[ 128 ], fov;

        get_msg_arg_string(2, input, charsmax(input) );
        get_user_name( lookingAt, username, charsmax( username ) );
        fov = pev( lookingAt, pev_fov);

        format(message, charsmax( message ) , "%s  FOV: %d  FPS: %d", input, fov, g_player_fps[lookingAt]);
        set_msg_arg_string( 2, message );
 
    }

}