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


#define BEAM_SPRITE "sprites/laserbeam.spr"
new g_bPlayerNearby[33];


public plugin_init() {
    RegisterPlugin();
    register_forward(FM_AddToFullPack, "Hook_AddToFullPack",1);

    //call the timer function every 0.5 seconds
    set_task(0.5, "timer_FindEntityInSphere",_, _,_,"b");
}

public client_putinserver(id) {
    g_bPlayerNearby[id] = false;
}   

public client_disconnected(id) {
    g_bPlayerNearby[id] = false;
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
            new solidstate;
            pev(i,pev_solid,solidstate);
            DebugPrintLevel(0, "Player %d has solid state %d", i, solidstate);
            //set_pev(i,pev_solid,5);
            entity_set_int(i, EV_INT_solid, 5);
            DebugPrintLevel(0, "Player %d has now solid state %d", i, solidstate);
            //DebugPrintLevel(0, "Player is connected");
            g_bPlayerNearby[i] = false; // Reset the player nearby flag
            ent = -1;
            pev(i, pev_origin, origin);
            while((ent = engfunc(EngFunc_FindEntityInSphere, ent, origin, 150.0)))
            {

                // We don't want our own entity
                if(ent == i)
                    continue;
                
                pev(ent, pev_classname, class, charsmax(class));
                //DebugPrintLevel(0, "Found entity %d with class %s", ent, class);
                if(equal(class, "player") && pev(ent, pev_team) >= 1 && pev(ent, pev_team) <= 4) // Check if the entity is a player
                {                    
                    g_bPlayerNearby[i] = true;
                    break;
                }

            }
        }
    }
}
