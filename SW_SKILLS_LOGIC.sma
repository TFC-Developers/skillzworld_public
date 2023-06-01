
#include "include/global"
#include <engine>
#include <fakemeta>
#include "include/utils"
#include "include/api_skills_mapentities"
#include "include/api_skills_mysql"
#include <xs>
#include <tfcx>


//enum to store the player's session data
enum ePlayerSessionData {
    Float:m_fRunStarttime,      //the time when the player touched the start orb
    m_iRunCount,                //how many runs the player has done
    Float:m_fTouchCooldown,     //how many seconds the player has to wait before touching the startball again
    bool:m_bInRun,              //if the player is in a run
    Float:m_fLastHudUpdate,     //the last time the hud was updated
    Float:m_fLastStartTouchHud, //the last time the start touch hud has been shown
    bool:m_bGotCourseInfo,      //if the player has received the course info
    Array:m_touchedCPs,         //array of touched cps
    m_iTotalCPsUsed,            //how many cps the player has used
    bool:m_bCourseFinished,     //if the player has finished the course
    Float:m_fGenericCooldown,   //generic cooldown for various things
    bool:m_bOwnCPs,             //if the player has his own cps / disables all other cps
    Array:m_CustomCPs,          //array of custom cps
    Float:m_fCustomCPsNextDr,   //next time the custom cps should be drawn
    bool:m_bResetConsent,      //if the player has consented to reset his time without menu
    Float:m_fMenuCooldown,      //the cooldown for the menu
    bool:m_bUsedExtras,         //if the player has used extras
    bool:m_bXtraSJ,              //if the player is in super jump mode
    m_iXtraCurCP,               //the current cp the player is in
    bool:m_bAltmodx,            //if the player is using altmodx
    Float:m_fAltmodxCooldown   //the cooldown for altmodx
}

enum eCustomCP {
    Float:m_vOrigin[3],         //the origin of the personal cp
    bool:m_ShouldDraw            //if the cp should be drawn
}
new g_sPlayerData[32][ePlayerSessionData]; 
new g_iThinker;
new g_iIndexSprite;
new g_iIndexClocksprite;
new g_iIndex_Flaremodel; 
new g_iIndex_CPmarker_red;
new g_iIndex_CPmarker_yellow;

new Float:g_fLastClockSpriteUpdate;

new Float:g_flClassDelay[33];                           //amxmodx delay for classmenu 

new const CHECKPOINT_SOUND[] = "misc/cpoint.wav"
new const CLOCK_SPRITE[] = "sprites/clocktag.spr"
new const CP_MARKER_RED[] = "models/skillzworld/cpmarker.spr"
new const CP_MARKER_YELLOW[] = "models/skillzworld/cpmarker1.spr"


public plugin_init() {
    RegisterPlugin();
    register_forward(FM_Touch, "pub_cptouch");
    register_forward(FM_Think, "pub_skillsthink");
    register_forward(FM_AddToFullPack, "Hook_AddToFullPack",1);
    register_think("spawn_thinker", "pub_skillsthink");
    register_clcmd("say /reset", "menu_resetconsent");
    register_clcmd("say /r", "menu_resetconsent");
    register_clcmd("say /load", "pub_loadlastcp");
    register_clcmd("say_team /load", "pub_loadlastcp");
    register_clcmd("say load", "pub_loadlastcp");
    register_clcmd("say /l", "pub_loadlastcp");
    register_clcmd("say_team /l", "pub_loadlastcp"); 
    register_clcmd("say /undo", "pub_undo");
    register_clcmd("say /u", "pub_undo");
    register_clcmd("say /stop", "pub_stoprun");
    register_clcmd("say /s", "pub_savecustomcp");
    register_clcmd("say /save", "pub_savecustomcp");
    register_clcmd("say /savecp", "pub_savecustomcp");
    register_clcmd("say save", "pub_savecustomcp");
    register_clcmd("say /mapcps", "pub_mapcps");
    register_clcmd("say /extras", "menu_extras_deploy");
    register_clcmd("say /setmedone", "pub_setmedone");
    register_clcmd("say", "hook_say");                                      //hook for altmodx functionalitieis
    register_forward(FM_PlayerPreThink, "Hook_PlayerPreThink",0);
    set_task(5.0, "spawn_thinker"); 
    g_iThinker = 0;
}
public plugin_precache() {
    precache_sound(CHECKPOINT_SOUND);
    g_iIndexSprite = precache_model("sprites/lgtning.spr")
    g_iIndex_Flaremodel = precache_model("sprites/flare6.spr");
    precache_sound("misc/party1.wav");
    g_iIndexClocksprite = precache_model(CLOCK_SPRITE);
    g_iIndex_CPmarker_red = precache_model(CP_MARKER_RED);
    g_iIndex_CPmarker_yellow = precache_model(CP_MARKER_YELLOW);

    //altmodx precaches
	precache_sound("items/protect.wav");
	precache_sound("items/protect2.wav");
	precache_sound("items/protect3.wav");
	precache_sound("FVox/HEV_logon.wav");
	precache_sound("FVox/hev_shutdown.wav");
	precache_sound("items/inv1.wav");
	precache_sound("items/inv2.wav");
	precache_sound("items/inv3.wav");
	precache_sound("items/damage.wav");
	precache_sound("items/damage2.wav");
	precache_sound("items/damage3.wav");
    //end of altmodx precaches

}
public plugin_natives() {
	register_library "api_skills_actions"
	register_native "reset_run", "Native_ResetRun"
	register_native "load_checkpoint", "Native_LoadCheckpoint"
	register_native "set_custom_checkpoint", "Native_SetCustomCheckpoint"
}
public Native_ResetRun(iPlugin, iParams) {
	menu_resetconsent get_param(1)
}
public Native_LoadCheckpoint(iPlugin, iParams) {
	pub_loadlastcp get_param(1)
}
public Native_SetCustomCheckpoint(iPlugin, iParams) {
	pub_savecustomcp get_param(1)
}


public pub_setmedone(id) {
    if (!is_connected_admin(id)) {
        client_print(id, print_chat, "* You are not an admin");
        return PLUGIN_HANDLED;
    }

    g_sPlayerData[id][m_bCourseFinished] = true;
    client_cmd(id, "spk \"ok run is over\"\n");
    client_print(id, print_chat, "* Done");
    return PLUGIN_HANDLED
}
public pub_stoprun(id) {
    if (!g_sPlayerData[id][m_bInRun]) {
        client_print(id, print_chat, "* You are not in a run");
        return;
    }
    g_sPlayerData[id][m_bInRun] = false;
    g_sPlayerData[id][m_fRunStarttime] = 0.0;

    client_cmd(id, "spk \"reset ok\"\n");
    client_print(id, print_chat, "* Your timer has been reset. Have fun on the course!");
    
    set_hudmessage(255, 0, 0, -1.0, 0.35, 0, 0.0, 1.0, 0.0, 0.0,13);
    show_hudmessage(id,"Stopped run...");
}
public reset_struct(id) {
    //reset the player's session data
    g_sPlayerData[id][m_fRunStarttime] = 0.0;
    g_sPlayerData[id][m_iRunCount] = 0;
    g_sPlayerData[id][m_fTouchCooldown] = 0.0;
    g_sPlayerData[id][m_bInRun] = false;
    g_sPlayerData[id][m_fLastHudUpdate] = 0.0;
    g_sPlayerData[id][m_fLastStartTouchHud] = 0.0;
    g_sPlayerData[id][m_bGotCourseInfo] = false;
    ArrayDestroy(g_sPlayerData[id][m_touchedCPs]); g_sPlayerData[id][m_touchedCPs] = Invalid_Array;
    ArrayDestroy(g_sPlayerData[id][m_CustomCPs]); g_sPlayerData[id][m_CustomCPs] = Invalid_Array;
    g_sPlayerData[id][m_iTotalCPsUsed] = 0; 
    g_sPlayerData[id][m_bCourseFinished] = false;
    g_sPlayerData[id][m_fGenericCooldown] = 0.0;
    g_sPlayerData[id][m_bOwnCPs] = false;
    g_sPlayerData[id][m_fCustomCPsNextDr] = 0.0;
    g_sPlayerData[id][m_bResetConsent] = false;
    g_sPlayerData[id][m_fMenuCooldown] = 0.0;
    g_sPlayerData[id][m_bUsedExtras] = false;
    g_sPlayerData[id][m_bXtraSJ] = false;
    g_sPlayerData[id][m_iXtraCurCP] = 0;
    g_sPlayerData[id][m_bAltmodx] = false;
    g_sPlayerData[id][m_fAltmodxCooldown] = 0.0;
}

