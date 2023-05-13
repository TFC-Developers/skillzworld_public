/*
 * Santa Hat Plugin for SkillzWorld
 *
 * This plugin adds santa hats to players in Team Fortress Classic
 * during the specified holiday season (December 1st to January 2nd).
 *
 * Written for AMX Mod X by skillzworld / MrKoala
 */

#include "include/global"
#include <fun>
#include <engine>
#include <time>
#include <fakemeta>

// Variables
new bool:g_bHasHat[33]; // Array to store whether each player has a santa hat (assumes a maximum of 32 players).
new bool:b_itsDecember = false; // Indicates if the current date is within the holiday season.
new bool:g_SnowPreache = false; // Indicates if the santa hat model has been successfully pre-cached.

// Plugin information
public plugin_init() {
    RegisterPlugin();

    // Initialize the cvar
    register_cvar("sw_snowballs", "0", FCVAR_EXTDLL);

    // Register the think function to be called every second
    register_think("SantaHatThink", "sw_santahat");

    // Check the current date and set b_itsDecember accordingly
    check_date();

    // register the santa hat think function 
    register_forward( FM_PlayerPreThink,    "AddSantaHat",    0 );
}

// Function to pre-cache resources at map start
public plugin_precache() {
    // Pre-cache the santa hat model
    precache_model("models/skillzworld/santa_hat.mdl");
    g_SnowPreache = true;
}

// Function to check the date and update b_itsDecember at the end of each map
public plugin_endmap() {
    check_date();
}

// Function to set the global boolean hat variable for that player to false
public client_putinserver(id) {
    g_bHasHat[id] = false;
    console_print(0, "Connect:  id: %d hashat?! --> %d", id, g_bHasHat[id]);
}
// Function to add a santa hat to the specified player if the conditions are met
public AddSantaHat(id) {
    new Float:sw_snowballs = get_cvar_float("sw_snowballs");
    if (sw_snowballs == 1.0 || (sw_snowballs >= 2.0 && b_itsDecember)) {
        if (!g_bHasHat[id] && g_SnowPreache) {
            console_print(0, "AddHat:  id: %d hashat?! --> %d", id, g_bHasHat[id]);
            if (is_user_connected(id) || entity_get_int(id, EV_INT_team) >= 1 && entity_get_int(id, EV_INT_team) <= 4) {
                console_print(0, "AddHat - 2 - :  id: %d hashat?! --> %d", id, g_bHasHat[id]);
/*
					edict_t *pent;
					pent = CREATE_NAMED_ENTITY(MAKE_STRING("info_target"));
					MDLL_Spawn(pent);
					pent->v.classname = MAKE_STRING("sw_santahat");
					SET_MODEL(ENT(pent), "models/skillzworld/santa_hat.mdl");
					pent->v.takedamage = DAMAGE_NO;
					pent->v.movetype = MOVETYPE_FOLLOW;
					pent->v.health = 100;
					pent->v.nextthink = gpGlobals->time + 0.1;
					pent->v.fuser1 = gpGlobals->time + 2;
					pent->v.solid = SOLID_NOT;
					pent->v.owner = pEntity;
					pent->v.aiment = pEntity;
					g_bHasHat[ENTINDEX(pEntity)] = true;
				}*/
                //new entity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
                new entity = CREATE_NAMED_ENTITY()
                dllfunc(DLLFunc_Spawn, entity);
                //new entity = create_entity("info_target");
                entity_set_string(entity, EV_SZ_classname, "sw_santahat");
                engfunc(EngFunc_SetModel, entity, "models/skillzworld/santa_hat.mdl");
                
                entity_set_float(entity, EV_FL_nextthink, (get_gametime() + 0.5) )
                entity_set_float(entity, EV_FL_takedamage, DAMAGE_NO);
                entity_set_int(entity, EV_INT_movetype, MOVETYPE_FOLLOW);
                entity_set_float(entity, EV_FL_health, 100);
                entity_set_int(entity, EV_INT_solid, SOLID_NOT);
                entity_set_int(entity, EV_ENT_owner, id);
                entity_set_int(entity, EV_ENT_aiment, id);
                g_bHasHat[id] = true;
                console_print(0, "AddHat - 3 - :  id: %d hashat?! --> %d", id, g_bHasHat[id]);
            }
        }
    }
}

// Function to handle the santa hat entities and remove them if the player is disconnected or not in a valid team
public SantaHatThink(entity) {
    new id = entity_get_int(entity, EV_ENT_owner);
    console_print(0, "Hat is thinking..");
    if (!is_user_connected(id) || entity_get_int(id, EV_INT_team) < 1 || entity_get_int(id, EV_INT_team) > 4  || g_bHasHat[id]) {
        g_bHasHat[id] = false;
        entity_set_int(entity, EV_INT_flags, FL_KILLME);
        console_print(0, "REMOVEHAT           id: %d hashat?! --> %d", id, g_bHasHat[id]);
    }
    entity_set_float(entity, EV_FL_nextthink, (get_gametime() + 0.5) )
}

// Function to check the current date and set b_itsDecember accordingly
public check_date() {
    new year, month, day;
    date(year, month, day);

    if(month == 12 || (month == 1 && day <= 2)) {
        b_itsDecember = true;
    } else {
        b_itsDecember = false;
    }
}