#include <amxmodx>
#include <engine>
#include <fakemeta>
#include "include/global"

#define PLAYER_TASK_OFFSET 100

new g_player_fps[ MAX_PLAYERS ];
new g_player_fov[ MAX_PLAYERS ];


public plugin_init( ) {

    register_plugin( "Show Aim Plugin", "1.0", "Skillzworld / Vancold.at"  );
    register_message( get_user_msgid( "StatusText" ), "ovewrite_statustext");

    for( new i = 0; i < MAX_PLAYERS; i++) {
        g_player_fps[ i ] = 0;
        g_player_fov[ i ] = 0;
    }

}

public client_prethink(id) {

    if(is_user_connected(id) && !task_exists(PLAYER_TASK_OFFSET + id)) {
        set_task( 1.0, "count_fps", PLAYER_TASK_OFFSET + id, "", 0, "b");
    }

    new fov = 0;
    fov = floatround( entity_get_float( id, EV_FL_fov ) );

    g_player_fps[ id ] ++;
    g_player_fov[ id ] = fov;

}

public count_fps( task_id ) {

    new id = task_id - PLAYER_TASK_OFFSET;
    client_print(0, print_chat, "fps: %d", g_player_fps[ id ] );    
    client_print(0, print_chat, "fov: %d", g_player_fov[ id ] );

    g_player_fps[ id ] = 0;

}


public client_disconnected(id) {

    g_player_fps[id] = 0;
    g_player_fov[id] = 0;

    if( task_exists( PLAYER_TASK_OFFSET + id ) ) {
        remove_task( PLAYER_TASK_OFFSET + id );
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