public client_connect(id) {
    reset_struct(id);
}
public client_disconnected(id) {
    reset_struct(id);
}
public menu_resetconsent(id) {
    if (g_sPlayerData[id][m_bResetConsent]) { pub_reset(id); return PLUGIN_HANDLED; }           //reset the player's time since he consented to it
    new oldMenuId, newMenuId; player_menu_info(id, oldMenuId, newMenuId);                                                                                       //get the player's menu id he is currently in
    if (oldMenuId >= 1) { return PLUGIN_HANDLED; }                                                                                                              //return if the player is in a menu
    //if (g_sPlayerData[id][m_fMenuCooldown] > get_gametime()) { return PLUGIN_HANDLED; }                                                                         //return if the player is in a menu cooldown
    g_sPlayerData[id][m_fMenuCooldown] = get_gametime() + 1.5;                                                                                                  //set the menu cooldown to 5 seconds

    new szMenu[256]; formatex(szMenu, charsmax(szMenu), "\\wDo you want to \\rreset\\w your \ncurrent timer and start over?\n\nNote: checkpoints will be reset if you start over\nif you just want to continue checkpoints wont be reset\n");
    new menu = menu_create( szMenu, "consentmenu_clicked" );
    menu_additem( menu, "Yes! (CPs will be reset!)", "1" );
    menu_additem( menu, "Just reset timer! (let me continue map)", "2" );
    menu_additem( menu, "Reset+TP to Start and dont ask again", "3" );
    menu_additem( menu, "No!", "4" );
    menu_display( id, menu ); //time out after 60 seconds
    return PLUGIN_HANDLED;
}

public consentmenu_clicked( const id, const menu, const item )
{
    if( item == MENU_EXIT )
    {
        menu_destroy( menu );
        return PLUGIN_HANDLED;
    }

    new data[ 6 ], iName[ 64 ];
    new access, callback;
    menu_item_getinfo( menu, item, access, data,5, iName, 63, callback );
    new iDecision = str_to_num( data );
    switch(iDecision) {
        case 1:                                                            // reset the timer and the cps (Choice: "Yes!")
        {
            pub_reset(id);
        }
        case 2:                                                             // reset the timer (Choice: "Just reset the timer")
        {
            pub_stoprun(id);
        }
        case 3:                                                             // reset the timer and teleport to start (Choice: "Reset+TP to Start and dont ask again")
        {
            g_sPlayerData[id][m_bResetConsent] = true;
            pub_reset(id);
        }
        case 4:                                                             // do nothing (Choice: "No!")
        {
        }
        default:                                                            // do nothing 
        {
        }
    }
    menu_destroy( menu );
    return PLUGIN_HANDLED;
}


public pub_mapcps(id) {
    //return if not in customcps mode
    if (!g_sPlayerData[id][m_bOwnCPs]) {
        client_print(id, print_chat, "* You are not in custom cps mode. Save at least one custom cp (say /s) to enter this mode.");
        return PLUGIN_HANDLED;
    }
    g_sPlayerData[id][m_bOwnCPs] = false;
    ArrayDestroy(g_sPlayerData[id][m_CustomCPs]); g_sPlayerData[id][m_CustomCPs] = Invalid_Array;
    client_print(id, print_chat, "* Custom cps mode disabled. Say /s again to re-enable it. The counter of used cps has not been reset.");
    return PLUGIN_HANDLED;
}
public pub_savecustomcp(id) {
    if (g_sPlayerData[id][m_CustomCPs] == Invalid_Array) {
        g_sPlayerData[id][m_CustomCPs] = ArrayCreate(eCustomCP);
    }

    if (get_user_team(id) < 1 || get_user_team(id) > 4) {
        client_print(id, print_chat, "* You are not in a valid team");
        return PLUGIN_HANDLED;
    }

    new Float:velocity[3];
    pev(id, pev_velocity, velocity);
    /*Discussion: Should we allow saving cps while the player is moving?
    if (floatround(floatsqroot(floatadd(floatadd(floatmul(velocity[0], velocity[0]), floatmul(velocity[1], velocity[1])), floatmul(velocity[2], velocity[2]))), floatround_floor) > 10.0) {
        client_print(id, print_chat, "* You are moving too fast to save a custom cp");
        return;
    }*/
    if (!(pev(id, pev_flags) & FL_ONGROUND)) {
        client_print(id, print_chat, "* You are not on the ground");
        return PLUGIN_HANDLED;
    }

    if (!g_sPlayerData[id][m_bOwnCPs]) {
        g_sPlayerData[id][m_bOwnCPs] = true;
        client_print(id, print_chat, "* The predefined cps have been disabled for you. To re-enable them, type /mapcps to switch back");
    }

    //get the player's origin
    new Float:origin[3];
    pev(id, pev_origin, origin);

    new Buffer[eCustomCP];
    Buffer[m_vOrigin][0] = origin[0];
    Buffer[m_vOrigin][1] = origin[1];
    Buffer[m_vOrigin][2] = origin[2];
    Buffer[m_ShouldDraw] = true;
    ArrayPushArray(g_sPlayerData[id][m_CustomCPs], Buffer);
    client_print(id, print_chat, "* Your current position has been saved as a custom cp. Say /load to load it");
    return PLUGIN_HANDLED;

}
public draw_customcps(id) {
    if (!g_sPlayerData[id][m_bOwnCPs]) { return; }                          //return if not in custom cps mode
    if (g_sPlayerData[id][m_fCustomCPsNextDr] > get_gametime()) { return; } //return if not time to draw
    if (g_sPlayerData[id][m_CustomCPs] == Invalid_Array) { return; }        //return if no custom cps
    
    g_sPlayerData[id][m_fCustomCPsNextDr] = get_gametime() + 1.1;           //set the next time to draw
    new Float:origin[3]; pev(id, pev_origin, origin);                       //get the player's origin
    new iCount = ArraySize(g_sPlayerData[id][m_CustomCPs]);                 //get the amount of custom cps
    if (iCount == 0) { return; }                                            //return if no custom cps
    new Buffer[eCustomCP];                                                  

    for (new i = iCount-1; i >= 0; i--) {
        ArrayGetArray(g_sPlayerData[id][m_CustomCPs], i, Buffer);
        if (i == iCount-1) {
            message_begin(MSG_ONE, SVC_TEMPENTITY, .player = id);
            {
                write_byte(TE_SPRITE);
                write_coord_f(Buffer[m_vOrigin][0]);
                write_coord_f(Buffer[m_vOrigin][1]);
                write_coord_f(Buffer[m_vOrigin][2]);
                write_short(g_iIndex_CPmarker_yellow);
                write_byte(0);
                write_byte(150);
            }
            message_end();
        } else if (i < iCount-1 && i >= iCount-6){
            message_begin(MSG_ONE, SVC_TEMPENTITY, .player = id);
            {
                write_byte(TE_SPRITE);
                write_coord_f(Buffer[m_vOrigin][0]);
                write_coord_f(Buffer[m_vOrigin][1]);
                write_coord_f(Buffer[m_vOrigin][2]);
                write_short(g_iIndex_CPmarker_red);
                write_byte(0);
                write_byte(150);
            }
            message_end();
        }
    }
}
public spawn_thinker() {
    if (g_iThinker != 0) { return; }                                                             //return if thinker already exists    
    new entity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target")) // create the entity
    entity_set_string(entity, EV_SZ_classname, "sw_skillsthink");                                // set the classname
    entity_set_float(entity, EV_FL_nextthink, (get_gametime() + 0.1) );                          // set the nextthink
    g_iThinker = entity;                                                                         // set the global thinker 
}

