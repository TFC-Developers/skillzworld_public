/*
 * Santa Hat Plugin for SkillzWorld
 *
 * This plugin adds santa hats to players in Team Fortress Classic
 * during the specified holiday season (December 1st to January 2nd).
 *
 * Written for AMX Mod X by skillzworld / MrKoala & Vancold
 * Changelog:
 * 14.05.2023: Initial release
 * 15.05.2023: debugged by Vancold
 * 16.05.2023: Added candy cane umbrella
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
    precache_model("models/skillzworld/p_candy.mdl");
    precache_model("models/skillzworld/v_candy.mdl");
    g_SnowPreache = true;
}

// Function to check the date and update b_itsDecember at the end of each map
public plugin_endmap() {
    check_date();
}

// Function to set the global boolean hat variable for that player to false
public client_putinserver(id) {
    g_bHasHat[id] = false;
}

// Function to add a santa hat to the specified player if the conditions are met
public AddSantaHat(id) {
    new Float:sw_snowballs = get_cvar_float("sw_snowballs");
    if (sw_snowballs == 1.0 || (sw_snowballs >= 2.0 && b_itsDecember)) {

        // Candy cane umbrella
        new szViewModel[64]; entity_get_string(id, EV_SZ_viewmodel, szViewModel, charsmax(szViewModel));
        if (equali(szViewModel, "models/v_umbrella.mdl")) {
            entity_set_string(id, EV_SZ_viewmodel, "models/skillzworld/v_candy.mdl");
            entity_set_string(id, EV_SZ_weaponmodel, "models/skillzworld/p_candy.mdl");
        }

        if (!g_bHasHat[id] && g_SnowPreache) {
            if ( is_user_connected(id) && is_user_alive(id) && entity_get_int(id, EV_INT_team) >= 1 && entity_get_int(id, EV_INT_team) <= 4 ) {

                new entity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
                entity_set_string(entity, EV_SZ_classname, "sw_santahat");
                engfunc(EngFunc_SetModel, entity, "models/skillzworld/santa_hat.mdl");
                
                entity_set_float(entity, EV_FL_nextthink, (get_gametime() + 0.5) )
                entity_set_float(entity, EV_FL_takedamage, DAMAGE_NO);
                entity_set_int(entity, EV_INT_movetype, MOVETYPE_FOLLOW);
                entity_set_float(entity, EV_FL_health, 100.0);
                entity_set_int(entity, EV_INT_solid, SOLID_NOT);
                entity_set_int(entity, EV_ENT_owner, id);
                entity_set_edict(entity, EV_ENT_aiment, id);
                g_bHasHat[id] = true;
            }
        }
    }
}

// Function to handle the santa hat entities and remove them if the player is disconnected or not in a valid team
public SantaHatThink(entity) {
    new id = entity_get_int(entity, EV_ENT_owner);
    if (!is_user_connected(id) || entity_get_int(id, EV_INT_team) < 1 || entity_get_int(id, EV_INT_team) > 4  || g_bHasHat[id]) {
        g_bHasHat[id] = false;
        entity_set_int(entity, EV_INT_flags, FL_KILLME);
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
