/*
 * Adminmenu Plugin for SkillzWorld
 *
 * Written for AMX Mod X by skillzworld / MrKoala
 */


/*********[ Includes ]*********/
#include < amxmodx >
#include < amxmisc >
#include < engine >
#include < fakemeta >
#include < fakemeta_util >
#include < fakemeta_stocks >


/*********[ Global definitions ]*********/
new g_iVictim[33]       // array containing the victim the admin choose
new g_iAction[33]       // array containing action to be issued
new g_iReason[33]        // array containing choosen reason
new Array:g_iReasons    // array with reasons
new g_msgScreenFade

bool:is_connected_admin(id, privileges){return (is_user_connected(id) && (get_user_flags(id) & privileges) && !is_user_bot(id));}
bool:is_connected_user(id){return (is_user_connected(id) && !is_user_bot(id));}

public plugin_init( )
{
  register_plugin( "Skillzworld Adminmenu", "1.0", "MrKoala" );
  register_clcmd( "sw_menu",  "adminmenu_deploy", ADMIN_KICK );
  register_clcmd( "say /adminmenu",  "adminmenu_deploy", ADMIN_KICK );

  g_msgScreenFade = get_user_msgid( "ScreenFade" );

  g_iReasons = ArrayCreate( 64 )
  ArrayPushString(g_iReasons, "foul name")
  ArrayPushString(g_iReasons, "No Blocking/Holding")
  ArrayPushString(g_iReasons, "No Spawn* Abuse")
  ArrayPushString(g_iReasons, "No Personal Info")
  ArrayPushString(g_iReasons, "No Excessive Language")
  ArrayPushString(g_iReasons, "No Cheating")
  ArrayPushString(g_iReasons, "impersonating admin/member")
  ArrayPushString(g_iReasons, "No Lagging/Crashing")
}
public plugin_end( )
{
  ArrayDestroy( g_iReasons )
}
/*********[ Functions ]*********/
public client_putinserver(id)
{
  g_iVictim[id] = -1
  g_iAction[id] = -1
  g_iReason[id] = -1
}


public adminmenu_deploy( const id )
{
  if (!is_connected_admin(id, ADMIN_KICK)) return PLUGIN_HANDLED
  g_iVictim[id] = -1  // no victim yet
  g_iReason[id] = -1  // no reason yet
  new menu = menu_create( "\yAdmin menu^n^nChoose a player:", "adminmenu_clicked" );
  new szName[ 32 ], szTempid[ 10 ];
  for (new i = 1; i <= get_maxplayers(); i++)
  {
    if (is_connected_user(i)) {
      get_user_name( i, szName, 31 );
      //num_to_str( get_user_userid(i), szTempid, 9 );
      num_to_str( i, szTempid, 9 );
      menu_additem( menu, szName, szTempid, 0 );
    }
  }
  menu_display( id, menu ); //time out after 60 seconds
  return PLUGIN_HANDLED;
}


public adminmenu_clicked( const id, const menu, const item )
{
    if( item == MENU_EXIT )
    {
        menu_destroy( menu );
        return PLUGIN_HANDLED;
    }

    new data[ 6 ], iName[ 64 ];
    new access, callback;
    menu_item_getinfo( menu, item, access, data,5, iName, 63, callback );

    new tempid = str_to_num( data );
    if( !is_user_bot( tempid ) )
        adminsubmenu_deploy( id, tempid )

    menu_destroy( menu );
    return PLUGIN_HANDLED;
}

public adminsubmenu_deploy(const id, const victim) {
  new szName[ 32 ]
  get_user_name( victim, szName, 31 );
  g_iVictim[ id ] = victim
  new szSubmenuHeader[ 128 ]
  format(szSubmenuHeader,sizeof(szSubmenuHeader)-1,"\yChoose action on^n^n%s:",szName)
  new menu = menu_create( szSubmenuHeader, "adminsubmenu_clicked" );
  menu_additem(menu, "Warning only", "1")           // 1 = Warning
  menu_additem(menu, "Slap", "2")                   // 2 = Slap
  menu_additem(menu, "Slay", "3")                   // 3 = slay
  menu_additem(menu, "Kick", "4")                   // 4 = Kick
  menu_additem(menu, "Gag", "6")                    // 6 = Gag
  menu_additem(menu, "Ban", "7")                    // 7 = Ban
  menu_additem(menu, "Force new nick", "5")         // 5 = Nickname
  menu_display( id, menu ); //time out after 60 seconds
  return PLUGIN_HANDLED;
}