public pub_skillsthink(id) {
    if (g_iThinker == 0 || g_iThinker != id) { return FMRES_HANDLED; }
    
    entity_set_float(id, EV_FL_nextthink, (get_gametime() + 0.09) );                            // set the nextthink
    for (new i = 1; i <= 32; i++) {                                                             // loop through all players
        if (is_connected_user(i) && pev(i, pev_team) >= 1 && pev(i, pev_team) <= 4) {
            update_hud(i);
            draw_customcps(i);
            
            if (g_fLastClockSpriteUpdate < get_gametime()) {
                draw_clocksprite(i);
                g_fLastClockSpriteUpdate = get_gametime() + 1;
            }
        }
    }
    return FMRES_HANDLED;
}
public update_hud(id) {
    new iStatusMessage = get_user_msgid("StatusText");
    if (!g_sPlayerData[id][m_bInRun] && g_sPlayerData[id][m_iTotalCPsUsed] > 0) {
        new szMsg[128];
        formatex(szMsg, charsmax(szMsg), "Checkpoints used: %d", g_sPlayerData[id][m_iTotalCPsUsed]);
        message_begin(MSG_ONE, iStatusMessage, .player = id);
        write_byte(1);
        write_string(szMsg);
        message_end();
        return;
    }

    if (get_user_team(id) < 1 || get_user_team(id) > 4 || !g_sPlayerData[id][m_bInRun] || g_sPlayerData[id][m_bCourseFinished]) {
        message_begin(MSG_ONE, iStatusMessage, .player = id);
        write_byte(1);
        write_string("");
        message_end();       
        return;
    }

    if (iStatusMessage == 0) {
        return;
    }
    new Float:fTime = floatsub(get_gametime(), g_sPlayerData[id][m_fRunStarttime]);
    new iTotalSeconds = floatround(fTime, floatround_floor); new iHours = iTotalSeconds / 3600; new iSeconds = iTotalSeconds % 60; new iMinutes = iTotalSeconds / 60; new iMillis = floatround(fTime*100.0, floatround_floor) % 100;

    // check when the hud was last updated and fire function
    if (g_sPlayerData[id][m_fLastHudUpdate] < get_gametime()) {
        g_sPlayerData[id][m_fLastHudUpdate] = get_gametime() + 0.25;
        new szBigHudTXT[128];
        if (iHours > 0) {
            formatex(szBigHudTXT, charsmax(szBigHudTXT), "%02d:%02d:%02d", iHours, iMinutes, iSeconds);
        } else {
            formatex(szBigHudTXT, charsmax(szBigHudTXT), "%02d:%02d", iMinutes, iSeconds);
    
        }
        message_begin(MSG_ONE, SVC_TEMPENTITY, .player = id);
        {
            write_byte(TE_TEXTMESSAGE);
            write_byte( 1 );
            write_short( clamp(-1*(1<<13), -32768, 32767) );
            write_short( clamp(floatround(0.92*float(1<<13), floatround_floor), -32768, 32767) );
            write_byte( 1 ); // Effect
            write_byte( 0 ); // R
            write_byte( 255 ); // G
            write_byte( 0 ); // B
            write_byte( 0 ); // Alpha
            write_byte( 0 ); // Effect R
            write_byte( 0 ); // Effect G
            write_byte( 0 ); // Effect B
            write_byte( 0 ); // Effect Alpha
            write_short( clamp(0*(1<<8), 0, 65535) );
            write_short( clamp(0*(1<<8), 0, 65535) );
            write_short( clamp(120*(1<<8), 0, 65535) );
            write_string(szBigHudTXT);
        }
        message_end();
    }

    new szMsg[128];
    if (iHours > 0) {
        formatex(szMsg, charsmax(szMsg), "Timer: %02d:%02d:%02d.%02d", iHours, iMinutes, iSeconds, iMillis);
    } else if (iMinutes > 0) {
        formatex(szMsg, charsmax(szMsg), "Timer: %02d:%02d.%02d", iMinutes, iSeconds, iMillis);
    } else {
        formatex(szMsg, charsmax(szMsg), "Timer: %02d.%02d", iSeconds, iMillis);
    }

    if (g_sPlayerData[id][m_iTotalCPsUsed] == 1) {
        formatex(szMsg, charsmax(szMsg), "%s (%d cp used)", szMsg, g_sPlayerData[id][m_iTotalCPsUsed]);
    } else if (g_sPlayerData[id][m_iTotalCPsUsed] > 1) {
        formatex(szMsg, charsmax(szMsg), "%s (%d cps used)", szMsg, g_sPlayerData[id][m_iTotalCPsUsed]);
    }

    message_begin(MSG_ONE, iStatusMessage, .player = id);
    write_byte(1);
    write_string(szMsg);
    message_end();
}


public pub_cptouch(touched, toucher) {
    new szClass[32];
    new szClassToucher[32];
    if (is_valid_ent(touched) == 0 || is_valid_ent(toucher) == 0) {
        return;
    }
    entity_get_string(touched, EV_SZ_classname, szClass, charsmax(szClass));
    entity_get_string(toucher, EV_SZ_classname, szClassToucher, charsmax(szClassToucher));
    if (!equali(szClass, "sw_checkpoint") || !equali(szClassToucher, "player")) {
        return;
    }
    //check if he is allowed to touch the entity no matter what type it is
    if (pev(touched,pev_iuser2) != api_get_player_course(toucher)) {                    //check if the player is on the same course as the checkpoint
        return;                                                                         //if not, return
    }   

    if (pev(touched, pev_iuser1) == 0) {                                                //check if the checkpoint is a start orb (0 = start orb, 1 = checkpoint, 2 = finish orb)
        //don't sed the menu if:
        if (g_sPlayerData[toucher][m_bUsedExtras] && g_sPlayerData[toucher][m_fGenericCooldown] < get_gametime()) { 
            client_print(toucher, print_chat, "* You can't do this, since you used extras to get here. User your /extras menu to suicide and start over.");
            g_sPlayerData[toucher][m_fGenericCooldown] = get_gametime() + 10.0;                                                    //set the player's touchcooldown to 2 seconds
            return;
        } //because player used extras 
        if (g_sPlayerData[toucher][m_bUsedExtras]) { return; }

        if (g_sPlayerData[toucher][m_bInRun]                                            //check if the player is in a run
            && ((g_sPlayerData[toucher][m_fRunStarttime] + 2.0) <= get_gametime())      //check if the player has touched the start orb at least 2 seconds ago
            && !g_sPlayerData[toucher][m_bResetConsent]) {                              //check if the player has consented to reset his time without menu
            menu_resetconsent(toucher);                                                 //ask the player if he wants to reset his time and if consented, reset it
        } else {                                                                        //if the player is not in a run
            pub_sub_starttouch(touched, toucher);                                       //start the run
        }
    } 
    if ((pev(touched, pev_iuser1) == 1) && !(g_sPlayerData[toucher][m_bCourseFinished])) {
        pub_sub_cptouch(touched, toucher);
    }
    if (pev(touched, pev_iuser1) == 2) {
        pub_sub_endtouch(touched, toucher);
    }
 
}

