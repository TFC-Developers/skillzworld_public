#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include "include/global"

#define PLAYER_TASK_OFFSET 100

new g_player_fps[ MAX_PLAYERS ];
new g_player_fps_count[ MAX_PLAYERS ];
new g_player_fov[ MAX_PLAYERS ];
new g_player_teamrelation [ MAX_PLAYERS ];


public plugin_init( ) {

    register_plugin( "Show Aim Plugin", "1.0", "Skillzworld / Vancold.at"  );
    register_message( get_user_msgid( "StatusText" ), "ovewrite_statustext");

    for( new i = 0; i < MAX_PLAYERS; i++) {
        g_player_fps[ i ] = 0;
        g_player_fps_count[ i ] = 0;
        g_player_fov[ i ] = 0;
    }

}

public client_PreThink( id ) {

    new fov = 0;
    fov = floatround( entity_get_float( id, EV_FL_fov ) );

    g_player_fps[ id ] ++;
    g_player_fov[ id ] = fov;

    if( is_user_connected(id) && !task_exists( id ) ) {
        set_task( 1.0, "count_fps", id, "", 0, "b" );
    }

}

public count_fps( params[], id ) {

    g_player_fps_count[ id ] = g_player_fps[ id ];
    g_player_fps[ id ] = 0;

}


public client_disconnected( id, bool:drop, message[], maxlen ) {

    g_player_fps[id] = 0;
    g_player_fov[id] = 0;

    if( task_exists( id ) ) {
        remove_task( id );
    }
}

public ovewrite_statustext( msg_id, msg_dest, playerId ) {

    new lookingAt = GetAimEntity( playerId );

    if( lookingAt > 0 && lookingAt < MAX_PLAYERS + 1 ) {

        new message[ 256 ], input[ 128 ];

        get_msg_arg_string( 2, input, charsmax(input) );
        format( message, charsmax( message ) , "%s  FOV: %d  FPS: %d", input, g_player_fov[ lookingAt ], g_player_fps_count[ lookingAt ] );
        set_msg_arg_string( 2, message );
        client_print(playerId, "id: %d , fps: %d , fov: %d",lookingAt, g_player_fps_count[ lookingAt ], g_player_fov[ lookingAt ] )
 
    }

}