#include <amxmodx>
#include <string>
#include <fakemeta>
#include <engine>

/**
 *
 * This plugin hooks into entity on the first possible frame and changes values that might cause crashes / problems on the server.
 * This is accomplished by hooking into the KeyValue call in the plugin_precache.
 * The plugin can register values and specifiy if they are handled entity specific or in general.
 * The hooks are getting called in plugin_precache and do their thing. 
 * Additionally this plugin generated info_tfdetects for maps that don't have one and spawn info_player_teamspawn / info_player_start if needed,
 * provided there is atleast one info_player_start / -_teamspawn or -_deathmatch entity on the map.
 * If there are no spawns the map is changed back to the default votemap. 
 *
 * Written for AMX Mod X by skillzworld / Vancold.at
 **/

#define CHANGEMAP "sw_mapvote_b2cw"

enum _:hook {
    h_keyname[64],        // the keyname to look for
    h_function[128],      // the custom forward we define
    h_classname[128]      // the classname of the entity (only if we want to apply the keyname to a specific ent)
}

enum _:entity {
    e_id,                 // id of the entity we changed
    e_classname[128],     // classname of the entity
    e_changed_value[256]  // the change that occured
}

new g_hooks[64][hook];
new g_entities[512][entity];

new g_register_count;
new g_change_count;
new bool: g_excuted_frame;
new g_debug;
new g_update_forward; 

new g_itd;
new g_itd_remove;

new bool: g_ipd_exists;
new bool: g_ipt_exists;
new bool: g_ips_exists;
new g_spawn_points[32];
new g_spawn_point_counter;


//  [ PLUGIN INIT & CONSOLE COMMANDS ]  //
public plugin_init() {

    register_plugin( "Mapport Plugin", "1.0", "Skillzworld / Vancold.at"  );
    register_cvar( "sw_mapport_debug", "0", FCVAR_EXTDLL );
    register_concmd( "sw_changed_ents", "print_ents", ADMIN_ADMIN, "Lists all the entities that have been changed by this plugin" );


    g_ipd_exists          = has_map_ent_class( "info_player_deathmatch" );
    g_ips_exists          = has_map_ent_class( "info_player_start" );
    g_ipt_exists          = has_map_ent_class( "info_player_teamspawn" );

    if( g_debug ) {
        console_print( 0, "[MAPPORT] Spawnpoints its: %d | ips: %d | ipt: %d; (1 = true; 0 = false)", g_ips_exists, g_ipd_exists,  g_ipt_exists );
    }
                    
    cleanup();
}

/**
 * Function to remove entities that were created in the mapload phase but are unneeded now. 
 */
public cleanup() {

    if( g_itd_remove != -1 ) {
        remove_entity( g_itd_remove );

        if( g_debug ) {
            console_print( 0, "[MAPPORT] Removed the second info_tfdetect with the id %d", g_itd_remove );
        }

    } else {
        saveEntity( g_itd, "info_tfdetect", "Spawned an info_tfdetect on the map" );
    }


    if(!g_ipt_exists) 
    {
        new classname[64], Float: origin[3], Float: angles[3], id, output[128];
        
        for(new i = 0; i < g_spawn_point_counter; i++) 
        {

            id = 0;

            if(i == 0 && !g_ips_exists) {

                new tempId = create_entity("info_player_start");
                entity_get_vector( g_spawn_points[i], EV_VEC_origin,   origin);
                entity_get_vector( g_spawn_points[i], EV_VEC_angles,   angles);
                entity_get_string( g_spawn_points[i], EV_SZ_classname, classname, charsmax( classname ));
                entity_set_vector( tempId, EV_VEC_origin,   origin);                
                entity_set_vector( tempId, EV_VEC_angles,   angles);
                entity_set_string( tempId, EV_SZ_classname, "info_player_start");

                DispatchSpawn( tempId );

                output = "";
                format( output, charsmax(output), "Missing info_player_start; Created a new one", tempId );
                saveEntity( id, "info_player_teamspawn", output );

                if( g_debug ) {
                    console_print( 0, "[MAPPORT] Missing info_player_start; Created a new one with the id %d", tempId );
                }

            }

            id = create_entity("info_player_teamspawn");
            entity_get_vector( g_spawn_points[i], EV_VEC_origin,   origin);
            entity_get_vector( g_spawn_points[i], EV_VEC_angles,   angles);
            entity_get_string( g_spawn_points[i], EV_SZ_classname, classname, charsmax( classname ));
            entity_set_vector( id, EV_VEC_origin,   origin);                
            entity_set_vector( id, EV_VEC_angles,   angles);
            entity_set_string( id, EV_SZ_classname, "info_player_teamspawn" );
            DispatchKeyValue( id, "team_no", "1" );

            DispatchSpawn( id );

            output = "";
            format( output, charsmax(output), "Converted a %s to a info_player_teamspawn", classname, id );
            saveEntity( id, "info_player_teamspawn", output );

            if( g_debug ) {
                console_print( 0, "[MAPPORT] Converted a %s to a info_player_teamspawn with the id %d", classname, id );
            }

            if(i > 0) {
                
                remove_entity(g_spawn_points[i]);
                
                if( g_debug ) {
                    console_print( 0, "[MAPPORT] Removed the extra %s (id: %d) from the map", classname, g_spawn_points[i] );
                }

            }
        }
    }

}

