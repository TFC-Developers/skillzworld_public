
#include "include/global"
#include <engine>
#include <fakemeta>
#include "include/utils"
#include "include/api_skills_mapentities"


//enum to store the player's session data
enum ePlayerSessionData {
    m_fRunStarttime,
    m_iRunCount, //how many times the player has tried to beat the map aka touched the start
    Float:m_fTouchCooldown, //how many seconds the player has to wait before touching the startball again
    bool:m_bInRun, //if the player is in a run
    Float:m_fLastHudUpdate, //the last time the hud was updated
    Float:m_fLastStartTouchHud, //the last time the start touch hud has been shown
    bool:m_bGotCourseInfo, //if the player has received the course info
    Array:m_touchedCPs, //array of touched cps
    Float:m_vStartOrigin[3], //the player's origin when he touched the start orb
    Float:m_vStartAngles[3], //the player's origin when he touched the start orb
    m_iTotalCPsUsed, //how many cps the player has used
    bool:m_bCourseFinished, //if the player has finished the course
    Float:m_fGenericCooldown //generic cooldown for various things
}

new Array: g_sPlayerData[32][ePlayerSessionData]; 
new g_iThinker;
new g_iIndexSprite;
new g_iIndexClocksprite;
new g_iIndex_Flaremodel; 
new Float:g_fLastClockSpriteUpdate;

#define CHECKPOINT_SOUND "misc/cpoint.wav"
#define	CLOCK_SPRITE "sprites/clocktag.spr"


public plugin_init() {
    RegisterPlugin();
    register_forward(FM_Touch, "pub_cptouch");
    register_forward(FM_Think, "pub_skillsthink");
    register_think("spawn_thinker", "pub_skillsthink");
    register_clcmd("say /reset", "pub_reset");
    register_clcmd("say /r", "pub_reset");
    register_clcmd("say /load", "pub_loadlastcp");
    register_clcmd("say /l", "pub_loadlastcp");
    register_clcmd("say /undo", "pub_undo");
    register_clcmd("say /u", "pub_undo");
    register_clcmd("say /etest", "pub_test");   
    
    g_iThinker = 0;
}
public pub_test(id) {
    SkillsEffectGoalTouch(id, true, g_iIndexSprite, g_iIndex_Flaremodel);
}
public plugin_precache() {
    precache_sound(CHECKPOINT_SOUND);
    g_iIndexSprite = precache_model("sprites/lgtning.spr")
    g_iIndex_Flaremodel = precache_model("sprites/flare6.spr");
    g_iIndexClocksprite = precache_model(CLOCK_SPRITE);
}

public reset_struct(id) {
    //reset the player's session data
    g_sPlayerData[id][m_fRunStarttime] = 0.0;
    g_sPlayerData[id][m_iRunCount] = 0;
    g_sPlayerData[id][m_bInRun] = false;
    g_sPlayerData[id][m_fTouchCooldown] = 0.0;
    g_sPlayerData[id][m_fLastHudUpdate] = 0.0;
    g_sPlayerData[id][m_fLastStartTouchHud] = 0.0;
    g_sPlayerData[id][m_bGotCourseInfo] = false;
    ArrayDestroy(g_sPlayerData[id][m_touchedCPs]);
    g_sPlayerData[id][m_vStartOrigin][0] = 0.0;
    g_sPlayerData[id][m_vStartOrigin][1] = 0.0;
    g_sPlayerData[id][m_vStartOrigin][2] = 0.0;
    g_sPlayerData[id][m_iTotalCPsUsed] = 0; 
    g_sPlayerData[id][m_bCourseFinished] = false;
}

