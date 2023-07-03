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

}

public OverwriteStatusText( msg_id, msg_dest, playerId ) {

    new message[ 256 ], username[ 128 ], test[ 128 ], unknown;
    new Float: health, Float: armor, Float: fov, Float: fps;

    get_user_name( lookingAt[playerId], username, charsmax( username ) );
    health = entity_get_float( lookingAt[playerId], EV_FL_health );
    armor  = entity_get_float( lookingAt[playerId], EV_FL_armorvalue );
    fov    = entity_get_float( lookingAt[playerId], EV_FL_fov);


    format(test, charsmax(test) , "1 %p1 Health: %f Armor: %f FOV %f", health, armor, fov);

    set_msg_arg_string(2,test);

    /*
    message_begin(MSG_ONE, get_user_msgid("StatusText"), {0, 0, 0}, playerId); 
    write_byte(0); 
    write_string(message); 
    message_end();
    */ 
}

