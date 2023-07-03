/*
*
*/

#include <amxmodx>
#include <engine>

#define STATUSTEXT 84
new lookingAt[MAX_PLAYERS];

public plugin_init( ) {

    register_plugin( "Show Aim Plugin", "1.0", "Skillzworld / Vancold.at"  );
    register_event( "StatusValue", "EventStatusValue_PlayerID", "b", "1=2", "2>0" );
    register_message( STATUSTEXT, "OverwriteStatusText");

    for( new i = 0; i < sizeof(lookingAt); i++) {
        lookingAt[i] = 0;
    }

}

public EventStatusValue_PlayerID ( playerId ) {

    lookingAt[playerId] = read_data( 2 );
    new username[ 128 ];
    get_user_name( lookingAt[playerId], username, charsmax( username ) );
    client_print(playerId, print_chat, "looking at id: %d | name: %s", lookingAt[playerId], username )

}

public OverwriteStatusText( msg_id, msg_dest, playerId ) {

    new message[ 256 ], input[ 128 ];
    new Float: fov, Float: fps;

    get_msg_arg_string(2, input, charsmax(input) );
    fov    = entity_get_float( lookingAt[playerId], EV_FL_fov);


    format(message, charsmax( message ) , "%s fov: %02f", input, fov);

    set_msg_arg_string( 2, message );

    /*
    message_begin(MSG_ONE, get_user_msgid("StatusText"), {0, 0, 0}, playerId); 
    write_byte(0); 
    write_string(message); 
    message_end();
    */ 
}

