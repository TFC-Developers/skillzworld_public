#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fun>
#include <tfcx>
#include <fakemeta>
#include <message_const>

#define PLUGIN "Entity Toys"
#define VERSION "1.0"
#define AUTHOR "SkillzWorld"

#define VEC_TO_FVEC(%1,%2) %2[0] = float(%1[0]); %2[1] = float(%1[1]); %2[2] = float(%1[2])
#define FVEC_TO_VEC(%1,%2,%3) %2[0] = floatround(%1[0],%3); %2[1] = floatround(%1[1],%3); %2[2] = floatround(%1[2],%3)

stock const PREFIX_MDL_PLAYER[] = "models/player/"
stock const MDL_CIVILIAN[] = "models/player/civilian/civilian.mdl"
stock const MDL_HGIBS[] = "models/hgibs.mdl"
stock const SPR_LIGHTNING[] = "sprites/lgtning.spr"
stock const SPR_LASERBEAM[] = "sprites/laserbeam.spr"
stock const SEARCH_ALL[] = "all"
stock const PLAYER[] = "player"
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
	register_plugin PLUGIN, VERSION, AUTHOR
	register_concmd "e_create", "cmd_create", ADMIN_ADMIN, "Spawns an entity. First argument is the class name, second argument can be positioning information, further argument pairs make keyvalues."
	register_concmd "e_give", "cmd_give", ADMIN_ADMIN, "Gives an item to a player."
	register_concmd "new_e_kill", "cmd_kill", ADMIN_ADMIN, "Deletes an entity."
	register_concmd "e_getmodel", "cmd_getmodel", ADMIN_ADMIN, "Shows the entity's model in the console."
}
public plugin_precache() {
	res_lightning = precache_model(SPR_LIGHTNING)
	res_laserbeam = precache_model(SPR_LASERBEAM)
	res_civilian = precache_model(MDL_CIVILIAN)
	res_hgibs = precache_model(MDL_HGIBS)
}
public cmd_getmodel(id, level, cid) {
	new ent; get_user_aiming id, ent
	new model[0x40]; entity_get_string ent, EV_SZ_model, model, charsmax(model)
	console_print 0, "Has model: %s", model
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
		console_print id, "Aiming to kill"
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
		console_print id, "Radius to kill"
		new i_origin[3]; get_user_origin id, i_origin
		new allbuffer[sizeof SEARCH_ALL]; 
		new Float:radius
		const Float:RADIUS_ALL = 9999.0
		if ((radius = read_argv_float(2))) { // e_kill cycler <num> [all]
			read_argv 3, allbuffer, charsmax(allbuffer)
			console_print id, "Radius found. ^"%s^" %d", allbuffer, radius
		} else {  // e_kill cycler [all]
			read_argv 2, allbuffer, charsmax(allbuffer)
			console_print id, "No radius found. ^"%s^" %d", allbuffer, radius
		}
		new bool:all = bool:equali(allbuffer, SEARCH_ALL)
		
		console_print id, "All: %d, radius: %f", all?1:0, radius
		if (all) {
			while ((ent = find_ent_by_class(ent, targetname))) {
				set_entity_flags ent, FL_KILLME, true
			}
		} else { // Use radius instead
			new Float:f_origin[3]; entity_get_vector id, EV_VEC_origin, f_origin
			while ((ent = find_ent_in_sphere(ent, f_origin, radius))) {
				entity_get_string ent, EV_SZ_classname, classname, charsmax(classname)
				if (equal(classname, targetname)) set_entity_flags ent, FL_KILLME, true
			}
		}
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
	// Create a civilian prison around Dizlin:
	//   e_create cycler @diz !X 40 angles "0 180";e_create cycler @diz !X -40;e_create cycler @diz !Y -40 angles "0 90";e_create cycler @diz !Y 40 angles "0 -90"
	
	new args_n = read_argc()
	if (args_n < 2) return
	new arg1[0x40], arg2[0x40]
	
	new arg_i = 1
	
	read_argv arg_i++, arg1, charsmax(arg1)
	new ent = create_entity(arg1)
	
	new Float:origin[3], Float:angles[3], bool:use_angles[3], iaimed[3]
	read_argv arg_i++, arg2, charsmax(arg2)
	
	new c = arg2[0]
	if (c == '@') {
		new id_new = get_player(arg2[1])
		if (id_new) id = id_new
		read_argv arg_i++, arg2, charsmax(arg2)
		c = arg2[0]
	}
	
	if (c == '!') {entity_get_vector id, EV_VEC_origin, origin;}
	else {get_user_origin id, iaimed, 3; VEC_TO_FVEC(iaimed, origin);}
	
	if (c == '.' || c == '!') {
		entity_get_vector id, EV_VEC_angles, angles
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
	entity_set_model ent, MDL_CIVILIAN
	for (; arg_i < args_n; ) {
		read_argv arg_i++, arg1, charsmax(arg1)
		read_argv arg_i++, arg2, charsmax(arg2)
		DispatchKeyValue ent, arg1, arg2
	}
	DispatchSpawn ent
}

static stock get_player(const search_name[]) {
	new player_name[0x20]
	for (new id = 1; id <= get_maxplayers(); id++) {
		get_user_name id, player_name, charsmax(player_name)
		if (containi(search_name, player_name)) return id
	}
	return 0
}

public cmd_give(id, level, cid) {
	new _name0[0x20], _name1[0x20], _name2[0x20]
	get_user_name 0, _name0, charsmax(_name0)
	get_user_name 1, _name1, charsmax(_name1)
	get_user_name 2, _name2, charsmax(_name2)
	new args_n = read_argc()
	if (args_n < 3) return
	new search_name[0x20]; read_argv 1, search_name, charsmax(search_name)
	new recipient = get_player(search_name)
	
	get_user_name recipient, search_name, charsmax(search_name)
	if (!recipient) return
	new classname[0x20]; read_argv 2, classname, charsmax(classname)
	for (new type_i; type_i < sizeof AMMO_TYPES; type_i++) {
		if (equali(AMMO_TYPES[type_i], classname)) {
			new amount = read_argv_int(4)
			if (!amount) amount = 9999
			tfc_setbammo recipient, type_i, amount
			return
		}
	}
	give_item recipient, classname
}