/**
 * Main Logic
 * We need to hook plugin_precache otherwise this whole plugin won't work; The values are getting set at precache!
 */
public plugin_precache() {

    if(!g_excuted_frame) {

        setup()
        register();

        g_update_forward     = register_forward( FM_KeyValue, "fix" );
        g_excuted_frame      = true;
        unregister_forward( FM_KeyValue, g_update_forward, 1 );

    }

}

/**
 * Function to setup variables and entities for mapport to work. 
 */
public setup() {

    g_register_count      = 0;
    g_change_count        = 0;
    g_excuted_frame       = false;
    g_debug               = get_cvar_num( "sw_mapport_debug" );
    g_itd_remove          = -1;
    g_spawn_point_counter = 0;

    for(new i = 0; i < MAX_PLAYERS; i++) {
        g_spawn_points[i] = 0;
    }

    g_itd = create_entity( "info_tfdetect" );
    entity_set_string( g_itd, EV_SZ_classname, "info_tfdetect" );
    DispatchKeyValue( g_itd, "origin", "0 0 0" );
    DispatchKeyValue( g_itd, "number_of_teams", "1" );
    DispatchKeyValue( g_itd, "maxammo_shells", "-1" );
    DispatchKeyValue( g_itd, "team1_name", "Climbers"  );
    DispatchSpawn( g_itd );

    if( g_debug ) {
        console_print( 0, "[MAPPORT] Spawned a temporary info_tfgoal with the id %d", g_itd );
    }
}

/**
 * This method prints all the changed entities affected by the plugin
 */
public print_ents( id, cid, level ) {
    
    if(g_change_count == 0) { console_print( id, "[MAPPORT] No keyvalue were changed." ); }

    for( new i = 0; i < g_change_count; i++ ) {
        console_print( id, "[MAPPORT] Entity %d '%s' - %s.", g_entities[i][e_id], g_entities[i][e_classname], g_entities[i][e_changed_value] ); 
    }
}

/**
 * The register function is used to define what values we hook and how they are process (what forward to use)
 */
public register() {

    registerChange( "angles",  "itd_fixangles", "info_teleport_destination" );
    registerChange( "dmg",      "fix_dmg",       "" );
    registerChange( "message",  "fix_message",   "" );
    registerChange( "roomtype", "remove_sound",  "env_sound" );

}

//  [ PLUGIN LOGIC ]  //
/**
 * Function to store the keyname + forward and classname; The classname determines if the forward is called on a specific entity or ALL entities with the
 * given keyname
 */
public registerChange( keyname[], function[], classname[] ) {

    new entry[hook];

    copy( entry[h_keyname],   charsmax( entry[h_keyname] ),   keyname );
    copy( entry[h_function],  charsmax( entry[h_function] ),  function );
    copy( entry[h_classname], charsmax( entry[h_classname] ), classname );

    g_hooks[g_register_count] = entry;
    g_register_count += 1; 


    if( g_debug ) { 

        if( strlen(classname) == 0 ) {
            console_print( 0, "[MAPPORT] Registered the value %s.", keyname ); 
        } else {
            console_print( 0, "[MAPPORT] Registered the value %s, checking it only for %s.", keyname, classname ); 
        }
    }
}

