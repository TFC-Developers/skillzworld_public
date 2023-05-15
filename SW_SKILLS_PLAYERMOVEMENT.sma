/*
 * entity use command plugin for SkillzWorld
 *
 * This plugin will make players non-solid and enables them to walk through other players.
 * Furthermore it will apply a hologram effect to the player if he is near another player.
 *
 * Written for AMX Mod X by skillzworld / MrKoala
 */

#include "include/global"
#include <engine>
#include <fakemeta>
#include "include/utils"


#define BEAM_SPRITE "sprites/laserbeam.spr"
new g_Beamsprite = 0;
new g_bPlayerNearby[33];
new g_bPlayerTempNoClip[33];
new g_fPlayerOrigin[33][3];
new g_iPlayerTeam[33];

public plugin_precache() {
	precache_sound("ambience/thunder_clap.wav");
    g_Beamsprite = precache_model(BEAM_SPRITE);

}
public plugin_init() {
    RegisterPlugin();
    register_forward(FM_AddToFullPack, "Hook_AddToFullPack",1);
    register_clcmd("say /clipon", "cmd_tempnoclip");
    register_clcmd("say /clipoff", "cmd_tempnoclip");
    register_clcmd("say /noclip", "cmd_tempnoclip");
    register_clcmd("say /clip", "cmd_tempnoclip");

    register_clcmd("say /slaytest", "cmd_slaytest");

    set_task(0.5, "timer_FindEntityInSphere",_, _,_,"b");
}

public cmd_slaytest(id) {
    stock_slay(id);
}
public cmd_tempnoclip(id) {
    if (g_bPlayerTempNoClip[id]) {

        //return if players team is not in range 1-4
        if (pev(id, pev_team) < 1 || pev(id, pev_team) > 4) {
            client_print(id, print_chat, "> You are not in a team anymore.");
            g_bPlayerTempNoClip[id] = false;
            g_fPlayerOrigin[id][0] = 0;
            g_fPlayerOrigin[id][1] = 0; 
            g_fPlayerOrigin[id][2] = 0;
            g_iPlayerTeam[id] = 0;
            return PLUGIN_HANDLED;
        }

        //check wether the player changed teams or class
        new iTeam, iClass;
        iTeam = pev(id, pev_team);
        iClass = pev(id, pev_playerclass);
        new iChecksum = iTeam + iClass;

        if (g_iPlayerTeam[id] != iChecksum) {
            stock_slay(id);
            client_print(id, print_chat, "> Silly you! You changed your team or class.");
            g_bPlayerTempNoClip[id] = false;
            g_fPlayerOrigin[id][0] = 0;
            g_fPlayerOrigin[id][1] = 0; 
            g_fPlayerOrigin[id][2] = 0;
            g_iPlayerTeam[id] = 0;
            return PLUGIN_HANDLED;
        }
        
        g_bPlayerTempNoClip[id] = false;

        entity_set_int(id, EV_INT_solid, 5);
        entity_set_int(id, EV_INT_movetype, MOVETYPE_WALK);

        //remove the trail
        message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
        write_byte(TE_KILLBEAM);
        write_short(id);
        message_end();

        //Teleport player to old position
        stock_teleport(id, g_fPlayerOrigin[id]);    

    } else {
        // don't allow when playerclass is 9 (engineer)
        if (pev(id, pev_playerclass) == 9) {
            client_print(id, print_chat, "> You are an engineer. You can't noclip.");
            return PLUGIN_HANDLED;
        }

        //don't allow when player already has noclip
        if (entity_get_int(id, EV_INT_movetype) == MOVETYPE_NOCLIP) {
            client_print(id, print_chat, "> You already have noclip.");
            return PLUGIN_HANDLED;
        }

        //don't allow when player is not in a team
        if (pev(id, pev_team) < 1 || pev(id, pev_team) > 4) {
            client_print(id, print_chat, "> This function is not allowed while in spectator mode.");
            return PLUGIN_HANDLED;
        }

        //only allow when player has no velocity
        new Float:vel[3];
        pev(id, pev_velocity, vel);
        if (vel[0] != 0 || vel[1] != 0 || vel[2] != 0) {
            client_print(id, print_chat, "> You can only noclip when you are not moving.");
            return PLUGIN_HANDLED;
        }

        //only allow when player is onground
        if (pev(id, pev_flags) & FL_ONGROUND == 0) {
            client_print(id, print_chat, "> You can only noclip when you are on the ground.");
            return PLUGIN_HANDLED;
        }

        //now we can noclip
        new Float:origin[3];
        pev(id, pev_origin, origin);
        g_fPlayerOrigin[id] = origin;
        g_iPlayerTeam[id] = pev(id, pev_team) + pev(id, pev_playerclass);
        g_bPlayerTempNoClip[id] = true;

        entity_set_int(id, EV_INT_solid, 0);
        entity_set_int(id, EV_INT_movetype, MOVETYPE_NOCLIP);

        //create a trail
        message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
        write_byte(TE_BEAMFOLLOW);
        write_short(id);
        write_short(g_Beamsprite);
        write_byte(10); // life
        write_byte(4); // width
        write_byte(0); // r
        write_byte(127); // g
        write_byte(255); // b
        write_byte(128); // brightness
        message_end();


        client_print(id, print_chat, "You are now non-solid.");

        return PLUGIN_HANDLED;
    }
}

