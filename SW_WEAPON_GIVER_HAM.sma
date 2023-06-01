#include "include/global"
#include <engine>
#include <fun>
#include <tfcx>
#include <hamsandwich>
#include <orpheu>
#include <orpheu_stocks>

public plugin_init() {
	RegisterPlugin
	RegisterHamPlayer Ham_Spawn, "player_spawn", .Post = true
}

public player_spawn(id) {
	if (!is_user_alive(id)) return
	tfc_setbammo id, TFC_AMMO_BULLETS, 137
	tfc_setbammo id, TFC_AMMO_SHELLS, 137
	give_item id, "tf_weapon_ac"
	give_item id, "tf_weapon_medikit"
	give_item id, "tf_weapon_ng"
}

public weapons_think() {	
	for (new id = 1; id <= get_maxplayers(); id++) {
		if (!(is_user_alive(id) && 1 <= pev(id, pev_team) <= 4)) continue
		tfc_setbammo id, TFC_AMMO_BULLETS, 137
		tfc_setbammo id, TFC_AMMO_SHELLS, 137
	}
	set_task 1.0, "weapons_think"
}
public OnConfigsExecuted() {
	weapons_think
}
