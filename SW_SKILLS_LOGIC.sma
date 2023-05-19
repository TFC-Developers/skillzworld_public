
#include "include/global"
#include <engine>
#include <fakemeta>
#include "include/utils"
#include "include/api_skills_mapentities"


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
    m_iCourseID                 //the course id
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
    register_clcmd("say /reset", "pub_reset");
    register_clcmd("say /r", "pub_reset");
    register_clcmd("say /load", "pub_loadlastcp");
    register_clcmd("say load", "pub_loadlastcp");
    register_clcmd("say /l", "pub_loadlastcp");
    register_clcmd("say /undo", "pub_undo");
    register_clcmd("say /u", "pub_undo");
    register_clcmd("say /stop", "pub_stoprun");
    register_clcmd("say /s", "pub_savecustomcp");
    register_clcmd("say /save", "pub_savecustomcp");
    register_clcmd("say /savecp", "pub_savecustomcp");
    register_clcmd("say save", "pub_savecustomcp");
    register_clcmd("say /mapcps", "pub_mapcps");
    register_clcmd("say /etest", "pub_test"); 
    register_clcmd("say /testdraw", "pub_drawtest");  
    set_task(5.0, "spawn_thinker");

    
    g_iThinker = 0;
}
public pub_test(id) {
    SkillsEffectGoalTouch(id, true, g_iIndexSprite, g_iIndex_Flaremodel);
}
public pub_drawtest(id) {
    //toggle m_bOwnCPs
    //get origin

}
public plugin_precache() {
    precache_sound(CHECKPOINT_SOUND);
    g_iIndexSprite = precache_model("sprites/lgtning.spr")
    g_iIndex_Flaremodel = precache_model("sprites/flare6.spr");
    g_iIndexClocksprite = precache_model(CLOCK_SPRITE);
    g_iIndex_CPmarker_red = precache_model(CP_MARKER_RED);
    g_iIndex_CPmarker_yellow = precache_model(CP_MARKER_YELLOW);

}
public pub_stoprun(id) {
    //check wether player is in a speedrun
    if (!g_sPlayerData[id][m_bInRun]) {
        client_print(id, print_chat, "* You are not in a run");
        return;
    }
    //reset the players run
    g_sPlayerData[id][m_bInRun] = false;
    g_sPlayerData[id][m_fRunStarttime] = 0.0;

    client_cmd(id, "spk \"reset ok\"\n");
    client_print(id, print_chat, "* Your timer has been reset. Have fun on the course!");
    //native set_hudmessage(red = 200, green = 100, blue = 0, Float:x = -1.0, Float:y = 0.35, effects = 0, Float:fxtime = 6.0, Float:holdtime = 12.0, Float:fadeintime = 0.1, Float:fadeouttime = 0.2, channel = -1);
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
}