/**
 * Main Logic
 * This is the FM_KeyValue forward; it gets the ent-id (as id) and the kvd_id (the handle that corresponds to the current keyvalue-dataset).
 * If the entitiy is not a map entity the forward will be ignored, otherwise it will create a forward by checking if the keyname is stored
 * in g_hooks; if it is, it will check if a class name is provided
 * -> if there is a classname this forward will only be applied to the registered classname + keyname 
 * -> if no classname is provided it will execute for all keynames that are registered
 * Once the function is done it will kill the newly created forward
 */
public fix( id, kvd_id ) {

    // Checking if we are looking at a map ent or not
    if( !pev_valid( id ) ) { return; }

    // variables used for the method; 
    new kvd_classname[128], kvd_keyname[64], regId;
    
    // reading out the classname and keyname to check if we have to trigger the logic
    get_kvd( kvd_id, KV_ClassName, kvd_classname, charsmax( kvd_classname ) );
    get_kvd( kvd_id, KV_KeyName,   kvd_keyname,   charsmax( kvd_keyname ) );


    if( equali( kvd_classname, "info_tfdetect" ) ) {


        if( g_itd_remove == -1 ) {

            g_itd_remove = id;

            DispatchKeyValue( g_itd, "number_of_teams", "" );
            DispatchKeyValue( g_itd, "maxammo_shells", "" );
            DispatchKeyValue( g_itd, "team1_name", "" );
            DispatchKeyValue( g_itd, "origin", "" );

            if( g_debug ) {
                console_print( 0, "[MAPPORT] Found a info_tfdetect with the id %d on the map. Replacing the values of the temprary info_tfdetect (%d) with the existing ones", id, g_itd );
            }
        }
        
        new kvd_value[128];
        get_kvd( kvd_id, KV_Value, kvd_value, charsmax( kvd_value ) );
        DispatchKeyValue( g_itd, kvd_keyname, kvd_value );

    }

    if( equali( kvd_classname, "info_player_start" ) || equali( kvd_classname, "info_player_deathmatch" ) ) {

        if(!exists_in_array(id)) {
            g_spawn_points[g_spawn_point_counter] = id;
            g_spawn_point_counter++;
        }
        
    }
    

    // Checking if the keyname is registered in g_hooks
    regId = isRegistered( kvd_keyname );

    // -1 means no hook is found -> return
    if( regId == -1 ) {
        return;
    }  

    // if the classname of the current hook we are checking is not null but does not match our keyvalue classname -> return; 
    if( strlen( g_hooks[regId][h_classname] ) != 0 && !equali( kvd_classname,g_hooks[regId][h_classname] ) ) {
        return;
    }

    // We are good to go, we are setting up the forward
    new Forward, ReturnVal, handle[64];

    // Getting the callback we are using for the forward, stored in g_hook
    copy( handle, charsmax( handle ), g_hooks[regId][h_function] );

    /* 
     * CreateMultiForward creates Forward that is useable in all plugins; We could just use CreateOneForward but that would require us to know our plugin-id
     * that is tiresome so we just define it as multi, which works the same but is easier to handle
     * The parameters are the callback, how the return value of the forward is handled + the parameters; The parameters are given as FP_*
     *  FP_CELL = int; FP_FLOAT = float, FP_STRING = string, FP_ARRAY = array.
     */
    Forward = CreateMultiForward( handle, ET_IGNORE, FP_CELL, FP_CELL, FP_STRING );

    // If the forward is invalid or couldn't be executed we should print an error message
    if( !Forward || !ExecuteForward( Forward, ReturnVal, kvd_id, id, kvd_classname ) ) {
        if( g_debug ) {
            console_print( 0, "[MAPPORT] Could not execute ^"%s^" forward.", handle ); 
        } 
    } 
    
    // In any case destroy the forward after we are done
    DestroyForward( Forward );

}

/**
 * Checks if the given id is stored in the spawnpoint array
 */
public exists_in_array(id) {
    
    for(new i = 0; i < g_spawn_point_counter; i++) {

        if(g_spawn_points[i] == id)
            return true;

    }

    return false;
}


