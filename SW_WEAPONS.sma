#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <tfcx>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN "SkillzWorld Weapons"
#define VERSION "1.0"
#define AUTHOR "SkillzWorld"

public plugin_init() {
	register_plugin PLUGIN, VERSION, AUTHOR
	RegisterHam(Ham_Spawn, "player", "spawn_dingus", .Post = 1)
}
public spawn_dingus(id) {
	give_item id, "tf_weapon_ac"
	give_item id, "tf_weapon_medikit"
	give_item id, "tf_weapon_ng"
}
public weapons_think() {
	for (new id = 1; id <= get_maxplayers(); id++) {
		if (is_user_alive(id) && 1 <= pev(id, pev_team) <= 4) {
			tfc_setbammo id, TFC_AMMO_BULLETS, 137
			tfc_setbammo id, TFC_AMMO_SHELLS, 137
		}
	}
	set_task_ex 1.0, "weapons_think"
}
public OnConfigsExecuted() {
	weapons_think
}