public pub_sub_endtouch(touched, toucher) {
    if (g_sPlayerData[toucher][m_bCourseFinished]) { return FMRES_HANDLED; }                                  //return if the player has already finished the course  
    /*if (g_sPlayerData[toucher][m_bAltmodx]) {
        if (g_sPlayerData[toucher][m_fAltmodxCooldown] < get_gametime()) {
            client_print(toucher, print_chat, "* You can't finish this run since you used the /give command. Say /reset to start over or touch the start.");
            g_sPlayerData[toucher][m_fAltmodxCooldown] = get_gametime() + 10.0; 
        }
            return FMRES_HANDLED;           
    }*/
    if (api_is_team_allowed(toucher,touched)) {                                                 //check if the player is in the correct team to touch this cp
        new Float:fTime = floatsub(get_gametime(), g_sPlayerData[toucher][m_fRunStarttime]);    //get the player's time
        if (g_sPlayerData[toucher][m_bInRun] == false) { fTime = 0.0; }                         // he completed the map without being in a run
        g_sPlayerData[toucher][m_bCourseFinished] = true;                                       //set the player's course finished to true
        new szName[32]; get_user_name(toucher, szName, charsmax(szName));                       //get the player's name
        new szBigHudTXT[128]; new szCourseName[32]; new iCourseID; new szChatTXT[128];          //declare some strings
        iCourseID = pev(touched, pev_iuser2);                                                   //get the course id
        new iCPCount = g_sPlayerData[toucher][m_iTotalCPsUsed];                                 //get the player's total cp count (cps used)
        api_get_coursename(iCourseID, szCourseName, charsmax(szCourseName));
        g_sPlayerData[toucher][m_bInRun] = false; //set the player's inrun to false
        if (fTime > 0.0) {
            new iTotalSeconds = floatround(fTime, floatround_floor), iCentis = floatround(fTime*100.0, floatround_floor) % 100;
            new iHours = iTotalSeconds / (60*60), iTotalMinutes = iTotalSeconds / 60
            new iMinutes = iTotalMinutes % 60, iSeconds = iTotalSeconds % 60
            formatex(szChatTXT, charsmax(szChatTXT), "* %s finished the course %s in %02d:%02d:%02d.%02d (%d cps used)", szName, szCourseName, iHours, iMinutes, iSeconds, iCentis, g_sPlayerData[toucher][m_iTotalCPsUsed]);
            if (iHours > 0) {
                formatex(szBigHudTXT, charsmax(szBigHudTXT), "Congratulations %s!\n\nYou finished the course %s in %02d:%02d:%02d\n\nSay /reset to start over.", szName, szCourseName, iHours, iMinutes, iSeconds, iCentis);
            } else {
                formatex(szBigHudTXT, charsmax(szBigHudTXT), "Congratulations %s!\n\nYou finished the course %s in %02d:%02d.%02d\n\nSay /reset to start over.", szName, szCourseName, iMinutes, iSeconds, iCentis);
            }
        } else {
            new bUsedAmx = g_sPlayerData[toucher][m_bAltmodx];
            formatex(szChatTXT, charsmax(szChatTXT), "* %s finished the course %s (%d cps used).%s", szName, szCourseName, iCPCount, bUsedAmx ? " They used /give." : "");
            formatex(szBigHudTXT, charsmax(szBigHudTXT), "Congratulations %s!\n\nYou finished the course %s \n\nSay /reset to start over.", szName, szCourseName);
        }
        // play sound
        //			sprintf(sound, "speak \"sound/misc/party1.wav\"\n");
        client_cmd(0, "speak \"sound/misc/party1.wav\"\n");
        new iMysqlCourseID = api_get_course_mysqlid(iCourseID);
        client_print(0, print_chat, szChatTXT);
        api_sql_insertrun(toucher, fTime, iMysqlCourseID, iCPCount, g_sPlayerData[toucher][m_bAltmodx]);
        set_hudmessage(200,100,0,-1.0, 0.35, 0, 0.0, 19.0, 1.0, 0.0, 2);
        show_hudmessage(0, szBigHudTXT);

        SkillsEffectGoalTouch(toucher, true, g_iIndexSprite, g_iIndex_Flaremodel);
        message_begin(MSG_ONE, SVC_TEMPENTITY, .player = toucher);
        {
            write_byte(TE_TEXTMESSAGE);
            write_byte( 1 );
            write_short( clamp(-1*(1<<13), -32768, 32767) );
            write_short( clamp(floatround(floatmul(0.92, float(1<<13)), floatround_floor), -32768, 32767) );
            write_byte( 1 ); // Effect
            write_byte( 0 ); // R
            write_byte( 255 ); // G
            write_byte( 0 ); // B
            write_byte( 0 ); // A
            write_byte( 0 ); // Effect R
            write_byte( 0 ); // Effect G
            write_byte( 0 ); // Effect B
            write_byte( 0 ); // Effect A
            write_short( clamp(0*(1<<8), 0, 65535) );
            write_short( clamp(0*(1<<8), 0, 65535) );
            write_short( clamp(120*(1<<8), 0, 65535) );
            write_string("");
        }
        message_end();         
    } else if (g_sPlayerData[toucher][m_fGenericCooldown] < get_gametime()) {
        g_sPlayerData[toucher][m_fGenericCooldown] = get_gametime() + 10.0;
        client_print(toucher, print_chat, "* Your team is not allowed to participate in this course");  
        client_cmd(toucher, "spk \"no access\"\n");
        return FMRES_HANDLED;
    }

}
public pub_sub_cptouch(touched, toucher) {
    if (!api_is_team_allowed(toucher,touched)) { return; }          //return if the player is not in the correct team to touch this cp
    if (g_sPlayerData[toucher][m_bOwnCPs]) { return; }              //return if the player is in custom cps mode
    if (did_touch_cp(toucher,touched)) { return; }                  //return if the player has already touched this cp

    add_touched_cp(toucher, touched);                               //add the touched cp to the player's touched cp array
    client_cmd( toucher, "spk \"%s\"\n", CHECKPOINT_SOUND);         //play the checkpoint sound

    new iTotalCPsTouched = ArraySize(g_sPlayerData[toucher][m_touchedCPs]);
    new iTotalCPsinCourse = api_get_totalcps(pev(touched, pev_iuser2));
    client_print(toucher, print_chat, "* You touched a total of %d cps (max: %d), say /undo or /u to undo this.", iTotalCPsTouched, iTotalCPsinCourse);
}