public adminsubmenu_clicked( const id, const menu, const item )
{
  g_iAction[ id ] = -1 // no action defined yet
  if( item == MENU_EXIT )
  {
      menu_destroy( menu );
      return PLUGIN_HANDLED;
  }
  new data[ 6 ], iName[ 64 ];
  new access, callback;
  menu_item_getinfo( menu, item, access, data,5, iName, 63, callback );
  new tempid = str_to_num( data );
  g_iAction[ id ] = tempid
  menu_destroy( menu );

  if (tempid == 5) { //Force a nickchange
    new szSteamid[ 32 ]
    get_user_authid(g_iVictim[id], szSteamid, 31);
    new player = cmd_target(id, szSteamid, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF)
    if (!player) {
      client_cmd(id,"speak ^"access denied^"")
      return PLUGIN_HANDLED;
    }
    util_visualwarning(player, "your nickname was inappropiate")
    client_cmd(player,"speak ^"this is a warning^"")
    util_loginformation(id,player,"inappropiate nickname (now: i am a demon)")
    client_cmd(player, "name ^"i am a demon^"")
    return PLUGIN_HANDLED;
  }

  new szReasonHeader[ 128 ]
  new szName[32]
  get_user_name( g_iVictim[id], szName, 31 );
  format(szReasonHeader,sizeof(szReasonHeader)-1,"\yReason to %s:^n^n%s:",util_getactionname(tempid),szName)

  new reasonsmenu = menu_create( szReasonHeader, "reasonsmenu_clicked" );
  new szTemp[6], szReason[64]
  for( new i; i < ArraySize( g_iReasons ); i++ )
  {
    ArrayGetString(g_iReasons, i, szReason, 63);
    num_to_str(i,szTemp,5)
    menu_additem(reasonsmenu, szReason, szTemp)
  }
  menu_display( id, reasonsmenu );

  return PLUGIN_HANDLED;
}

public reasonsmenu_clicked( const id, const menu, const item )
{
  if( item == MENU_EXIT )
  {
      menu_destroy( menu );
      return PLUGIN_HANDLED;
  }
  new data[ 6 ], iName[ 64 ];
  new access, callback;
  menu_item_getinfo( menu, item, access, data,5, iName, 63, callback );
  new tempid = str_to_num( data );

  if (g_iAction[id] < 0 || g_iVictim[id] < 0)
    return PLUGIN_HANDLED;

  new szReason[ 64 ]
  ArrayGetString(g_iReasons, tempid, szReason, 63);
  g_iReason[id] = tempid

  new szSteamid[ 32 ]
  get_user_authid(g_iVictim[id], szSteamid, 31);

  new player = cmd_target(id, szSteamid, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF)

  if (!player) {
    client_cmd(id,"speak ^"access denied^"")
    return PLUGIN_HANDLED;
  }

  new szNickname[ 32 ]
  get_user_name(player, szNickname, 31)

  switch( g_iAction[id] )
  {
    case 1: // Warn
    {
      util_visualwarning(player, szReason)
      client_cmd(player,"speak ^"this is a warning^"")
      util_loginformation(id,player,szReason)
      util_activity("* %s got warned for: %s",szNickname,szReason)
    }
    case 2: // Slap
    {
      util_visualwarning(player, szReason)
      client_cmd(player,"speak ^"this is not permitted^"")
      util_loginformation(id,player,szReason)
      new szTMP[6]
      num_to_str(player,szTMP,5)
      set_task(0.4, "util_slap",_,szTMP, sizeof(szTMP), "a", 7);
      util_activity("* %s got slapped for: %s",szNickname,szReason)
    }
    case 3: // Slay
    {
      util_visualwarning(player, szReason)
      client_cmd(player,"speak ^"this is not permitted^"")
      util_loginformation(id,player,szReason)
      user_kill(player)
      emit_sound(player, CHAN_ITEM , "ambience/thunder_clap.wav" , 1.0 , ATTN_NORM , 0 , PITCH_NORM)
      new origin[3]
      get_user_origin(player,origin)
      util_explosion(origin)
      util_activity("* %s got slayed for: %s",szNickname,szReason)
    }
    case 4: // Kick
    {
      util_loginformation(id,player,szReason)
      emit_sound(player, CHAN_ITEM , "ambience/thunder_clap.wav" , 1.0 , ATTN_NORM , 0 , PITCH_NORM)
      client_cmd(id,"amx_kick #%i ^"%s^"",get_user_userid(player),szReason)
    }
    case 6: // gag
    {
      durationmenu_deploy(id)
    }
    case 7: // ban
    {
      durationmenu_deploy(id)
    }
  }
  return PLUGIN_HANDLED;
}