public client_connect(id) {
    reset_struct(id);
}
public client_disconnected(id) {
    reset_struct(id);
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
    new nextthink = entity_get_float(entity, EV_FL_nextthink);
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
        if (is_connected_user(i) && g_sPlayerData[i][m_bInRun]) {
            update_hud(i);
            
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
    //return if player is not in a team between 1 and 4
    if (get_user_team(id) < 1 || get_user_team(id) > 4) {
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

    // build the string: 
    //new Float:fTime = get_gametime() - g_sPlayerData[id][m_fRunStarttime]; 
    new Float:fTime = floatsub(get_gametime(), g_sPlayerData[id][m_fRunStarttime]);
    new iTotalSeconds = floatround(fTime, floatround_floor)
    new iHours = iTotalSeconds / 3600
    new iSeconds = iTotalSeconds % 60
    new iMinutes = iTotalSeconds / 60
    new iMillis = floatround(fTime*100.0, floatround_floor) % 100

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
    
    message_end();
    }
    //DebugPrintLevel(0, "Mins: %d, Secs: %d, Millis: %d", iMinutes, iSeconds, iMillis);  

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
    if (!api_is_team_allowed(toucher,touched)) {
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

        formatex(szBigHudTXT, charsmax(szBigHudTXT), "Congratulations %s!\n\nYou finished the course %s in %02d:%02d.%02d\n\nSay /reset to start over.", szName, szCourseName, floatround(fTime/60.0, floatround_floor), floatround(fTime, floatround_floor) % 60, floatround(fTime*100.0, floatround_floor) % 100);
        //show the hud message
        set_hudmessage(100,100,0,-1.0, 0.35, 0, 0, 12.0, 1.0, 0.0, 1);
        show_hudmessage(0, szBigHudTXT);

        // print a message to the chat of everyone stating some stats including how many cps were used
        new szChatTXT[128];
        formatex(szChatTXT, charsmax(szChatTXT), "* %s finished the course %s in %02d:%02d.%02d (%d cps used)", szName, szCourseName, floatround(fTime/60.0, floatround_floor), floatround(fTime, floatround_floor) % 60, floatround(fTime*100.0, floatround_floor) % 100, g_sPlayerData[toucher][m_iTotalCPsUsed]);
        client_print(0, print_chat, szChatTXT);

        //show some fancy effects
        SkillsEffectGoalTouch(toucher, true, g_iIndexSprite, g_iIndex_Flaremodel);  


        
    } if (g_sPlayerData[toucher][m_fGenericCooldown] < get_gametime()) {
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
    //check wether the player is actually in a run
    if (!g_sPlayerData[toucher][m_bInRun]) {
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
        //DebugPrintLevel(0, "%f > %f", g_sPlayerData[toucher][m_fTouchCooldown], get_gametime());
        //DebugPrintLevel(0, "pub_sub_starttouch: toucher %d is not allowed to touch again", toucher);
        return FMRES_HANDLED;
    }


    //start the run
    if (api_is_team_allowed(toucher,touched)) {

        //start the run
        ArrayDestroy(g_sPlayerData[toucher][m_touchedCPs]);  
        g_sPlayerData[toucher][m_touchedCPs] = ArrayCreate(1);

        g_sPlayerData[toucher][m_bInRun] = true;
        g_sPlayerData[toucher][m_fRunStarttime] = get_gametime();
        g_sPlayerData[toucher][m_iRunCount] += 1;
        g_sPlayerData[toucher][m_fTouchCooldown] = get_gametime() + 2.0;
        g_sPlayerData[toucher][m_iTotalCPsUsed] = 0;
        // save the angles of the player to the array
        new Float:angles[3];
        pev(toucher, pev_angles, angles);
        g_sPlayerData[toucher][m_vStartAngles][0] = angles[0];
        g_sPlayerData[toucher][m_vStartAngles][1] = angles[1];
        g_sPlayerData[toucher][m_vStartAngles][2] = angles[2];
        DebugPrintLevel(0, "angles are %f %f %f", angles[0], angles[1], angles[2]);

        //check if origin is already set (if player has already touched the start)
        if (g_sPlayerData[toucher][m_vStartOrigin][0] == 0.0 && g_sPlayerData[toucher][m_vStartOrigin][1] == 0.0 && g_sPlayerData[toucher][m_vStartOrigin][2] == 0.0) {
            DebugPrintLevel(0, "pub_sub_starttouch: origin not set yet, setting it now");
            //save the origin of the player to the array
            new Float:origin[3];
            pev(toucher, pev_origin, origin);
            g_sPlayerData[toucher][m_vStartOrigin][0] = origin[0];
            g_sPlayerData[toucher][m_vStartOrigin][1] = origin[1];
            g_sPlayerData[toucher][m_vStartOrigin][2] = origin[2];
        } 

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
            set_hudmessage(0,255,0,-1.0, 0.20, 0, 0, 15.0, 1.0, 0.0, 3);
            show_hudmessage(toucher, "Speedrun timer started!\n\nType /reset if you want to start over.\nYour time can only be saved once per map cycle.");
        }

        update_hud(toucher);
        spawn_thinker();

    } else if (g_sPlayerData[toucher][m_fGenericCooldown] < get_gametime()) {
        // set generic cooldown to 10 seconds
        g_sPlayerData[toucher][m_fGenericCooldown] = get_gametime() + 10.0;
        client_print(toucher, print_chat, "* Your team is not allowed to participate in this course");  
        client_cmd(toucher, "spk \"no access\"\n");
        return;
    }
}
public pub_undo(id) {
    // check if the array exists
    if (g_sPlayerData[id][m_touchedCPs] == 0) {
        client_print(id, print_chat, "* You have not touched any cps yet");
        return;
    }
    //check array size
    new iSize = ArraySize(g_sPlayerData[id][m_touchedCPs]);
    if (iSize == 0) {
        client_print(id, print_chat, "* You have not touched any cps yet");
        return;
    }
    // if there is only one cp then tell him that it cant be reset
    if (iSize == 1) {
        client_print(id, print_chat, "* You reached your first saved cp");
        return;
    }

    // check if player is alive and it not tell him to respawn
    if (!is_user_alive(id)) {
        client_print(id, print_chat, "* You have to respawn first in order to use your last cp");
        return;
    }

    //actually remove the last cp from the array
    ArrayDeleteItem(g_sPlayerData[id][m_touchedCPs], iSize - 1);

    //teleport him to the last cp saved

    pub_loadlastcp(id);
}
public pub_loadlastcp(id) {
    //check if the array exists
    if (g_sPlayerData[id][m_touchedCPs] == 0) {
        client_print(id, print_chat, "* You have not touched any cps yet");
        return;
    }
    new iSize = ArraySize(g_sPlayerData[id][m_touchedCPs]);
    new iLastCP = 0;

    if (iSize == 0) {
        client_print(id, print_chat, "* You have not touched any cps yet");
        return;
    }

    // check if player is alive and it not tell him to respawn
    if (!is_user_alive(id)) {
        client_print(id, print_chat, "* You have to respawn first in order to use your last cp");
        return;
    }
    iLastCP = ArrayGetCell(g_sPlayerData[id][m_touchedCPs], iSize - 1);
    DebugPrintLevel(0, "pub_loadlastcp: last cp is %d", iLastCP);
    // check if the classname is actually matching sw_checkpoint just to be sure
    new szClass[32];
    entity_get_string(iLastCP, EV_SZ_classname, szClass, charsmax(szClass));
    if (!equali(szClass, "sw_checkpoint")) {
        client_print(id, print_chat, "* Something weird happened here.. please report this to an admin [error: 1]");
        return;
    }

    CreateTeleportEffect(id,g_iIndexSprite);

    //play sound: 	/*EOEFFECTS*/

    emit_sound(id, CHAN_ITEM, "misc/teleport_out.wav", 0.5, ATTN_NORM, 0, PITCH_HIGH);

    new Float:fOrigin[3]; // origin of cps
    pev(iLastCP, pev_origin, fOrigin);
    // add 20 to z axis
    fOrigin[2] += 20.0;

    //remove the users velocity
    entity_set_vector(id, EV_VEC_velocity, {0.0, 0.0, 0.0});
    stock_teleport(id, fOrigin);

    //increase the amount of cps used by 1
    g_sPlayerData[id][m_iTotalCPsUsed] += 1;

}
public pub_reset(id) {
    // just teleport the player to the start orb
    new fOrigin[3];
    fOrigin[0] = g_sPlayerData[id][m_vStartOrigin][0];
    fOrigin[1] = g_sPlayerData[id][m_vStartOrigin][1]; 
    fOrigin[2] = g_sPlayerData[id][m_vStartOrigin][2];

    new fAngles[3];
    fAngles[0] = g_sPlayerData[id][m_vStartAngles][0];
    fAngles[1] = g_sPlayerData[id][m_vStartAngles][1];
    fAngles[2] = g_sPlayerData[id][m_vStartAngles][2];
    //set his initial angles with pev
    entity_set_vector(id, EV_VEC_angles, fAngles);

    //reset velocity / momentum
    entity_set_vector(id, EV_VEC_velocity, {0.0, 0.0, 0.0});
    stock_teleport(id, fOrigin);
}

public did_touch_cp(id,cp) {

    if (g_sPlayerData[id][m_touchedCPs] == 0) { return false; } //if the array does not exist yet return false
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



/* Effect when touching the goal */
stock SkillsEffectGoalTouch(id, bool:speedrun, model_lightning, model_flare)
{

    //debug message on which class called
    new szClass[32];
    entity_get_string(id, EV_SZ_classname, szClass, charsmax(szClass));
    DebugPrintLevel(0, "SkillsEffectGoalTouch: %d touched a %s", id, szClass);

    // Player position
    new Float:origin[3];
    entity_get_vector(id, EV_VEC_origin, origin);

    //Debug origin
    DebugPrintLevel(0, "SkillsEffectGoalTouch: origin is %f %f %f", origin[0], origin[1], origin[2]);


    // Use particle burst for colors
    new const COLORS[] = {250, 83, 211};
    for (new i = 0; i < sizeof(COLORS); ++i) 
    {
        message_begin(MSG_ALL, SVC_TEMPENTITY);
        write_byte(TE_PARTICLEBURST);
        write_coord_f(origin[0]);
        write_coord_f(origin[1]);
        write_coord_f(origin[2]);
        write_short(500); // radius
        write_byte(COLORS[i]); // color
        write_byte(100); // duration
        message_end();
    }

    if (!speedrun)
        return;

    message_begin(MSG_PVS, SVC_TEMPENTITY, origin);
    write_byte(TE_STREAK_SPLASH);
    write_coord_f(origin[0]);
    write_coord_f(origin[1]);
    write_coord_f(origin[2] - 40);
    write_coord_f(0);
    write_coord_f(0);
    write_coord_f(500);
    write_byte(10);
    write_short(100);
    write_short(10);
    write_short(100);
    message_end();

    // Increase player's z velocity
    // get current velocity
    new Float:velocity[3];
    entity_get_vector(id, EV_VEC_velocity, velocity);
    // set new velocity
    velocity[2] += 800.0;
    entity_set_vector(id, EV_VEC_velocity, velocity);
    //set_pev(id, pev_velocity, pev(id, pev_velocity) + 800.0);

    new const funnel_positions[] = {70, 100};
    for (new i = 0; i < sizeof(funnel_positions); ++i) 
    {
        message_begin(MSG_ALL, SVC_TEMPENTITY);
        write_byte(TE_LARGEFUNNEL);
        write_coord_f(origin[0]);
        write_coord_f(origin[1]);
        write_coord_f(origin[2] + funnel_positions[i]);
        write_short(model_flare);
        write_short(i);
        message_end();
    }

    new const beamdisk_positions[] = {0, 100, 200};
    for (new i = 0; i < sizeof(beamdisk_positions); ++i) 
    {
        message_begin(MSG_ALL, SVC_TEMPENTITY);
        write_byte(TE_BEAMDISK);
        write_coord_f(origin[0]);
        write_coord_f(origin[1]);
        write_coord_f(origin[2] + beamdisk_positions[i]);
        write_coord_f(origin[0] + 100);
        write_coord_f(origin[1]);
        write_coord_f(origin[2] + 100); // reach damage radius over .3 seconds
        write_short(model_lightning);
        write_byte(0); // startframe
        write_byte(0); // framerate
        write_byte(150); // life
        write_byte(10);  // width
        write_byte(0);   // noise
        write_byte(random_float(100.0, 255.0));   // r, g, b
        write_byte(random_float(0.0, 255.0));   // r, g, b
        write_byte(random_float(20.0, 255.0));   // r, g, b
        write_byte(210);	// brightness
        write_byte(0);		// speed
        message_end();
    }

    new const beamtorus_positions[] = {50, 150, 250};
    for (new i = 0; i < sizeof(beamtorus_positions); ++i) 
    {
        message_begin(MSG_ALL, SVC_TEMPENTITY);
        write_byte(TE_BEAMTORUS);
        write_coord_f(origin[0]);
        write_coord_f(origin[1]);
        write_coord_f(origin[2] + beamtorus_positions[i]);
        write_coord_f(origin[0]);
        write_coord_f(origin[1]);
        write_coord_f(origin[2] + 100); // reach damage radius over .3 seconds
        write_short(model_lightning);
        write_byte(0); // startframe
        write_byte(0); // framerate
        write_byte(150); // life
        write_byte(10);  // width
        write_byte(0);   // noise
        write_byte(random_float(100.0, 255.0));   // r, g, b
        write_byte(random_float(0.0, 255.0));   // r, g, b
        write_byte(random_float(20.0, 255.0));   // r, g, b
        write_byte(210);	// brightness
        write_byte(0);		// speed
        message_end();
    }
}