public pub_sub_starttouch(touched, toucher) {
    if (g_sPlayerData[toucher][m_fTouchCooldown] > get_gametime()) {
        return FMRES_HANDLED;
    }
    if (api_is_team_allowed(toucher,touched)) {
/*
    if (g_sPlayerData[toucher][m_bAltmodx]) {
        if (g_sPlayerData[toucher][m_fAltmodxCooldown] < get_gametime()) {
            client_print(toucher, print_chat, "* You can't finish this run since you used the /give command. Say /reset to start over or touch the start.");
            g_sPlayerData[toucher][m_fAltmodxCooldown] = get_gametime() + 10.0; 
        }
            return FMRES_HANDLED;           
    }*/
        ArrayDestroy(g_sPlayerData[toucher][m_touchedCPs]);                                                                 //destroy the player's touched cp array
        ArrayDestroy(g_sPlayerData[toucher][m_CustomCPs]); g_sPlayerData[toucher][m_CustomCPs] = Invalid_Array;             //destroy the player's custom cp array
        g_sPlayerData[toucher][m_touchedCPs] = ArrayCreate(1);                                                              //create a new touched cp array
        g_sPlayerData[toucher][m_bInRun] = true;                                                                            //set the player's inrun to true
        g_sPlayerData[toucher][m_fRunStarttime] = get_gametime();                                                           //set the player's runstarttime to the current gametime
        g_sPlayerData[toucher][m_iRunCount] += 1;                                                                           //increase the player's runcount by 1
        g_sPlayerData[toucher][m_fTouchCooldown] = get_gametime() + 2.0;                                                    //set the player's touchcooldown to 2 seconds
        g_sPlayerData[toucher][m_iTotalCPsUsed] = 0;                                                                        //set the player's totalcpsused to 0
        g_sPlayerData[toucher][m_bOwnCPs] = false;                                                                          //set the player's owncps to false
        g_sPlayerData[toucher][m_bCourseFinished] = false;                                                                  //set the player's coursefinished to false

        if (!g_sPlayerData[toucher][m_bGotCourseInfo]) {
            g_sPlayerData[toucher][m_bGotCourseInfo] = true;
            new szCourseName[32]; new szCourseDescription[128];
            api_get_coursename(pev(touched, pev_iuser2), szCourseName, charsmax(szCourseName));
            api_get_coursedescription(pev(touched, pev_iuser2), szCourseDescription, charsmax(szCourseDescription));
            client_print(toucher, print_chat, "* Run started on course %s", szCourseName);
            client_print(toucher, print_chat, "* Course description: %s", szCourseDescription);
        }

        client_cmd(toucher, "spk \"one two three go\"\n");

        if (g_sPlayerData[toucher][m_fLastStartTouchHud] < get_gametime()) {
            g_sPlayerData[toucher][m_fLastStartTouchHud] = get_gametime() + 30.0;
            set_hudmessage(0,255,0,-1.0, 0.20, 0, 0.0, 15.0, 1.0, 0.0, 3);
            show_hudmessage(toucher, "Speedrun timer started!\n\nType /reset if you want to start over.\nYour time can only be saved once per map cycle.");
        }

        update_hud(toucher);

    } else if (g_sPlayerData[toucher][m_fGenericCooldown] < get_gametime()) {
        g_sPlayerData[toucher][m_fGenericCooldown] = get_gametime() + 10.0;
        client_print(toucher, print_chat, "* Your team is not allowed to participate in this course");  
        client_cmd(toucher, "spk \"no access\"\n");
        return FMRES_HANDLED;
    }
    return FMRES_HANDLED
}

public pub_undo(id) {

    if (g_sPlayerData[id][m_bOwnCPs]) {
        new iSize = ArraySize(g_sPlayerData[id][m_CustomCPs]);
        if (iSize == 0) {
            client_print(id, print_chat, "* You have not saved any custom cps yet");
            return PLUGIN_HANDLED;
        }
        if (!is_user_alive(id)) {
            client_print(id, print_chat, "* You have to respawn first in order to use your last cp");
            return PLUGIN_HANDLED;
        }
        ArrayDeleteItem(g_sPlayerData[id][m_CustomCPs], iSize - 1);
        client_print(id, print_chat, "* Your last saved custom cp has been removed");
        pub_loadlastcp(id);
        return PLUGIN_HANDLED;
    }
    // if the player is not in custom cps mode, remove the last touched cp
    if (g_sPlayerData[id][m_touchedCPs] == Invalid_Array) {
        client_print(id, print_chat, "* You have not touched any cps yet");
        return PLUGIN_HANDLED;
    }
    new iSize = ArraySize(g_sPlayerData[id][m_touchedCPs]);
    if (iSize == 0) {
        client_print(id, print_chat, "* You have not touched any cps yet");
        return PLUGIN_HANDLED;
    }
    if (iSize == 1) {
        client_print(id, print_chat, "* You reached your first saved cp");
        return PLUGIN_HANDLED;
    }
    if (!is_user_alive(id)) {
        client_print(id, print_chat, "* You have to respawn first in order to use your last cp");
        return PLUGIN_HANDLED;
    }
    ArrayDeleteItem(g_sPlayerData[id][m_touchedCPs], iSize - 1);
    pub_loadlastcp(id);
    return PLUGIN_HANDLED;
}
public pub_loadlastcp(id) {

    if (!is_user_alive(id)) {
        client_print(id, print_chat, "* You have to respawn first in order to use your last cp");
        return PLUGIN_HANDLED;
    }
    new Float:fOrigin[3]; fOrigin = Float:{0.0, 0.0, 0.0};

    if (g_sPlayerData[id][m_bOwnCPs]) {
        new iSize = ArraySize(g_sPlayerData[id][m_CustomCPs]);
        new Buffer[eCustomCP];
        if (iSize == 0) {
            client_print(id, print_chat, "* You have not saved any custom cps yet");
            return PLUGIN_HANDLED;
        }
        ArrayGetArray(g_sPlayerData[id][m_CustomCPs], iSize - 1, Buffer);
        fOrigin[0] = Buffer[m_vOrigin][0];
        fOrigin[1] = Buffer[m_vOrigin][1];
        fOrigin[2] = Buffer[m_vOrigin][2];
    } else {
        if (g_sPlayerData[id][m_touchedCPs] == Invalid_Array) {
            client_print(id, print_chat, "* You have not touched any cps yet");
            return PLUGIN_HANDLED;
        }
        new iSize = ArraySize(g_sPlayerData[id][m_touchedCPs]);
        new iLastCP = 0;

        if (iSize == 0) {
            client_print(id, print_chat, "* You have not touched any cps yet");
            return PLUGIN_HANDLED;
        }
        iLastCP = ArrayGetCell(g_sPlayerData[id][m_touchedCPs], iSize - 1);
        new szClass[32];
        entity_get_string(iLastCP, EV_SZ_classname, szClass, charsmax(szClass));
        if (!equali(szClass, "sw_checkpoint")) {
            client_print(id, print_chat, "* Something weird happened here.. please report this to an admin [error: 1]");
            return PLUGIN_HANDLED;
        }
        entity_get_vector(iLastCP, EV_VEC_origin, fOrigin);                             //get the origin of the cp
    }

    if (fOrigin[0] == 0.0 && fOrigin[1] == 0.0 && (fOrigin[2] == 20.0 || fOrigin[2] == 5.0)) {
        client_print(id, print_chat, "* Something weird happened here.. please report this to an admin [error: 3]");
        return PLUGIN_HANDLED;
    }
    //// This position adjustment is necessary for now, as the premade checkpoints in the database have their centre points glued to the floor rather than represent a player position,
    //// which causes a teleported player's hitbox to intersect with slopes and get stuck. These checkpoints need to be fixed so this patch can be removed.
    //// This position adjustment is at odds with the FL_DUCKING flag below, it will not be possible to load a checkpoint made while crouched while it's here.
    fOrigin[2] += 20.0;
    
    CreateTeleportEffect(id,g_iIndexSprite);                                            //create teleport effect
    emit_sound(id, CHAN_ITEM, "misc/teleport_out.wav", 0.5, ATTN_NORM, 0, PITCH_HIGH);  //play teleport sound
    
    //// Setting the player to crouched fixes bug where a standing player loads a crouched cp and gets stuck.
    //// Example: Crouching under one of the very first jumps in the-climb and using a custom checkpoint
    //// Visual bug: loading a crouched checkpoint makes your view height higher than it should be, though the hitbox is correct (so you can jump and peek through the world geometry).
    ////    Probably caused by being stood on one frame and crouched on the next, it tries to do an animated transition so you get a half-half view height
    set_pev id, pev_flags, pev(id, pev_flags) | FL_DUCKING
    
    entity_set_vector(id, EV_VEC_velocity, Float:{0.0, 0.0, 0.0});                      //reset velocity / momentum
    stock_teleport(id, fOrigin);                                                        //teleport the player to the cp
    g_sPlayerData[id][m_iTotalCPsUsed] += 1;                                            //add 1 to the total cp used counter
    return PLUGIN_HANDLED;
}
public pub_reset(id) {
	/* discussion: should we allow resetting if the player has not started a run yet?
	if (g_sPlayerData[id][m_iCourseID] == 0) {
		client_print(id, print_chat, "* You have not started a run yet");
		return;
	}*/

    if (g_sPlayerData[id][m_bAltmodx]) {
        PowerUp(id, 0, "1");
        g_sPlayerData[id][m_bAltmodx] = false;
    }

	new ent;
	ent = -1;
	new eSearch = -1;
	while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "sw_checkpoint"))) {
		if(!pev_valid(ent) || pev(ent, pev_iuser2) != api_get_player_course(id)) continue;
		
		if (pev(ent, pev_iuser1) == 0) {
			eSearch = ent;
			break;
		}
	}  
	//check if ent is valid
	if (!pev_valid(eSearch)) {
		client_print(id, print_chat, "* Something weird happened here.. did you already start a run? [error: 2]");
		return;
	}
	//reset his run
	g_sPlayerData[id][m_bInRun] = false;
	g_sPlayerData[id][m_fRunStarttime] = 0.0;
	g_sPlayerData[id][m_fTouchCooldown] = 0.0;
	new Float:fOrigin[3];                                           //create a new origin vector
	pev(eSearch, pev_origin, fOrigin);                              //get the origin of the cp
	fOrigin[2] += 20.0;                                             //add 20 to z axis to prevent getting stuck in the cp
	CreateTeleportEffect(id,g_iIndexSprite);                        //create teleport effect
	entity_set_vector(id, EV_VEC_velocity, Float:{0.0, 0.0, 0.0});  //reset velocity / momentum
	stock_teleport(id, fOrigin);                                    //teleport the player to the cp
}

