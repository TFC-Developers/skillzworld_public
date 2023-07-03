#include <amxmodx>
#include <engine>
#include "include/global"

new g_player_fps[ MAX_PLAYERS ];
new g_player_fov[ MAX_PLAYERS ];


public plugin_init( ) {

    register_plugin( "Show Aim Plugin", "1.0", "Skillzworld / Vancold.at"  );

    register_message( get_user_msgid( "StatusText" ), "ovewrite_statustext");
    register_message( get_user_msgid( "SetFov" ), "read_fov");

    for( new i = 0; i < MAX_PLAYERS; i++) {
        g_player_fps[ i ] = 0;
        g_player_fov[ i ] = 0;
    }

}

public read_fov ( msg_id, msg_dest, playerId ) {
    client_print(playerId, print_chat, "hello ;)");
    g_player_fov[playerId] = get_msg_arg_int( 1 );
}



public ovewrite_statustext( msg_id, msg_dest, playerId ) {

    new lookingAt = GetAimEntity(playerId);

    if(lookingAt > 0 && lookingAt < MAX_PLAYERS + 1) {

        new message[ 256 ], input[ 128 ], username[ 128 ];

        get_msg_arg_string(2, input, charsmax(input) );
        get_user_name( lookingAt, username, charsmax( username ) );
        fov = entity_get_float( lookingAt, EV_FL_fov);

        format(message, charsmax( message ) , "%s  FOV: %.2f  FPS: %d", input, g_player_fov[playerId], g_player_fps[lookingAt]);
        set_msg_arg_string( 2, message );
 
    }

}