public durationmenu_deploy(const id) {
  new szName[ 32 ]
  get_user_name( g_iVictim[ id ], szName, 31 );
  new szSubmenuHeader[ 128 ]
  format(szSubmenuHeader,sizeof(szSubmenuHeader)-1,"\yChoose duration for %s on^n^n%s:",util_getactionname(g_iAction[id]),szName)
  new menu = menu_create( szSubmenuHeader, "durationmenu_clicked" );
  menu_additem(menu, "1h", "60")
  menu_additem(menu, "1d", "1440")
  menu_additem(menu, "3d", "4320")
  menu_additem(menu, "10d", "14400")
  menu_additem(menu, "30d", "43200")
  menu_additem(menu, "perm", "0")
  menu_display( id, menu ); //time out after 60 seconds
  return PLUGIN_HANDLED;
}

public durationmenu_clicked( const id, const menu, const item )
{
  if( item == MENU_EXIT )
  {
      menu_destroy( menu );
      return PLUGIN_HANDLED;
  }
  new data[ 6 ], iName[ 64 ];
  new access, callback;
  menu_item_getinfo( menu, item, access, data,5, iName, 63, callback );
  new tempid = str_to_num( data );

  if (g_iAction[id] < 0 || g_iVictim[id] < 0 || g_iReason[id] < 0)
    return PLUGIN_HANDLED;

  new szReason[ 64 ]
  ArrayGetString(g_iReasons, g_iReason[id], szReason, 63);

  new szSteamid[ 32 ]
  get_user_authid(g_iVictim[id], szSteamid, 31);

  new player = cmd_target(id, szSteamid, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF)

  if (!player) {
    client_cmd(id,"speak ^"access denied^"")
    return PLUGIN_HANDLED;
  }

  new szNickname[ 32 ]
  get_user_name(player, szNickname, 31)

  if (g_iAction[id] == 6) { // gag
    new gagtime = tempid * 60 // gag needs time in seconds
    util_visualwarning(player, szReason)
    util_loginformation(id,player,szReason,gagtime)
    client_cmd(id,"amx_gag #%i %i",get_user_userid(g_iVictim[id]), gagtime)
    util_activity("* %s got gagged for: %s",szNickname,szReason)
  }
  if (g_iAction[id] == 7) { // ban
    util_loginformation(id,player,szReason,tempid)
    //Usage: amx_addban <name> <authid or ip> <time in minutes> <reason>
    client_cmd(id,"amx_addban ^"%s^" ^"%s^" %i ^"%s^"",szNickname,szSteamid, tempid,szReason)
  }
  return PLUGIN_HANDLED;
}