public client_connect(id) {
    reset_struct(id);
}
public client_disconnected(id) {
    reset_struct(id);
}
public pub_mapcps(id) {
    //return if not in customcps mode
    if (!g_sPlayerData[id][m_bOwnCPs]) {
        client_print(id, print_chat, "* You are not in custom cps mode. Save at least one custom cp (say /s) to enter this mode.");
        return;
    }
    g_sPlayerData[id][m_bOwnCPs] = false;
    ArrayDestroy(g_sPlayerData[id][m_CustomCPs]); g_sPlayerData[id][m_CustomCPs] = Invalid_Array;
    client_print(id, print_chat, "* Custom cps mode disabled. Say /s again to re-enable it. The counter of used cps has not been reset.");
}
public pub_savecustomcp(id) {
    if (g_sPlayerData[id][m_CustomCPs] == Invalid_Array) {
        g_sPlayerData[id][m_CustomCPs] = ArrayCreate(eCustomCP);
    }

    if (get_user_team(id) < 1 || get_user_team(id) > 4) {
        client_print(id, print_chat, "* You are not in a valid team");
        return;
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
        return;
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

}
public draw_customcps(id) {
    //return if not in customcps mode
    if (!g_sPlayerData[id][m_bOwnCPs]) {
        return;
    }

    //check wether one second has passed already
    if (g_sPlayerData[id][m_fCustomCPsNextDr] > get_gametime()) {
        return;
    }
    //return when Invalid_Array
    if (g_sPlayerData[id][m_CustomCPs] == Invalid_Array) {
        return;
    }
    // set next draw
    g_sPlayerData[id][m_fCustomCPsNextDr] = get_gametime() + 1.1;
    //get origin
    new Float:origin[3];
    pev(id, pev_origin, origin);
    //iterate through all custom cps
    new iCount = ArraySize(g_sPlayerData[id][m_CustomCPs]);
    //return if no cps are in the array
    if (iCount == 0) { return; }
    new Buffer[eCustomCP];
    for (new i = iCount-1; i >= 0; i--) {
        //get the origin of the cp
        ArrayGetArray(g_sPlayerData[id][m_CustomCPs], i, Buffer);
        if (i == iCount-1) {
            //draw the cp
            message_begin(MSG_ONE, SVC_TEMPENTITY, Float:{0,0,0}, .player = id);
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
            //draw the cp
            message_begin(MSG_ONE, SVC_TEMPENTITY,Float:{0,0,0} , .player = id);
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
    if (g_iThinker != 0) {
        return;
    }
    //spawn an info_target and rename it to sw_skillsthink^
    new entity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
    entity_set_string(entity, EV_SZ_classname, "sw_skillsthink");    
    entity_set_float(entity, EV_FL_nextthink, (get_gametime() + 0.1) );

    //get the next think time as debug
    new Float:nextthink = entity_get_float(entity, EV_FL_nextthink);
    DebugPrintLevel(0, "spawn_thinker: next think time: %f (now %f)", nextthink, get_gametime());

    DebugPrintLevel(0, "spawn_thinker: thinker spawned (id: %d)", entity);  
    g_iThinker = entity;
}

public pub_skillsthink(id) {
    if (g_iThinker == 0 || g_iThinker != id) {
	    return FMRES_HANDLED;
    }
    //set next think to gametime + 0.15
    entity_set_float(id, EV_FL_nextthink, (get_gametime() + 0.09) );

    //call update_hud for all players
    for (new i = 1; i <= 32; i++) {
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

        message_begin(MSG_ONE, iStatusMessage, {0,0,0}, id);
        write_byte(1);
        write_string(szMsg);
        message_end();
        return;
    }

    if (get_user_team(id) < 1 || get_user_team(id) > 4 || !g_sPlayerData[id][m_bInRun]) {
        //empty the hud
        message_begin(MSG_ONE, iStatusMessage, {0,0,0}, id);
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
        g_sPlayerData[id][m_fLastHudUpdate] = get_gametime() + 0.5;
        new szBigHudTXT[128];
        if (iHours > 0) {
            formatex(szBigHudTXT, charsmax(szBigHudTXT), "XX%02d:%02d:%02d", iHours, iMinutes, iSeconds);
        } else {
            formatex(szBigHudTXT, charsmax(szBigHudTXT), "XX%02d:%02d", iMinutes, iSeconds);
    
        }
        message_begin(MSG_ONE, SVC_TEMPENTITY, .player = id);
        {
            write_byte(TE_TEXTMESSAGE);
            write_byte(1 & 0xFF);
            write_short( clamp(-1*(1<<13), -32768, 32767) );
            write_short( clamp(floatround(floatmul(0.92, float(1<<13)), floatround_floor), -32768, 32767) );
            write_byte( 1 );
            write_byte( 0 );
            write_byte( 255 );
            write_byte( 0 );
            write_byte( 0 );
            write_byte( 0 );
            write_byte( 0 );
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

    //add the cps used to the string if the player has used any
    if (g_sPlayerData[id][m_iTotalCPsUsed] == 1) {
        formatex(szMsg, charsmax(szMsg), "%s (%d cp used)", szMsg, g_sPlayerData[id][m_iTotalCPsUsed]);
    } else if (g_sPlayerData[id][m_iTotalCPsUsed] > 1) {
        formatex(szMsg, charsmax(szMsg), "%s (%d cps used)", szMsg, g_sPlayerData[id][m_iTotalCPsUsed]);
    }

    message_begin(MSG_ONE, iStatusMessage, {0,0,0}, id);
    write_byte(1);
    write_string(szMsg);
    message_end();


}


public pub_cptouch(touched, toucher) {
     //check if touched is a cp
    new szClass[32];
    new szClassToucher[32];
    entity_get_string(touched, EV_SZ_classname, szClass, charsmax(szClass));
    entity_get_string(toucher, EV_SZ_classname, szClassToucher, charsmax(szClassToucher));
    if (!equali(szClass, "sw_checkpoint") || !equali(szClassToucher, "player")) {
        return;
    }

    //check if cp is start cp by checking if its iuser1 is 0 => start cp
    if (pev(touched, pev_iuser1) == 0) {
        //DebugPrintLevel(0, "pub_cptouch: %d touched a start cp", toucher);
        pub_sub_starttouch(touched, toucher);
    } 

    //check if the cp is a normal cp so if its iuser1 is set to 1
    if (pev(touched, pev_iuser1) == 1) {
        //DebugPrintLevel(0, "pub_cptouch: %d touched a normal cp", toucher);
        pub_sub_cptouch(touched, toucher);
    }

    // check if the cp is a goal orb so if its iuser1 is set to 2
    if (pev(touched, pev_iuser1) == 2) {
        //DebugPrintLevel(0, "pub_cptouch: %d touched a goal orb", toucher);
        pub_sub_endtouch(touched, toucher);
    }
 
}

public pub_sub_endtouch(touched, toucher) {

    //ignore if the player already touched the goal orb
    if (g_sPlayerData[toucher][m_bCourseFinished]) {
        return;
    }

    //check wether the player was allowed to touch this orb, dismiss if not
    if (api_is_team_allowed(toucher,touched)) {
        // calculate the runtime as float
        new Float:fTime = floatsub(get_gametime(), g_sPlayerData[toucher][m_fRunStarttime]);
        //dismiss if the runtime is below 5 seconds (testing purposes)
        if (fTime < 5.0) {
            client_print(toucher, print_chat, "* Your time is too short to be saved");
            return;
        }

        g_sPlayerData[toucher][m_bCourseFinished] = true; //set the player's course finished to true
        //format the hud message
        new szBigHudTXT[128];
        //get player name
        new szName[32];
        get_user_name(toucher, szName, charsmax(szName));
        //get course name
        new szCourseName[32];
        api_get_coursename(pev(touched, pev_iuser2), szCourseName, charsmax(szCourseName));
        g_sPlayerData[toucher][m_bInRun] = false; //set the player's inrun to false
        new iTotalSeconds = floatround(fTime, floatround_floor); new iHours = iTotalSeconds / 3600; new iSeconds = iTotalSeconds % 60; new iMinutes = iTotalSeconds / 60; new iMillis = floatround(fTime*100.0, floatround_floor) % 100;
        //format differently if hours are > 0
        if (iHours > 0) {
            formatex(szBigHudTXT, charsmax(szBigHudTXT), "Congratulations %s!\n\nYou finished the course %s in %02d:%02d:%02d\n\nSay /reset to start over.", szName, szCourseName, iHours, iMinutes, iSeconds, iMillis);
        } else {
            formatex(szBigHudTXT, charsmax(szBigHudTXT), "Congratulations %s!\n\nYou finished the course %s in %02d:%02d.%02d\n\nSay /reset to start over.", szName, szCourseName, iMinutes, iSeconds, iMillis);
        }
        //print to console as dbeug
        DebugPrintLevel(0, "pub_sub_endtouch: %s finished the course %s in %02d:%02d.%02d", szName, szCourseName, iMinutes, iSeconds, iMillis);
        DebugPrintLevel(0, "Hudtxt: %s", szBigHudTXT);
        //show the hud message
        set_hudmessage(200,100,0,-1.0, 0.35, 0, 0.0, 19.0, 1.0, 0.0, 2);
        show_hudmessage(0, szBigHudTXT);

        // print a message to the chat of everyone stating some stats including how many cps were used
        new szChatTXT[128];
        formatex(szChatTXT, charsmax(szChatTXT), "* %s finished the course %s in %02d:%02d.%02d (%d cps used)", szName, szCourseName, floatround(fTime/60.0, floatround_floor), floatround(fTime, floatround_floor) % 60, floatround(fTime*100.0, floatround_floor) % 100, g_sPlayerData[toucher][m_iTotalCPsUsed]);
        client_print(0, print_chat, szChatTXT);

        //show some fancy effects
        SkillsEffectGoalTouch(toucher, true, g_iIndexSprite, g_iIndex_Flaremodel);  


        
    } else if (g_sPlayerData[toucher][m_fGenericCooldown] < get_gametime()) {
        // set generic cooldown to 10 seconds
        g_sPlayerData[toucher][m_fGenericCooldown] = get_gametime() + 10.0;
        client_print(toucher, print_chat, "* Your team is not allowed to participate in this course");  
        client_cmd(toucher, "spk \"no access\"\n");
        return;
    }

}
public pub_sub_cptouch(touched, toucher) {
    // check if the player is in the correct team to touch this cp
    if (!api_is_team_allowed(toucher,touched)) {
        return;
    }
    //return if custom cps are enabled
    if (g_sPlayerData[toucher][m_bOwnCPs]) {
        return;
    }
    //check if player already has touched this cp
    if (did_touch_cp(toucher,touched)) {
        return;
    }

    //now add the cp to the array
    add_touched_cp(toucher, touched);
    //play sound
    client_cmd( toucher, "spk \"%s\"\n", CHECKPOINT_SOUND);
    new iTotalCPsTouched = ArraySize(g_sPlayerData[toucher][m_touchedCPs]);
    new iTotalCPsinCourse = api_get_totalcps(pev(touched, pev_iuser2));
    
    client_print(toucher, print_chat, "* You touched a total of %d cps (max: %d), say /undo or /u to undo this.", iTotalCPsTouched, iTotalCPsinCourse);
    DebugPrintLevel(0, "pub_sub_cptouch: player touched a total of %d cps", ArraySize(g_sPlayerData[toucher][m_touchedCPs]));
}

public pub_sub_starttouch(touched, toucher) {
   
    //check if he is allowed to touch again (prevent spamming)
    if (g_sPlayerData[toucher][m_fTouchCooldown] > get_gametime()) {
        return FMRES_HANDLED;
    }

    //start the run
    if (api_is_team_allowed(toucher,touched)) {

        //start the run
        ArrayDestroy(g_sPlayerData[toucher][m_touchedCPs]);
        ArrayDestroy(g_sPlayerData[toucher][m_CustomCPs]); g_sPlayerData[toucher][m_CustomCPs] = Invalid_Array;

        g_sPlayerData[toucher][m_touchedCPs] = ArrayCreate(1);

        g_sPlayerData[toucher][m_bInRun] = true;
        g_sPlayerData[toucher][m_fRunStarttime] = get_gametime();
        g_sPlayerData[toucher][m_iRunCount] += 1;
        g_sPlayerData[toucher][m_fTouchCooldown] = get_gametime() + 2.0;
        g_sPlayerData[toucher][m_iTotalCPsUsed] = 0;
        g_sPlayerData[toucher][m_bOwnCPs] = false;
        g_sPlayerData[toucher][m_iCourseID] = pev(touched, pev_iuser2);

        //only provide the course info once per map cycle
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
        // set generic cooldown to 10 seconds
        g_sPlayerData[toucher][m_fGenericCooldown] = get_gametime() + 10.0;
        client_print(toucher, print_chat, "* Your team is not allowed to participate in this course");  
        client_cmd(toucher, "spk \"no access\"\n");
        return FMRES_HANDLED;
    }
    return FMRES_HANDLED
}
public pub_undo(id) {
    // check if player has custom cps
    if (g_sPlayerData[id][m_bOwnCPs]) {
        new iSize = ArraySize(g_sPlayerData[id][m_CustomCPs]);
        if (iSize == 0) {
            client_print(id, print_chat, "* You have not saved any custom cps yet");
            return;
        }
        if (!is_user_alive(id)) {
            client_print(id, print_chat, "* You have to respawn first in order to use your last cp");
            return;
        }
        ArrayDeleteItem(g_sPlayerData[id][m_CustomCPs], iSize - 1);
        client_print(id, print_chat, "* Your last saved custom cp has been removed");
        pub_loadlastcp(id);
        return;
    } // proceed if not
    if (g_sPlayerData[id][m_touchedCPs] == Invalid_Array) {
        client_print(id, print_chat, "* You have not touched any cps yet");
        return;
    }
    new iSize = ArraySize(g_sPlayerData[id][m_touchedCPs]);
    if (iSize == 0) {
        client_print(id, print_chat, "* You have not touched any cps yet");
        return;
    }
    if (iSize == 1) {
        client_print(id, print_chat, "* You reached your first saved cp");
        return;
    }
    if (!is_user_alive(id)) {
        client_print(id, print_chat, "* You have to respawn first in order to use your last cp");
        return;
    }
    ArrayDeleteItem(g_sPlayerData[id][m_touchedCPs], iSize - 1);
    pub_loadlastcp(id);
}
public pub_loadlastcp(id) {

    if (!is_user_alive(id)) {
        client_print(id, print_chat, "* You have to respawn first in order to use your last cp");
        return;
    }
    new Float:fOrigin[3];
    fOrigin = Float:{0.0, 0.0, 0.0};

    if (g_sPlayerData[id][m_bOwnCPs]) {
        new iSize = ArraySize(g_sPlayerData[id][m_CustomCPs]);
        new Buffer[eCustomCP];
        if (iSize == 0) {
            client_print(id, print_chat, "* You have not saved any custom cps yet");
            return;
        }
        ArrayGetArray(g_sPlayerData[id][m_CustomCPs], iSize - 1, Buffer);
        fOrigin[0] = Buffer[m_vOrigin][0];
        fOrigin[1] = Buffer[m_vOrigin][1];
        fOrigin[2] = Buffer[m_vOrigin][2];
    } else {
        if (g_sPlayerData[id][m_touchedCPs] == Invalid_Array) {
            client_print(id, print_chat, "* You have not touched any cps yet");
            return;
        }
        new iSize = ArraySize(g_sPlayerData[id][m_touchedCPs]);
        new iLastCP = 0;

        if (iSize == 0) {
            client_print(id, print_chat, "* You have not touched any cps yet");
            return;
        }
        iLastCP = ArrayGetCell(g_sPlayerData[id][m_touchedCPs], iSize - 1);
        new szClass[32];
        entity_get_string(iLastCP, EV_SZ_classname, szClass, charsmax(szClass));
        if (!equali(szClass, "sw_checkpoint")) {
            client_print(id, print_chat, "* Something weird happened here.. please report this to an admin [error: 1]");
            return;
        }  

        entity_get_vector(iLastCP, EV_VEC_origin, fOrigin);                        //get the origin of the cp
    }

    if (fOrigin[0] == 0.0 && fOrigin[1] == 0.0 && (fOrigin[2] == 20.0 || fOrigin[2] == 5.0)) {
        client_print(id, print_chat, "* Something weird happened here.. please report this to an admin [error: 3]");
        return;
    }
    fOrigin[2] += 20.0;                                                                 //add 20 to z axis to prevent getting stuck in the cp
    CreateTeleportEffect(id,g_iIndexSprite);                                            //create teleport effect
    emit_sound(id, CHAN_ITEM, "misc/teleport_out.wav", 0.5, ATTN_NORM, 0, PITCH_HIGH);  //play teleport sound
    entity_set_vector(id, EV_VEC_velocity, Float:{0.0, 0.0, 0.0});                      //reset velocity / momentum
    stock_teleport(id, fOrigin);                                                        //teleport the player to the cp
    g_sPlayerData[id][m_iTotalCPsUsed] += 1;                                            //add 1 to the total cp used counter

}
public pub_reset(id) {
    /* discussion: should we allow resetting if the player has not started a run yet?
    if (g_sPlayerData[id][m_iCourseID] == 0) {
        client_print(id, print_chat, "* You have not started a run yet");
        return;
    }*/
    new ent;
  	ent = -1;
    new eSearch = -1;
	while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "sw_checkpoint")))
	{
        if(!pev_valid(ent))
            continue;

        if(pev(ent, pev_iuser2) != g_sPlayerData[id][m_iCourseID])
            continue;

        if (pev(ent, pev_iuser1) == 0) {
            eSearch = ent;
            break;
        }
		if(ent != g_sPlayerData[id][m_iCourseID])
			continue;

		if(!pev_valid(ent))
			continue;

	}  
    //chec if ent is valid
    if (!pev_valid(eSearch)) {
        client_print(id, print_chat, "* Something weird happened here.. please report this to an admin [error: 2]");
        return;
    }
    //get the origin of the cp
    new Float:fOrigin[3];
    pev(eSearch, pev_origin, fOrigin);
    //add 20 to z axis
    fOrigin[2] += 20.0;
    //teleport the player to the cp
    CreateTeleportEffect(id,g_iIndexSprite);
    //reset velocity / momentum
    entity_set_vector(id, EV_VEC_velocity, Float:{0.0, 0.0, 0.0});
    stock_teleport(id, fOrigin);
}

public did_touch_cp(id,cp) {
    if (g_sPlayerData[id][m_touchedCPs] == Invalid_Array) { return false; } //if the array does not exist yet return false
    new iSize = ArraySize(g_sPlayerData[id][m_touchedCPs]);
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
    //check if the array has an Invalid_Handled
    if (g_sPlayerData[id][m_touchedCPs] == Invalid_Array) {
        g_sPlayerData[id][m_touchedCPs] = ArrayCreate(1);
    }
    //add the cp to the array
    return ArrayPushCell(g_sPlayerData[id][m_touchedCPs], cp);
}

public draw_clocksprite(id) {

    //if user is not in speedrun then return
    if (!g_sPlayerData[id][m_bInRun]) {
        return;
    }

    //send message to remove the sprite
    message_begin(MSG_ALL, SVC_TEMPENTITY);
    write_byte(125);
    write_byte(id);
    message_end();

    //iterate through all players and send sprite mesage
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

    //check wether player is not set
    if (player == 0) {
        //since its not a player check if the host should see the cp entities and compare the class
        if (!is_valid_ent(ent)) { return FMRES_IGNORED; }
        new szClass[32];
        entity_get_string(ent, EV_SZ_classname, szClass, charsmax(szClass));
        
        if (equali(szClass,"sw_checkpoint") && g_sPlayerData[host][m_bOwnCPs] && pev(ent, pev_iuser1) == 1) { 
            set_es(es_handle, ES_Effects, (get_es(es_handle, ES_Effects) | EF_NODRAW));
        }
    }

    return FMRES_HANDLED;
}

/* Effect when touching the goal */
stock SkillsEffectGoalTouch(id, bool:speedrun, model_lightning, model_flare)
{

    //debug message on which class called
    new szClass[32];
    entity_get_string(id, EV_SZ_classname, szClass, charsmax(szClass));
    DebugPrintLevel(0, "SkillsEffectGoalTouch: %d touched a %s", id, szClass);

    new origin[3]; get_user_origin(id, origin);  // Integer player position

    //Debug origin
    DebugPrintLevel(0, "SkillsEffectGoalTouch: origin is %d %d %d", origin[0], origin[1], origin[2]);


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
