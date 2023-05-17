#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>

#define PLUGIN "Create Entity"
#define VERSION "1.0"
#define AUTHOR "SkillzWorld"

public plugin_init() {
	register_plugin PLUGIN, VERSION, AUTHOR
	register_concmd "e_create", "spawn_entity", ADMIN_ADMIN, "Spawns an entity. First argument is the class name, further argument pairs make keyvalues."
}

new const DEFAULT_MODEL[] = "models/player/civilian/civilian.mdl"
public spawn_entity(pid, level, cid) {
	// Example: e_create cycler model models/player/civilian/civilian.mdl framerate 1
	new args_n = read_argc()
	if (args_n < 2) return PLUGIN_HANDLED
	new arg1[0x40], arg2[0x40]
	read_argv 1, arg1, charsmax(arg1)
	new ent = create_entity(arg1)
	entity_set_model ent, DEFAULT_MODEL
	new Float:origin[3]; entity_get_vector pid, EV_VEC_origin, origin
	entity_set_origin ent, origin
	for (new arg_i = 2; arg_i < args_n; arg_i += 2) {
		read_argv arg_i    , arg1, charsmax(arg1)
		read_argv arg_i + 1, arg2, charsmax(arg2)
		DispatchKeyValue ent, arg1, arg2
	}
	DispatchSpawn ent
	return PLUGIN_HANDLED
}