/*********[ Util functions ]*********/
public util_activity(szText[],...) {
  new szActivity[256]
  format_args(szActivity, 255, 0);
  for (new i = 1; i <= get_maxplayers(); i++)
  {
    if (is_connected_user(i))
      client_print(i, print_chat, szActivity)
  }

}
public util_slap(szID[]) {
  new id = str_to_num( szID );
  if (is_user_connected(id)) {
    user_slap(id,0)
    message_begin( MSG_ONE_UNRELIABLE, g_msgScreenFade,{ 0, 0, 0 }, id );
    write_short( 150 );
    write_short( 20 );
    write_short( 0x0001 );
    write_byte( 255 );
    write_byte( 0 );
    write_byte( 0 );
    write_byte( 200 );
    message_end();
  }
}
public util_visualwarning(id, reason[]) {
  message_begin( MSG_ONE_UNRELIABLE, g_msgScreenFade,{ 0, 0, 0 }, id );
  {
    write_short( 500 );
    write_short( 20 );
    write_short( 0x0001 );
    write_byte( 255 );
    write_byte( 0 );
    write_byte( 0 );
    write_byte( 200 );
  }
  message_end();

  set_hudmessage(255, 50, 50, -1.0, -1.0, 0, 0.0, 5.0, 0.0, 0.0, -1)
  show_hudmessage(id, "Adminwarning^n^n%s^n^nPlease play nice and fair",reason)
}
util_loginformation(adminid, victimid, reason[], duration = 0) {

  new szAdmin[ 32 ], szVictim[ 32 ], szAdminid[ 32 ], szVictimid[ 32 ]
  new szHostname[64], szMapname[ 32 ], szTime[ 64 ], szAddr[ 64 ]

  get_user_ip(victimid, szAddr, 63,1);
  get_user_authid(adminid, szAdminid, 31);
  get_user_authid(victimid, szVictimid, 31);
  get_time("%m/%d/%Y - %H:%M:%S", szTime, 63);
  get_mapname(szMapname,31)
  get_cvar_string("hostname", szHostname, 63)
  get_user_name( adminid, szAdmin, 31 );
  get_user_name( victimid, szVictim, 31 );
  console_print(adminid,"^nForum Thread:^n%s ^t %s ^t %s^n",szVictim,szVictimid,szAddr)
  console_print(adminid,"****************************************")
  console_print(adminid,"Server:^t%s",szHostname)
  console_print(adminid,"Map:^t %s (%s)",szMapname,szTime)
  console_print(adminid,"Admin:^t%s | %s", szAdmin,szAdminid)
  console_print(adminid,"Player:^t%s | %s", szVictim,szVictimid)
  console_print(adminid,"IP:^t^t %s", szAddr)
  console_print(adminid,"Reason:^t%s", reason )
  console_print(adminid,"Action:^t%s", util_getactionname(g_iAction[adminid]) )
  if (duration > 0)
    console_print(adminid,"Duration:^t%i", duration )
  console_print(adminid,"****************************************")
  log_amx("-EVILADMIN- %s<%s> %s %s<%s> for %s", szAdmin,szAdminid,util_getactionname(g_iAction[adminid]),szVictim,szVictimid,reason)
}

public util_getactionname(num) {
   new szAction[ 32 ]
   switch( num )
   {
       case 1:
         format(szAction,sizeof(szAction)-1,"warn")
       case 2:
         format(szAction,sizeof(szAction)-1,"slap")
       case 3:
         format(szAction,sizeof(szAction)-1,"slay")
       case 4:
         format(szAction,sizeof(szAction)-1,"kick")
       case 5:
         format(szAction,sizeof(szAction)-1,"forced nickchange")
       case 6:
         format(szAction,sizeof(szAction)-1,"gag")
       case 7:
         format(szAction,sizeof(szAction)-1,"ban")
       default:
        format(szAction,sizeof(szAction)-1,"undefined")
   }
   return szAction
}

public util_explosion( vec1[3] )
{
   //Explosion2
   message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
   write_byte( 12 )
   write_coord(vec1[0])
   write_coord(vec1[1])
   write_coord(vec1[2])
   write_byte( 188 ) // byte (scale in 0.1's) 188
   write_byte( 10 ) // byte (framerate)
   message_end()

   message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1)
   {
     write_byte( 10 )
     write_coord(vec1[0])
     write_coord(vec1[1])
     write_coord(vec1[2])
   }
   message_end()
}
