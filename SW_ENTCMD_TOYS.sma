#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fun>
#include <tfcx>
#include <fakemeta>

#define PLUGIN "Entity Toys"
#define VERSION "1.0"
#define AUTHOR "SkillzWorld"

stock const MDL_CIVILIAN[] = "models/player/civilian/civilian.mdl"
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
}

#define VEC_TO_FVEC(%1,%2) %2[0] = float(%1[0]); %2[1] = float(%1[1]); %2[2] = float(%1[2])
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
	// Create a civilian prison:
	//   e_create cycler !X 40 angles "0 180";e_create cycler !X -40;e_create cycler !Y -40 angles "0 90";e_create cycler !Y 40 angles "0 -90"
	
	new args_n = read_argc()
	if (args_n < 2) return PLUGIN_HANDLED
	new arg1[0x40], arg2[0x40]
	
	read_argv 1, arg1, charsmax(arg1)
	new ent = create_entity(arg1)
	
	new Float:origin[3], Float:angles[3], bool:use_angles[3], iaimed[3]
	read_argv 2, arg2, charsmax(arg2)
	
	new arg_i = 2, c = arg2[0]
	if (c == '!') {entity_get_vector id, EV_VEC_origin, origin;}
	else {get_user_origin id, iaimed, 3; VEC_TO_FVEC(iaimed, origin);}
	
	if (c == '.' || c == '!') {
		entity_get_vector id, EV_VEC_angles, angles
		arg_i = 3
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
	for (; arg_i < args_n; arg_i += 2) {
		read_argv arg_i    , arg1, charsmax(arg1)
		read_argv arg_i + 1, arg2, charsmax(arg2)
		DispatchKeyValue ent, arg1, arg2
	}
	DispatchSpawn ent
	
	return PLUGIN_HANDLED
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