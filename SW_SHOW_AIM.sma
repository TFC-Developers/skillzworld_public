#include < amxmodx >
#include < geoip >

new const MESSAGE_TEAMMATE[ ] = "1 %%c1: %%p2 - %s - %%h: %%i3%%%%";
new const MESSAGE_ENEMY   [ ] = "1 %%c1: %%p2 - %s";

new g_szCountry[ 33 ][ 45 ];
new g_iMsgStatusText;
new g_iRelation;

public plugin_init( )
{
	register_plugin( "Aim Info + Country", "2.0", "xPaw" );
	
	register_event( "StatusValue", "EventStatusValue_Relation", "b", "1=1" );
	register_event( "StatusValue", "EventStatusValue_PlayerID", "b", "1=2", "2>0" );
	
	g_iMsgStatusText = get_user_msgid( "StatusText" );
}

public EventStatusValue_Relation( const id )
{
	g_iRelation = read_data( 2 );
}

public EventStatusValue_PlayerID( const id )
{
	if( !g_iRelation )
	{
		return;
	}
	
	new iPlayer = read_data( 2 );
	
	if( !g_szCountry[ iPlayer ][ 0 ] )
	{
		g_iRelation = 0;
		return;
	}
	
	new szMessage[ 80 ];
	formatex( szMessage, 79, g_iRelation == 1 ? MESSAGE_TEAMMATE : MESSAGE_ENEMY, g_szCountry[ iPlayer ] );
	
	g_iRelation = 0;
	
	message_begin( MSG_ONE, g_iMsgStatusText, _, id );
	{
		write_byte( 0 );
		write_string( szMessage );
	}
	message_end( );
}

public client_putinserver( id )
{
	new szIP[ 16 ];
	get_user_ip( id, szIP, 15, 1 );
	
	if( geoip_country( szIP, g_szCountry[ id ], 44 ) == 5 && g_szCountry[ id ][ 0 ] == 'e' )
	{
		g_szCountry[ id ][ 0 ] = EOS;
	}
}

public client_disconnect( id )
{
	g_szCountry[ id ][ 0 ] = EOS;
}