public client_putinserver(id) {
    g_bPlayerNearby[id] = false;
    g_bPlayerTempNoClip[id] = false;
    g_fPlayerOrigin[id][0] = 0;
    g_fPlayerOrigin[id][1] = 0;
    g_fPlayerOrigin[id][2] = 0;
    g_iPlayerTeam[id] = 0;

}   

public client_disconnected(id) {
    g_bPlayerNearby[id] = false;
    g_bPlayerTempNoClip[id] = false;
    g_fPlayerOrigin[id][0] = 0;
    g_fPlayerOrigin[id][1] = 0;
    g_fPlayerOrigin[id][2] = 0;
    g_iPlayerTeam[id] = 0;

}   

public Hook_AddToFullPack(es_handle, e, ent, host, hostflags, player, pSet){

    //Let the other client think that the player is not solid (prevent edge collision)
    if (e <= get_maxplayers()) {

        //check if e is in team greater 1 and smaller 4
        if (pev(e, pev_team) >= 1 && pev(e, pev_team) <= 4) {

            set_es(es_handle,ES_Solid,SOLID_NOT);

            if (g_bPlayerNearby[e]) {

                set_es(es_handle,ES_RenderMode,kRenderTransAlpha);
                set_es(es_handle,ES_RenderFx,kRenderFxGlowShell);
                set_es(es_handle,ES_RenderAmt,130);
            }
        }
    }

    return FMRES_HANDLED;
}



public timer_FindEntityInSphere()
{
	static Float:origin[3];
	static class[32];
	static ent;

  for (new i = 1; i <= get_maxplayers(); i++)
  {
        //DebugPrintLevel(0, "Checking player %d", i);
        if (is_connected_user(i)) {

            // set player to not solid if not in temporary noclip
            if (!g_bPlayerTempNoClip[i]) {
                entity_set_int(i, EV_INT_solid, 5);
            }

            g_bPlayerNearby[i] = false; // Reset the player nearby flag
            ent = -1;
            pev(i, pev_origin, origin);
            while((ent = engfunc(EngFunc_FindEntityInSphere, ent, origin, 150.0)))
            {
                // We don't want our own entity
                if(ent == i)
                    continue;
                
                pev(ent, pev_classname, class, charsmax(class));

                if(equal(class, "player") && pev(ent, pev_team) >= 1 && pev(ent, pev_team) <= 4) // Check if the entity is a player
                {                    
                    g_bPlayerNearby[i] = true;
                    break;
                }

            }
        }
    }
}
