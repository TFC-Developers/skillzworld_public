#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>

#define PLUGIN "Create Cycler"
#define VERSION "1.0"
#define AUTHOR "SkillzWorld"

public plugin_init() {
	register_plugin PLUGIN, VERSION, AUTHOR
	register_concmd "e_cycler", "spawn_cycler", ADMIN_ADMIN, "Spawns a funny cycler. Takes an optional argument as model, crashes if not precached."
}

new const DEFAULT_MODEL[] = "models/player/civilian/civilian.mdl"
public spawn_cycler(pid, level, cid) {
	new ent = create_entity("cycler")
	new args_n = read_argc()
	if (args_n > 1) {
		new chosen_model[0x40]; read_argv 1, chosen_model, charsmax(chosen_model)
		entity_set_model ent, chosen_model
	} else {
		entity_set_model ent, DEFAULT_MODEL
	}
	new Float: origin[3]; entity_get_vector pid, EV_VEC_origin, origin
	entity_set_origin ent, origin
	new Float: angles[3]; entity_get_vector pid, EV_VEC_angles, angles
	angles[0] = angles[2] = 0.0
	entity_set_vector ent, EV_VEC_angles, angles
	set_pev ent, pev_framerate, 1.0
	DispatchSpawn ent
	return PLUGIN_HANDLED
}