public did_touch_cp(id,cp) {
    if (g_sPlayerData[id][m_touchedCPs] == Invalid_Array) { return false; } //if the array does not exist yet return false
    new iSize = ArraySize(g_sPlayerData[id][m_touchedCPs]);                 //get the size of the array
    new iValue = 0;
    for (new i = 0; i < iSize; i++) {
        iValue = ArrayGetCell(g_sPlayerData[id][m_touchedCPs], i);
        if (iValue== cp) {
            return true;
        }
    }
    return false;
}

public add_touched_cp(id,cp) {
    if (g_sPlayerData[id][m_touchedCPs] == Invalid_Array) {
        g_sPlayerData[id][m_touchedCPs] = ArrayCreate(1);
    }
    return ArrayPushCell(g_sPlayerData[id][m_touchedCPs], cp);
}

public draw_clocksprite(id) {
    if (!g_sPlayerData[id][m_bInRun]) { return; }                           //return if not in run

    //send message to remove the sprite
    message_begin(MSG_ALL, SVC_TEMPENTITY);
    write_byte(125);
    write_byte(id);
    message_end();

    for (new i = 1; i <= 32; i++) {
        if (is_connected_user(i) && g_sPlayerData[i][m_bInRun] && i != id) { // dont send to the player who triggered the sprite
            message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, {0,0,0}, i);
            write_byte(TE_PLAYERATTACHMENT);
            write_byte(id);
            write_coord(60);
            write_short(g_iIndexClocksprite);
            write_short(10);
            message_end();
        }
    }
}

public Hook_AddToFullPack(es_handle, e, ent, host, hostflags, player, pSet){
    if (player == 0) {

        if (!is_valid_ent(ent)) { return FMRES_IGNORED; }
        new szClass[32];
        entity_get_string(ent, EV_SZ_classname, szClass, charsmax(szClass));
        
        if (equali(szClass,"sw_checkpoint") && g_sPlayerData[host][m_bOwnCPs] && pev(ent, pev_iuser1) == 1) { 
            set_es(es_handle, ES_Effects, (get_es(es_handle, ES_Effects) | EF_NODRAW));
        }
        if ( (g_sPlayerData[host][m_touchedCPs] != Invalid_Array) && (ArraySize(g_sPlayerData[host][m_touchedCPs]) >= 2) && equali(szClass,"sw_checkpoint") && !g_sPlayerData[host][m_bUsedExtras]) {

            if (ent == ArrayGetCell(g_sPlayerData[host][m_touchedCPs], ArraySize(g_sPlayerData[host][m_touchedCPs]) - 1) ||
                ent == ArrayGetCell(g_sPlayerData[host][m_touchedCPs], ArraySize(g_sPlayerData[host][m_touchedCPs]) - 2)) {
                // Draw the last two checkpoints in the array
            } else if (ArrayFindValue(g_sPlayerData[host][m_touchedCPs], ent) != -1) {
                // Checkpoint has already been touched, don't draw it
                set_es(es_handle, ES_Effects, (get_es(es_handle, ES_Effects) | EF_NODRAW));
            } else {
                // Draw all other checkpoints
            }
        }

    }

    return FMRES_HANDLED;
}

/* Effect when touching the goal */
stock SkillsEffectGoalTouch(id, bool:speedrun, model_lightning, model_flare)
{
    new origin[3]; get_user_origin(id, origin);  // Integer player position
    
    // Use particle burst for colors
    new const COLORS[] = {250, 83, 211};
    for (new i = 0; i < sizeof(COLORS); ++i) 
    {
        message_begin(MSG_ALL, SVC_TEMPENTITY);
        {
            write_byte(TE_PARTICLEBURST);
            write_coord(origin[0]);
            write_coord(origin[1]);
            write_coord(origin[2]);
            write_short(500); // radius
            write_byte(COLORS[i]); // color
            write_byte(100); // duration
        }
        message_end();
    }
    
    if (!speedrun)
        return;
    
    message_begin(MSG_PVS, SVC_TEMPENTITY, origin);
    write_byte(TE_STREAK_SPLASH);
    {
        write_coord(origin[0]);
        write_coord(origin[1]);
        write_coord(origin[2] - 40);
        write_coord(0);
        write_coord(0);
        write_coord(500);
        write_byte(10);
        write_short(100);
        write_short(10);
        write_short(100);
    }
    message_end();

    // Increase player's z velocity
    // get current velocity
    new Float:velocity[3];
    entity_get_vector(id, EV_VEC_velocity, velocity);
    // set new velocity
    velocity[2] = floatadd(velocity[2], 800.0);
    entity_set_vector(id, EV_VEC_velocity, velocity);
    //set_pev(id, pev_velocity, pev(id, pev_velocity) + 800.0);

    new const funnel_positions[] = {70, 100};
    for (new i = 0; i < sizeof(funnel_positions); ++i) 
    {
        message_begin(MSG_ALL, SVC_TEMPENTITY);
        {
            write_byte(TE_LARGEFUNNEL);
            write_coord(origin[0]);
            write_coord(origin[1]);
            write_coord(origin[2] + funnel_positions[i]);
            write_short(model_flare);
            write_short(i);
        }
        message_end();
    }

    new const beamdisk_positions[] = {0, 100, 200};
    for (new i = 0; i < sizeof(beamdisk_positions); ++i) 
    {
        message_begin(MSG_ALL, SVC_TEMPENTITY);
        {
            write_byte(TE_BEAMDISK);
            write_coord(origin[0]);
            write_coord(origin[1]);
            write_coord(origin[2] + beamdisk_positions[i]);
            write_coord(origin[0] + 100);
            write_coord(origin[1]);
            write_coord(origin[2] + 100); // reach damage radius over .3 seconds
            write_short(model_lightning);
            write_byte(0); // startframe
            write_byte(0); // framerate
            write_byte(150); // life
            write_byte(10);  // width
            write_byte(0);   // noise
            write_byte(floatround(random_float(100.0, 255.0)));   // r, g, b
            write_byte(floatround(random_float(0.0  , 255.0)));   // r, g, b
            write_byte(floatround(random_float(20.0 , 255.0)));   // r, g, b
            write_byte(210);	// brightness
            write_byte(0);		// speed
        }
        message_end();
    }

    new const beamtorus_positions[] = {50, 150, 250};
    for (new i = 0; i < sizeof(beamtorus_positions); ++i) 
    {
        message_begin(MSG_ALL, SVC_TEMPENTITY);
        {
            write_byte(TE_BEAMTORUS);
            write_coord(origin[0]);
            write_coord(origin[1]);
            write_coord(origin[2] + beamtorus_positions[i]);
            write_coord(origin[0]);
            write_coord(origin[1]);
            write_coord(origin[2] + 100); // reach damage radius over .3 seconds
            write_short(model_lightning);
            write_byte(0); // startframe
            write_byte(0); // framerate
            write_byte(150); // life
            write_byte(10);  // width
            write_byte(0);   // noise
            write_byte(floatround(random_float(100.0, 255.0)));   // r, g, b
            write_byte(floatround(random_float(100.0, 255.0)));   // r, g, b
            write_byte(floatround(random_float(100.0, 255.0)));   // r, g, b
            write_byte(210);	// brightness
            write_byte(0);		// speed
        }
        message_end();
    }
}