/**
 * Checks if the keyname (toCheck) is stored in g_hooks; True if it stored in g_hooks, otherwise false
 */
public isRegistered( toCheck[] ) {

    for(new i = 0; i < g_register_count; i++) {

        new tempIdentifier[64];
        copy( tempIdentifier, charsmax( tempIdentifier ), g_hooks[i][h_keyname] );


        if( equali( toCheck, tempIdentifier ) ) {
            return i;
        }

    }

    return -1;
}


/**
 * Stores the changed keyname value + entid and the change note inside an array for printing purposes
 */
public saveEntity( id, name[], change[] ) {

    new entry[entity];
    entry[e_id] = id;
    copy( entry[e_classname],     charsmax( entry[e_classname] ),     name );
    copy( entry[e_changed_value], charsmax( entry[e_changed_value] ), change );

    g_entities[g_change_count] = entry;
    g_change_count += 1;

    return;
    
}


//  [ FORWARDS ]  //
/**
 * Function hook to change the dmg keyvalue for any entity that has a damage value < -1 to -1
 */
public fix_dmg( kvd_id, id, classname[] ) {

    new input[32], Float: dmg;

    get_kvd( kvd_id, KV_Value, input, 31 );
    dmg = str_to_float( input );

    if( dmg < -1.0 ) {

        set_kvd( kvd_id, KV_Value, "-1.0" );

        new output[128]; 
        format( output, charsmax( output ), "Negative damage for %s: %i (Changed to: -1).", classname, id );

        saveEntity( id, classname, output );

        if( g_debug ) { 
            console_print( 0, "[MAPPORT] %s", output ); 
        }

    }

}

/**
 * Function hook to change the message keyvalue for any entity that has a message length greater than 73 and setting it to a default string
 */
public fix_message( kvd_id, id, classname[] ) {
 
    new input[128], len;

    get_kvd( kvd_id, KV_Value, input, charsmax( input ) );
    len = strlen( input );

    if( len > 73 ) {

        set_kvd( kvd_id, KV_Value, "- = skillzworld.eu = -" );

        new output[128]; 
        format( output, charsmax( output ), "Message length exceeded 74 for %s (Changed to: - = skillzworld.eu = -).", classname, id );

        saveEntity( id, classname, output );

        if( g_debug ) { 
            console_print( 0, "[MAPPORT] %s", output ); 
        }

    }

}

/**
 * Function hook to change the angles keyvalue for info_teleport_destination where the z value is not 0, setting it to 0
 */
public itd_fixangles( kvd_id, id, classname[] ) {

    new input[36], exploded[3][12], Float: angles[3];
    get_kvd( kvd_id, KV_Value, input, charsmax( input ) );
    explode_string( input, " ", exploded, 3, 12 );

    angles[0] = str_to_float( exploded[0] );
    angles[1] = str_to_float( exploded[1] );
    angles[2] = str_to_float( exploded[2] );

    if( angles[2] > 0 ) {

        new changed[32];
        format( changed, charsmax( changed ), "%f %f %f", angles[0], angles[1], 0.0 );
        set_kvd( kvd_id, KV_Value, changed );

        new output[128];
        format( output, charsmax( output ), "Z value in angles can not be bigger than 0 in %s (Changed %f to 0.0).", classname, id, angles[2] );

        saveEntity( id, classname, output );

        if( g_debug ) {
            console_print( 0, "[MAPPORT] %s ", output );
        }
    }
    
}

/**
 * Function hook to change the stepsound keyvalue for an env_sound entity that has a roomtype that is not 0 and chaning it to 0
 */
public remove_sound( kvd_id, id, classname[] ) {

    new input[32], roomType;

    get_kvd( kvd_id, KV_Value, input, charsmax( input ) );
    roomType = str_to_num( input );

    if( roomType != 0 ) {
        set_kvd( kvd_id, KV_Value, "0" );

        new output[128];
        format( output, charsmax( output ), "Changed roomtype value, removing the old value for %s (Changed %d to 0).", classname, id, roomType );

        saveEntity( id, classname, output );

        if( g_debug) {
            console_print( 0, "[MAPPORT] %s", output );
        }
    }
}