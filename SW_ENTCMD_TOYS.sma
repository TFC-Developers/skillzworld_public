#include "include/global"
#include <engine>
#include <fun>
#include <tfcx>
#include <fakemeta>
#include <message_const>

#define VEC_TO_FVEC(%1,%2) %2[0] = float(%1[0]); %2[1] = float(%1[1]); %2[2] = float(%1[2])
#define FVEC_TO_VEC(%1,%2,%3) %2[0] = floatround(%1[0],%3); %2[1] = floatround(%1[1],%3); %2[2] = floatround(%1[2],%3)

stock const PREFIX_MDL_PLAYER[] = "models/player/"
stock const MDL_CIVILIAN[] = "models/player/civilian/civilian.mdl"
stock const MDL_HGIBS[] = "models/hgibs.mdl"
stock const SPR_LIGHTNING[] = "sprites/lgtning.spr"
stock const SPR_LASERBEAM[] = "sprites/laserbeam.spr"
stock const SEARCH_ALL[] = "all"
stock const PLAYER[] = "player"
new Trie:defaults = Invalid_Trie
new res_lightning
new res_laserbeam
new res_civilian
new res_hgibs
stock const AMMO_TYPES[][] = { // The indices are the values of the ammo enum in tfcconst.inc
	"shells",
	"bullets",
	"cells",
	"rockets",
	"nade1",
	"nade2",
}
public plugin_init() {
	RegisterPlugin
	register_concmd "e_create", "cmd_create", ADMIN_ADMIN, "Spawns an entity. First argument is the class name, second argument can be positioning information, further argument pairs make keyvalues."
	register_concmd "e_give", "cmd_give", ADMIN_ADMIN, "Gives an item to a player."
	register_concmd "new_e_kill", "cmd_kill", ADMIN_ADMIN, "Deletes an entity."
	register_concmd "e_kv", "cmd_kv", ADMIN_ADMIN, ""
	register_concmd "e_default", "cmd_defaults", ADMIN_ADMIN, "Set default keyvalues for spawning entities. Prefix a key with ! to remove it."
	register_concmd "e_defaults", "cmd_defaults", ADMIN_ADMIN, "Set default keyvalues for spawning entities. Prefix a key with ! to remove it."
	register_concmd "e_nearmodel", "cmd_nearmodel", ADMIN_ADMIN, "Find a nearby entity and get its model."
}
public plugin_precache() {
	res_lightning = precache_model(SPR_LIGHTNING)
	res_laserbeam = precache_model(SPR_LASERBEAM)
	res_civilian = precache_model(MDL_CIVILIAN)
	res_hgibs = precache_model(MDL_HGIBS)
	
	defaults = TrieCreate()
	TrieSetString defaults, "model", MDL_CIVILIAN
}
public plugin_end() {
	TrieDestroy defaults
}
public cmd_defaults(id, level, cid) {
	new args_n = read_argc()
	static arg1[0x40], arg2[0x40]
	for (new arg_i = 1; arg_i < args_n; ) {
		read_argv arg_i++, arg1, charsmax(arg1)
		if (arg1[0] == '!') {
			TrieDeleteKey defaults, arg1[1]
			console_print id, "Removed default kv: \"%s\"", arg1[1]
		} else {
			read_argv arg_i++, arg2, charsmax(arg2)
			TrieSetString defaults, arg1, arg2
			console_print id, "Added default kv: \"%s\", \"%s\"", arg1, arg2
		}
		
	}
}
public cmd_nearmodel(id, level, cid) {
	static Float:origin[3], Float:radius
	radius = read_argv_float(1)
	entity_get_vector id, EV_VEC_origin, origin
	static model[0x40], classname[0x40]
	new ent
	while ((ent = find_ent_in_sphere(ent, origin, radius))) {
		if (ent == id) continue
		entity_get_string ent, EV_SZ_model, model, charsmax(model)
		if (!model[0] || model[0] == '*') continue // Skip brush models
		entity_get_string ent, EV_SZ_classname, classname, charsmax(classname)
		console_print id, "Entity %d \"%s\" has model \"%s\"", ent, classname, model
		return
	}
	console_print id, "Nothing found"
}
public cmd_kv(id, level, cid) {
	// Usage
	// e_kv skin - View a keyvalue from the aimed entity
	// e_kv skin 11 - Set specific keyvalue from the aimed entity
	// e_kv 1000 model - Find a nearby ent and get its keyvalue (useless because of invisible volume entities everywhere)
	// e_kv cycler skin 11 - Do it to all cyclers
	// e_kv cycler 1000 skin 11 - Find a cycler in a 1000u radius around you and set its keyvalue
	// e_kv cycler 1000 skin - Get it instead
	// e_kv cycler 1000 all skin 11 - Set keyvalue for all cyclers in that radius
	new args_n = read_argc(), arg_i = 1
	static arg1[0x40], arg2[0x40]
	static classname[0x40], found_classname[0x40]
	static Float:radius, Float:origin[3]
	new count
	new ent
	radius = read_argv_float(arg_i)
	if (radius) {
		arg_i++ // Go past radius
		entity_get_vector id, EV_VEC_origin, origin
		read_argv arg_i, arg1, charsmax(arg1)
		if (args_n - arg_i == 1) { // There is only 1 argument, so find only
			while ((ent = find_ent_in_sphere(ent, origin, radius))) {
				if (ent == id) continue
				print_kv id, ent, arg1
				return
			}
			console_print id, "Found nothing"
		} else {
			console_print id, "Radius set for any entity not implemented."
		}
		return
	}
	
	if (args_n <= 3) { // Aim find
		get_user_aiming id, ent
	} else { // Classname find
		read_argv arg_i++, classname, charsmax(classname)
		radius = read_argv_float(arg_i)
		if (!radius) { // Arg 2 is actually classname, so set all
			read_argv arg_i, arg1, charsmax(arg1)
			read_argv arg_i + 1, arg2, charsmax(arg2)
			while ((ent = find_ent_by_class(ent, classname))) {
				DispatchKeyValue ent, arg1, arg2
				count++
			}
			console_print id, "Set %d keyvalues \"%s\": \"%s\" for all entities of class \"%s\"", count, arg1, arg2, classname
			return
		}
		// Radius find
		arg_i++ // Go past radius
		entity_get_vector id, EV_VEC_origin, origin
		if (args_n - arg_i == 3) { // "all key value" - Set all in radius
			arg_i++ // Go past "all"
			read_argv arg_i, arg1, charsmax(arg1)
			read_argv arg_i + 1, arg2, charsmax(arg2)
			while ((ent = find_ent_in_sphere(ent, origin, radius))) {
				entity_get_string ent, EV_SZ_classname, found_classname, charsmax(found_classname)
				if (!equal(classname, found_classname)) continue
				DispatchKeyValue ent, arg1, arg2
				DispatchKeyValue ent, arg1, arg2
				count++
			}
			console_print id, "Set %d keyvalue \"%s\": \"%s\" for all entities of class \"%s\" in radius %f", count, arg1, arg2, classname, radius
			return
		}
		
		// Find single entity in radius:
		entity_get_vector id, EV_VEC_origin, origin
		new bool:found = false
		while ((ent = find_ent_in_sphere(ent, origin, radius))) {
			entity_get_string ent, EV_SZ_classname, found_classname, charsmax(found_classname)
			if (equal(classname, found_classname)) {found = true; break;}
		}
		if (!found) ent = 0
	}
	
	/// Set/get single
	if (!ent) {
		console_print id, "Did not find a target entity."
		return
	}
	read_argv arg_i, arg1, charsmax(arg1)
	if (args_n - arg_i == 1) { // The argument list ends with a key name, so read
		print_kv(id, ent, arg1)
	} else { // The argument list ends with a key name and a value, so set
		read_argv arg_i + 1, arg2, charsmax(arg2)
		DispatchKeyValue ent, arg1, arg2
		console_print id, "Set keyvalue:\n\"%s\": \"%s\"", arg1, arg2
	}
	return
}
stock print_kv(id, ent, const key[]) {
	enum /*PRESET_MEMORY_TYPE*/ {
		PM_INT,
		PM_FLOAT,
		PM_VECTOR,
		PM_STRING,
	}
	static const PRESET_KEYS[][] = {
		"classname",
		"model",
		"body",
		"skin",
		"origin",
		"angles",
		"spawnflags",
		"renderamt",
		"renderfx",
		"rendermode",
		"rendercolor",
	}
	static const PRESET_KEY_PAIRS[sizeof PRESET_KEYS][2] = {
		{EV_SZ_classname	, PM_STRING	},
		{EV_SZ_model		, PM_STRING	},
		{EV_INT_body		, PM_INT	},
		{EV_INT_skin		, PM_INT	},
		{EV_VEC_origin		, PM_VECTOR	},
		{EV_VEC_angles		, PM_VECTOR	},
		{EV_INT_spawnflags	, PM_INT	},
		{EV_FL_renderamt	, PM_FLOAT	},
		{EV_INT_renderfx	, PM_INT	},
		{EV_INT_rendermode	, PM_INT	},
		{EV_VEC_rendercolor	, PM_VECTOR	},
	}
	static any:vec[3], str[0x40]
	new bool:found = false
	for (new i; i < sizeof PRESET_KEYS; i++) {
		if (!equali(key, PRESET_KEYS[i])) continue
		new k_field = PRESET_KEY_PAIRS[i][0], k_type = PRESET_KEY_PAIRS[i][1]
		switch (k_type) {
		case PM_INT: {console_print id, "\"%s\": \"%d\"", PRESET_KEYS[i], entity_get_int(ent, k_field);}
		case PM_FLOAT: {console_print id, "\"%s\": \"%f\"", PRESET_KEYS[i], entity_get_float(ent, k_field);}
		case PM_VECTOR: {entity_get_vector ent, k_field, vec; console_print id, "\"%s\": \"%f %f %f\"", PRESET_KEYS[i], vec[0], vec[1], vec[2];}
		case PM_STRING: {entity_get_string ent, k_field, str, charsmax(str); console_print id, "\"%s\": \"%s\"", PRESET_KEYS[i], str;}
		}
		found = true
	}
	if (!found) console_print id, "No match for key \"%s\" hardcoded in the plugin.", key
}
public cmd_kill(id, level, cid) {
	// Usage:
	// (look at entity) e_kill - Destroy aimed entity
	// (look at entity) e_kill cycler - Destroy aimed entity if it's a cycler
	// e_kill cycler all - Destroy all cyclers
	// e_kill cycler 1000 - Destroy a cycler within 1000u of distance
	// e_kill cycler 1000 all - Destroy all cyclers within 1000u of distance
	new args_n = read_argc()
	new classname[0x20]
	new targetname[0x20]; read_argv 1, targetname, charsmax(targetname)
	new ent
	if (args_n <= 2) { // Aim and kill
		get_user_aiming id, ent
		new hitpos[3]; get_user_origin id, hitpos, 3
		
		if (!ent) return PLUGIN_HANDLED
		
		entity_get_string ent, EV_SZ_classname, classname, charsmax(classname)
		
		if (args_n == 2 && !equal(classname, targetname)) return PLUGIN_HANDLED
		
		message_begin MSG_BROADCAST, SVC_TEMPENTITY;
		{
			write_byte TE_BEAMENTPOINT
			write_short id
			write_coord hitpos[0]
			write_coord hitpos[1]
			write_coord hitpos[2]
			write_short res_laserbeam
			write_byte 0 // Starting frame
			write_byte 0 // Framerate
			write_byte 2 // Lifetime
			write_byte 5 // Line width
			write_byte 50 // Noise amplitude
			write_byte 175 // R
			write_byte 15 // G
			write_byte 20 // B
			write_byte 255 // Brightness
			write_byte 20 // Scrolling speed
		}
		message_end
		
		message_begin MSG_BROADCAST, SVC_TEMPENTITY;
		{
			write_byte TE_BEAMENTPOINT
			write_short id
			write_coord hitpos[0]
			write_coord hitpos[1]
			write_coord hitpos[2]
			write_short res_laserbeam
			write_byte 0 // Starting frame
			write_byte 0 // Framerate
			write_byte 2 // Lifetime
			write_byte 5 // Line width
			write_byte 10 // Noise amplitude
			write_byte 175 // R
			write_byte 125 // G
			write_byte 70 // B
			write_byte 255 // Brightness
			write_byte 20 // Scrolling speed
		}
		message_end
		
		message_begin MSG_BROADCAST, SVC_TEMPENTITY;
		{
			write_byte TE_EXPLOSION
			write_coord hitpos[0]
			write_coord hitpos[1]
			write_coord hitpos[2]
			write_short res_laserbeam
			write_byte 10
			write_byte 20
			write_byte TE_EXPLFLAG_NONE
		}
		message_end
		
		if (equal(classname, PLAYER)) {
			user_slap ent, 9999, 0
		} else {
			new model_prefix[sizeof PREFIX_MDL_PLAYER]; entity_get_string ent, EV_SZ_model, model_prefix, charsmax(model_prefix)
			if (equali(PREFIX_MDL_PLAYER, model_prefix)) { // Spawn some gibs
				message_begin MSG_BROADCAST, SVC_TEMPENTITY;
				{
					write_byte TE_EXPLODEMODEL
					write_coord hitpos[0]
					write_coord hitpos[1]
					write_coord hitpos[2]
					write_coord 1000
					write_short res_hgibs
					write_short 25 // Amount
					write_byte 200 // Lifespan (tenths, 200 = 20s)
				}
				message_end
				new eyes[3]; get_user_origin id, eyes, 1
				message_begin MSG_BROADCAST, SVC_TEMPENTITY;
				{
					write_byte TE_BLOODSTREAM
					write_coord hitpos[0]
					write_coord hitpos[1]
					write_coord hitpos[2]
					write_coord hitpos[0] - eyes[0]
					write_coord hitpos[1] - eyes[1]
					write_coord 0
					write_byte 225 // Colour
					write_byte 200 // Speed
				}
				message_end
			}
			set_entity_flags ent, FL_KILLME, true
		}
	} else if (!equal(targetname, PLAYER)) { // 3+ arguments, kill radius
		new killed_n
		new i_origin[3]; get_user_origin id, i_origin
		new allbuffer[sizeof SEARCH_ALL]; 
		new Float:radius
		const Float:RADIUS_ALL = 9999.0
		if ((radius = read_argv_float(2))) { // e_kill cycler <num> [all]
			read_argv 3, allbuffer, charsmax(allbuffer)
		} else {  // e_kill cycler [all]
			read_argv 2, allbuffer, charsmax(allbuffer)
		}
		new bool:all = bool:equali(allbuffer, SEARCH_ALL)
		
		console_print id, "All: %d, radius: %f", all?1:0, radius
		if (radius) {
			new Float:f_origin[3]; entity_get_vector id, EV_VEC_origin, f_origin
			while ((ent = find_ent_in_sphere(ent, f_origin, radius))) {
				entity_get_string ent, EV_SZ_classname, classname, charsmax(classname)
				if (!equal(classname, targetname)) continue
				set_entity_flags ent, FL_KILLME, true
				killed_n++
				if (!all) break
			}
		} else {
			while ((ent = find_ent_by_class(ent, targetname))) {
				set_entity_flags ent, FL_KILLME, true
				killed_n++
				if (!all) break
			}
		}
		console_print 0, "Killed entities: %d", killed_n
		message_begin MSG_BROADCAST, SVC_TEMPENTITY;
		{
			write_byte TE_BEAMDISK
			write_coord i_origin[0]
			write_coord i_origin[1]
			write_coord i_origin[2]
			write_coord i_origin[0]
			write_coord i_origin[1]
			write_coord i_origin[2] + floatround(all ? RADIUS_ALL : floatclamp(radius, 0.0, RADIUS_ALL))
			write_short res_lightning
			write_byte 0 // Start frame
			write_byte 0 // Framerate
			write_byte 40 // Lifetime
			write_byte 10 // Width
			write_byte 0 // Noise
			write_byte random_num(100, 255) // R
			write_byte random_num(0, 255) // G
			write_byte random_num(20, 255) // B
			write_byte 210 // Brightness
			write_byte 0 // Speed
		}
		message_end
	}
	return PLUGIN_HANDLED
}
public cmd_create(id, level, cid) {
	// The first argument is the class name.
	// The second argument is optional and starts with a put type, either a dot (.) or bang (!).
	//  Dot means spawn at aimed position. This is also default if this argument is not provided.
	//  Bang means spawn at my position.
	//
	// In the same argument after the put type is a coordinate list.
	// Position coordinates: xyz, XYZ
	// Angle coordinates: psr, PSR (pitch yaw roll, Y was taken so S is used for "Side")
	// 
	// An uppercase coordinate means there is an offset argument.
	//
	// An angle coordinate means the player's angle will take over.
	// Lowercase position coordinates do nothing.
	// 
	// Keyvalue pairs with "origin" and "angles" can be used to specify absolute coordinates.
	//
	// Spawn a classic cycler on you:
	//   e_create cycler !
	// Example to spawn a cycler where you aim that looks at you:
	//   e_create cycler .ZS 35 180
	// Create a penguin prison around Sylanha:
	//   e_defaults model "models/player/penguin/penguin.mdl"; e_create cycler @syl !X 40 angles "0 180";e_create cycler @syl !X -40;e_create cycler @syl !Y -40 angles "0 90";e_create cycler @syl !Y 40 angles "0 -90"
	// Spawn a respawning quad+invuln backpack:
	//   e_default model models/backpack.mdl; e_create info_tfgoal .Z 20 wait 1 noise items/armoron_1.wav g_e 1 g_a 1 super_damage_finished 1e400 invincible_finished 1e400
	
	console_print id, "Entered e_create"
	new args_n = read_argc()
	if (args_n < 2) return
	new arg1[0x40], arg2[0x40]
	
	new arg_i = 1
	
	read_argv arg_i++, arg1, charsmax(arg1)
	new ent = create_entity(arg1)
	
	new Float:origin[3], Float:angles[3], bool:use_angles[3], iaimed[3]
	read_argv arg_i, arg2, charsmax(arg2)
	
	new c = arg2[0]
	new target = id
	if (c == '@') {
		new target_new = get_player(arg2[1])
		if (target_new) target = target_new
		else {
			console_print id, "No player found matching substring \"%s\"", arg2[1]
			return
		}
		read_argv ++arg_i, arg2, charsmax(arg2)
		c = arg2[0]
	}
	
	if (c == '!') {entity_get_vector target, EV_VEC_origin, origin;}
	else {get_user_origin target, iaimed, 3; VEC_TO_FVEC(iaimed, origin);}
	
	if (c == '.' || c == '!') {
		arg_i++
		entity_get_vector target, EV_VEC_angles, angles
		for (new i = 1; (c = arg2[i]); i++) {
			switch (c | 0x20) { // Match against lowercase c
			case 'x': {if (!(c & 0x20)) origin[0] += read_argv_float(arg_i++);}
			case 'y': {if (!(c & 0x20)) origin[1] += read_argv_float(arg_i++);}
			case 'z': {if (!(c & 0x20)) origin[2] += read_argv_float(arg_i++);}
			case 'p': {if (!(c & 0x20)) angles[0] += read_argv_float(arg_i++); use_angles[0] = true;}
			case 's': {if (!(c & 0x20)) angles[1] += read_argv_float(arg_i++); use_angles[1] = true;}
			case 'r': {if (!(c & 0x20)) angles[2] += read_argv_float(arg_i++); use_angles[2] = true;}
			default: continue;
			}
		}
		if (!use_angles[0]) angles[0] = 0.0
		if (!use_angles[1]) angles[1] = 0.0
		if (!use_angles[2]) angles[2] = 0.0
	}
	
	entity_set_vector ent, EV_VEC_angles, angles
	entity_set_origin ent, origin
	new TrieIter:defaults_iter = TrieIterCreate(defaults)
	while (TrieIterGetString(defaults_iter, arg2, charsmax(arg2))) {
		TrieIterGetKey defaults_iter, arg1, charsmax(arg1)
		console_print id, "Used default kv: \"%s\", \"%s\"", arg1, arg2
		DispatchKeyValue ent, arg1, arg2
		TrieIterNext defaults_iter
	}
	TrieIterDestroy defaults_iter
	
	for (; arg_i < args_n; ) {
		read_argv arg_i++, arg1, charsmax(arg1)
		read_argv arg_i++, arg2, charsmax(arg2)
		DispatchKeyValue ent, arg1, arg2
	}
	DispatchSpawn ent
}

static stock get_player(const search_name[]) {
	static player_name[0x20]
	for (new id = 1; id <= get_maxplayers(); id++) {
		if (!is_user_connected(id)) continue
		get_user_name id, player_name, charsmax(player_name)
		if (containi(player_name, search_name) != -1) return id
	}
	return 0
}

public cmd_give(id, level, cid) {
	new args_n = read_argc()
	if (args_n < 3) return
	new search_name[0x20]; read_argv 1, search_name, charsmax(search_name)
	new recipient = get_player(search_name)
	if (!recipient) return
	
	new classname[0x20]; read_argv 2, classname, charsmax(classname)
	
	for (new type_i; type_i < sizeof AMMO_TYPES; type_i++) {
		if (equali(AMMO_TYPES[type_i], classname)) {
			new amount = read_argv_int(3)
			if (!amount) amount = 9999
			tfc_setbammo recipient, type_i, amount
			console_print id, "Gave %s some %s, bro", search_name, AMMO_TYPES[type_i]
			return
		}
	}
	give_item recipient, classname
	get_user_name recipient, search_name, charsmax(search_name)
	console_print id, "Gave %s a %s, bro", search_name, classname
}
