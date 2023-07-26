#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include "include/global"

new message[] = "1 %%c1: %%p2 - %%h: %%i3%%%%";

new g_player_fps[ MAX_PLAYERS ];
new g_player_fps_count[ MAX_PLAYERS ];
new g_player_fov[ MAX_PLAYERS ];

new g_status_text;

public plugin_init( ) {

    register_plugin( "Show Aim Plugin", "1.0", "Skillzworld / Vancold.at"  );
    register_event( "StatusValue", "playerID", "b", "1=2", "2>0" );

    g_status_text = get_user_msgid( "StatusText" );

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

    if( is_user_connected( id ) && !task_exists( id ) ) {
        set_task( 1.0, "count_fps", id, "", 0, "b" );
    }

}

public count_fps( params[], id ) {

    g_player_fps_count[ id ] = g_player_fps[ id ];
    g_player_fps[ id ] = 1;

}


public client_disconnected( id, bool: drop, message[], maxlen ) {

    g_player_fps[ id ] = 0;
    g_player_fov[ id ] = 0;
    g_player_fps_count[ id ] = 0;

    if( task_exists( id ) ) {
        remove_task( id );
    }
}

public playerID( const id ) {

    new lookingAt = read_data( 2 );
    new output[ 512 ];

    client_print(id, print_console, "lol");

    format( output, charsmax( output ) , "%s  FOV: %d  FPS: %d", message, g_player_fov[ lookingAt ], g_player_fps_count[ lookingAt ] );
    
    message_begin( MSG_ONE, g_status_text, _, id );
    {
        write_byte( 0 );
        write_string( "fuck off" );
    } 
    message_end( );

}