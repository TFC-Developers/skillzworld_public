#include <amxmodx>
#include <engine>
#include "include/global"

#define STATUSTEXT 84

public plugin_init( ) {

    register_plugin( "Show Aim Plugin", "1.0", "Skillzworld / Vancold.at"  );
    register_message( STATUSTEXT, "OverwriteStatusText");

}


public OverwriteStatusText( msg_id, msg_dest, playerId ) {

    new lookingAt = GetAimEntity(playerId);

    if(lookingAt > 0 && lookingAt < MAX_PLAYERS + 1) {

        new message[ 256 ], input[ 128 ], username[ 128 ];
        new Float: fov, Float: fps;

        get_msg_arg_string(2, input, charsmax(input) );
        fov    = entity_get_float( lookingAt, EV_FL_fov);
        fps    = 0.0;

        get_user_name( lookingAt, username, charsmax( username ) );

        format(message, charsmax( message ) , "%s  FOV: %.2f  FPS: %.2f", input, fov, fps);

        set_msg_arg_string( 2, message );

        client_print(playerId, print_chat, "I am looking at %s", username);    
    }

}