//add a menu /extras which is available as soon as the player finishes the map
public menu_extras_deploy(id) {
	//check if he finished the map if not return
	if (!g_sPlayerData[id][m_bCourseFinished]) {
		client_print(id, print_chat, "* You have to finish the map first!");
		return;
	}
	new szHeader[128];
	formatex(szHeader, charsmax(szHeader), "\\yCongrats!\nChoose your goodies\n");
	new menu = menu_create(szHeader, "menu_extras_clicked");
	//gray string if player is in noclip
	if (pev(id,pev_movetype) & MOVETYPE_NOCLIP) {
		menu_additem(menu,"Noclip: on","1")
	} else {
		menu_additem(menu,"Noclip: \\roff","1");
	} 
	
	if (g_sPlayerData[id][m_bXtraSJ]) {
		menu_additem(menu,"Superjump: on","2");
	} else {
		menu_additem(menu,"Superjump: \\roff","2");
	}
	menu_additem(menu, "TP to start","4");
	menu_additem(menu, "TP to end","5");
	menu_additem(menu, "Cycle through checkpoints","6");
	menu_additem(menu,"\\rPrepare for new run (slayme)","3");
	menu_display(id, menu);
}


public menu_extras_clicked(id, menu, item) {
    if( item == MENU_EXIT )
    {
        menu_destroy( menu );
        return PLUGIN_HANDLED;
    }

    //check if he finished the map if not return
    if (!g_sPlayerData[id][m_bCourseFinished]) {
        client_print(id, print_chat, "* You have to finish the map first!");
        return PLUGIN_HANDLED;
    }
    // he clicked on any extras so set m_bUsedExtras
    g_sPlayerData[id][m_bUsedExtras] = true;
    g_sPlayerData[id][m_fGenericCooldown] = get_gametime();  
    new data[ 6 ], iName[ 64 ];
    new access, callback;
    menu_item_getinfo( menu, item, access, data,5, iName, 63, callback );
    new tempid = str_to_num( data );
    menu_destroy( menu );
    switch( tempid )
    {
        case 1: //noclip
        {
            if (pev(id,pev_movetype) & MOVETYPE_NOCLIP) {
                entity_set_int(id, EV_INT_movetype, MOVETYPE_WALK);
                client_print(id, print_chat, "* Noclip off");
            } else {
                entity_set_int(id, EV_INT_movetype, MOVETYPE_NOCLIP);
                client_print(id, print_chat, "* Noclip on");
            }
	   menu_extras_deploy(id);
        }
        case 2: //superjump
        {
            if (g_sPlayerData[id][m_bXtraSJ]) {
                g_sPlayerData[id][m_bXtraSJ] = false;
                client_print(id, print_chat, "* Superjump off");
            } else {
                g_sPlayerData[id][m_bXtraSJ] = true;
                client_print(id, print_chat, "* Superjump on");
            }
	   menu_extras_deploy(id);
        }
        case 3: //reset & slay
        {
            skillsrun_reset(id);
        }
        case 4: //tp to start
        {
            new ent;
            ent = -1;
            new eSearch = -1;
            while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "sw_checkpoint"))) {
                if(!pev_valid(ent) || pev(ent, pev_iuser2) != api_get_player_course(id)) continue;
                
                if (pev(ent, pev_iuser1) == 0) {
                    eSearch = ent;
                    break;
                }
            }  
            //check if ent is valid
            if (!pev_valid(eSearch)) {
                client_print(id, print_chat, "* Something weird happened here.. did you already start a run? [error: 4]");
                return PLUGIN_HANDLED;
            }
            new Float:fOrigin[3];                                           //create a new origin vector
            pev(eSearch, pev_origin, fOrigin);                              //get the origin of the cp
            fOrigin[2] += 20.0;                                             //add 20 to z axis to prevent getting stuck in the cp
            CreateTeleportEffect(id,g_iIndexSprite);                        //create teleport effect
            entity_set_vector(id, EV_VEC_velocity, Float:{0.0, 0.0, 0.0});  //reset velocity / momentum
            stock_teleport(id, fOrigin);
	        menu_extras_deploy(id);
        }  
        case 5: //tp to end
        {
            new ent;
            ent = -1;
            new eSearch = -1;
            while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "sw_checkpoint"))) {
                if(!pev_valid(ent) || pev(ent, pev_iuser2) != api_get_player_course(id)) continue;
                
                if (pev(ent, pev_iuser1) == 2) {
                    eSearch = ent;
                    break;
                }
            }  
            //check if ent is valid
            if (!pev_valid(eSearch)) {
                client_print(id, print_chat, "* Something weird happened here.. did you already finish the map? [error: 5]");
                return PLUGIN_HANDLED;
            }
            new Float:fOrigin[3];                                           //create a new origin vector
            pev(eSearch, pev_origin, fOrigin);                              //get the origin of the cp
            fOrigin[2] += 20.0;                                             //add 20 to z axis to prevent getting stuck in the cp
            CreateTeleportEffect(id,g_iIndexSprite);                        //create teleport effect
            entity_set_vector(id, EV_VEC_velocity, Float:{0.0, 0.0, 0.0});  //reset velocity / momentum
            stock_teleport(id, fOrigin);
	   menu_extras_deploy(id);
        } 
        case 6: //cycle cps
        {
            new ent =  g_sPlayerData[id][m_iXtraCurCP]; new eSearch = -1; new found = false;

            while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "sw_checkpoint"))) {
                if(!pev_valid(ent) || pev(ent, pev_iuser2) != api_get_player_course(id)) continue;
                //cycling through all normal cps in course
                
                if (pev(ent, pev_iuser1) == 1) {
                    g_sPlayerData[id][m_iXtraCurCP] = ent;
                    eSearch = ent;
                    found = true;
                    break;
                }
            }  
            if (!found) {
                client_print(id, print_chat, "* You reached the last checkpoint, clicking again will cycle again through all cps");
                g_sPlayerData[id][m_iXtraCurCP] = 0;
                return PLUGIN_HANDLED;
            }
            //check if ent is valid
            if (!pev_valid(eSearch)) {
                client_print(id, print_chat, "* Something weird happened here.. did you already finish the map? [error: 6]");
                return PLUGIN_HANDLED;
            }
            new Float:fOrigin[3];                                           //create a new origin vector
            pev(eSearch, pev_origin, fOrigin);                              //get the origin of the cp
            fOrigin[2] += 20.0;                                             //add 20 to z axis to prevent getting stuck in the cp
            CreateTeleportEffect(id,g_iIndexSprite);                        //create teleport effect
            entity_set_vector(id, EV_VEC_velocity, Float:{0.0, 0.0, 0.0});  //reset velocity / momentum
            stock_teleport(id, fOrigin);   
            menu_extras_deploy(id); 
        }
    }
    return PLUGIN_HANDLED;

}

stock skillsrun_reset(id) {
    set_pev(id, pev_takedamage, DAMAGE_AIM);
    stock_slay(id);
    reset_struct(id);
    dllfunc(DLLFunc_Spawn, id);
    client_print(id, print_chat, "* You have been respawned and your skillsrun has been reset");
}

