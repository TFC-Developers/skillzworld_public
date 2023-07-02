/*
*
*/

#include <amxmodx>
#include <engine>

new g_statusText;

public plugin_init( ) {

    register_plugin( "Show Aim Plugin", "1.0", "Skillzworld / Vancold.at"  );
    register_event( "StatusValue", "EventStatusValue_PlayerID", "b", "1=2", "2>0" );
    g_statusText = get_user_msgid( "StatusText" );
    
}

public EventStatusValue_PlayerID ( playerId ) {

    new lookingAt = read_data( 2 );

    new message[ 256 ], username[128], Float: health, Float: armor, Float: fov, Float: fps;
    get_user_name( lookingAt, username, charsmax( username ) );
    health = entity_get_float( lookingAt, EV_FL_health );
    armor  = entity_get_float( lookingAt, EV_FL_armorvalue );
    fov    = entity_get_float( lookingAt, EV_FL_fov);

    formatex( message, 256, "%s  H:%f%  A:%f%  FOV:%f  FPS:%d", username, health, armor, fov, fps );

    message_begin( MSG_ONE, g_statusText, _, playerId );
    {
        write_byte( 0 );
        write_string( message );
    }
    message_end( );

}

