#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <tfcx>
#include <fakemeta>
#include <hamsandwich>
#include <orpheu>
#include <orpheu_stocks>

#define PLUGIN "SkillzWorld Weapons"
#define VERSION "1.0"
#define AUTHOR "SkillzWorld"

// Dependency for compile: Orpheu, Orpheu GameRules Object
//   Orpheu: https://forums.alliedmods.net/showthread.php?t=116393
//   GameRules: https://forums.alliedmods.net/showthread.php?t=123628

//// Set up GameRules
new g_pGameRules
public plugin_precache() {    
	OrpheuRegisterHook OrpheuGetFunction("InstallGameRules_tfc"), "install_game_rules", OrpheuHookPost
}
public install_game_rules() {
	g_pGameRules = OrpheuGetReturn()
}
////


public plugin_init() {
	register_plugin PLUGIN, VERSION, AUTHOR
	OrpheuRegisterHookFromObject g_pGameRules, "GetPlayerSpawnSpot", "CGameRules", "player_spawn_spot"
}

public player_spawn_spot(gameRules, id) {
	if (!is_user_alive(id)) return
	tfc_setbammo id, TFC_AMMO_BULLETS, 137
	tfc_setbammo id, TFC_AMMO_SHELLS, 137
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
	set_task 1.0, "weapons_think"
}
public OnConfigsExecuted() {
	weapons_think
}