public Hook_PlayerPreThink(id) {
    if (g_sPlayerData[id][m_bCourseFinished] && g_sPlayerData[id][m_bXtraSJ] && (pev(id, pev_flags) & FL_ONGROUND) && (pev(id, pev_button) & IN_ATTACK2)) {
        static Float:fAngles[3]; pev(id, pev_v_angle, fAngles)

        engfunc(EngFunc_MakeVectors, fAngles) // Convert view angle to normalised vector
        global_get(glb_v_forward, fAngles) // No longer require angles so use it to hold vector instead
            
        for (new i = 0; i < 3; i++)
        {
            fAngles[i] *= 1200.0 // Scale up vector
        }

        set_pev(id, pev_velocity, fAngles)
    }
}


//start of the codeblock for amxmodx
public hook_say(iClient)
{
	if(!is_user_alive(iClient))
		return PLUGIN_CONTINUE;
	
	static szCommand[20];
	read_args(szCommand, sizeof(szCommand)-1);
	remove_quotes(szCommand);
	
	if(szCommand[0] != '/')
		return PLUGIN_CONTINUE;
	
	static szArg2[12], Float:flHalfLifeTime;
	strtok(szCommand, szCommand, sizeof(szCommand)-1, szArg2, sizeof(szArg2)-1, ' ');
	trim(szArg2);
	
	global_get(glb_time, flHalfLifeTime);
	
	if(equali(szCommand[1], "class"))
	{
        if (api_mapflag(MAPFLAG_NOCLASS)) {
            client_print(iClient, print_chat, "* Class changing is disabled on this map.");
            return FMRES_HANDLED;
        }
		if(g_flClassDelay[iClient] > flHalfLifeTime)
		{
			client_print(iClient, print_chat, "* You must wait %.2f more seconds to switch your class again.", g_flClassDelay[iClient]-flHalfLifeTime);
			return FMRES_HANDLED;
		}
		
		if(equali(szArg2, "scout")) set_pev(iClient, pev_playerclass, CLASS_SCOUT);
		else if(equali(szArg2, "sniper")) set_pev(iClient, pev_playerclass, CLASS_SNIPER);
		else if(equali(szArg2, "soldier")) set_pev(iClient, pev_playerclass, CLASS_SOLDIER);
		else if(equali(szArg2, "demoman")) set_pev(iClient, pev_playerclass, CLASS_DEMOMAN);
		else if(equali(szArg2, "medic")) set_pev(iClient, pev_playerclass, CLASS_MEDIC);
		else if(equali(szArg2, "hwguy")) set_pev(iClient, pev_playerclass, CLASS_HWGUY);
		else if(equali(szArg2, "pyro")) set_pev(iClient, pev_playerclass, CLASS_PYRO);
		else if(equali(szArg2, "spy")) set_pev(iClient, pev_playerclass, CLASS_SPY);
		else if(equali(szArg2, "engineer")) set_pev(iClient, pev_playerclass, CLASS_ENGINEER);
		else if(equali(szArg2, "random")) set_pev(iClient, pev_playerclass, CLASS_RANDOM);
		else if(equali(szArg2, "civilian")) set_pev(iClient, pev_playerclass, CLASS_CIVILIAN);
		else if(str_to_num(szArg2) >= CLASS_SCOUT && str_to_num(szArg2) <= CLASS_CIVILIAN) set_pev(iClient, pev_playerclass, str_to_num(szArg2));
		else
		{
			client_print(iClient, print_chat, "* To change your class type, /class <classname> -OR- /class <class number>");
			return PLUGIN_CONTINUE;
		}
		
		fm_strip_user_weapons(iClient);
		skillsrun_reset(iClient);
		g_flClassDelay[iClient] = flHalfLifeTime + 2.0;
		
		return FMRES_HANDLED;
	}
	else if(equali(szCommand[1], "give"))
	{
        if (api_mapflag(MAPFLAG_NOGIVE))
        {
            client_print(iClient, print_chat, "* You cannot use this command on this map.");
            return PLUGIN_HANDLED;
        }
		if(equali(szArg2, "all"))
		{
			PowerUp(iClient, 0, "99999");
            g_sPlayerData[iClient][m_bAltmodx] = true;
            pub_stoprun(iClient);
            g_sPlayerData[iClient][m_fAltmodxCooldown] = get_gametime(); 
			tfc_setbammo(iClient, TFC_AMMO_NADE1, 4);
			tfc_setbammo(iClient, TFC_AMMO_NADE2, 4);
			tfc_setbammo(iClient, TFC_AMMO_SHELLS, 225);
			tfc_setbammo(iClient, TFC_AMMO_BULLETS, 225);
			tfc_setbammo(iClient, TFC_AMMO_CELLS, 225);
			tfc_setbammo(iClient, TFC_AMMO_ROCKETS, 225);
		}
		else if (equali(szArg2, "god")) {
			PowerUp(iClient, 1, "99999");
            g_sPlayerData[iClient][m_bAltmodx] = true;
            pub_stoprun(iClient);
            g_sPlayerData[iClient][m_fAltmodxCooldown] = get_gametime();  
        }
		else if(equali(szArg2, "quad")) {
			PowerUp(iClient, 2, "99999");
            g_sPlayerData[iClient][m_bAltmodx] = true;
            pub_stoprun(iClient);
            g_sPlayerData[iClient][m_fAltmodxCooldown] = get_gametime();  
        }
		else if(equali(szArg2, "nades"))
		{
			tfc_setbammo(iClient, TFC_AMMO_NADE1, 4);
			tfc_setbammo(iClient, TFC_AMMO_NADE2, 4);
		}
		else if(equali(szArg2, "ammo"))
		{
			tfc_setbammo(iClient, TFC_AMMO_SHELLS, 225);
			tfc_setbammo(iClient, TFC_AMMO_BULLETS, 225);
			tfc_setbammo(iClient, TFC_AMMO_CELLS, 225);
			tfc_setbammo(iClient, TFC_AMMO_ROCKETS, 225);
		}
		else
		{
			client_print(iClient, print_chat, "* To give yourself powerup(s) type, /give <quad, god, nades, ammo, or all>");
			return PLUGIN_CONTINUE;
		}
		
		return FMRES_HANDLED;
	}
	else if(equali(szCommand[1], "remove"))
	{
		if(equali(szArg2, "all"))
			PowerUp(iClient, 0, "1");
		else if(equali(szArg2, "god"))
			PowerUp(iClient, 1, "1");
		else if(equali(szArg2, "quad"))
			PowerUp(iClient, 2, "1");
		else
		{
			client_print(iClient, print_chat, "* To remove a powerup(s) type, /remove <quad, god, or all>");
			return PLUGIN_CONTINUE;
		}
		
		return FMRES_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

PowerUp(iClient, iType, szTime[]="1")
{
	new iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_tfgoal"));
	dllfunc(DLLFunc_Spawn, iEnt);
	
	set_keyvalue(iEnt, "g_a", "1"); // Player touch activates
	set_keyvalue(iEnt, "g_e", "1"); // Affects AP only
	set_keyvalue(iEnt, "goal_state", "2"); // Active goal
	
	switch(iType)
	{
		case 0:
		{
			// Give all
			set_keyvalue(iEnt, "invincible_finished", szTime);
			set_keyvalue(iEnt, "super_damage_finished", szTime);
		}
		case 1: set_keyvalue(iEnt, "invincible_finished", szTime); // Give god
		case 2: set_keyvalue(iEnt, "super_damage_finished", szTime); // Give quad
	}
	
	dllfunc(DLLFunc_Use, iEnt, iClient);
	engfunc(EngFunc_RemoveEntity, iEnt);
}
//end of the codeblock for amxmodx