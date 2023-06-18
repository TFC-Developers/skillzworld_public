#include "include/global"
#include <engine>
#include <fun>
#include <tfcx>
#include <hamsandwich>
#include "include/api_thirdperson"
#include "include/api_skills_actions"
#include "include/api_menu"

// Creates some action shortcuts for saycommands

public plugin_init() {
	RegisterPlugin
	RegisterHam Ham_Weapon_PrimaryAttack, "tf_weapon_medikit", "action_medikit"
	/*
	RegisterHam Ham_Weapon_PrimaryAttack, "tf_weapon_axe", "action_melee"
	RegisterHam Ham_Weapon_PrimaryAttack, "tf_weapon_knife", "action_melee"
	RegisterHam Ham_Weapon_PrimaryAttack, "tf_weapon_spanner", "action_melee"
	*/
}

const Float:ACTION_AIM_THRESHOLD = 88.0
public action_medikit(wid) {
	new id = entity_get_edict(wid, EV_ENT_owner);
	new Float:angles[3]; pev id, pev_v_angle, angles
	if (angles[0] > ACTION_AIM_THRESHOLD) {
		reset_run id
	} else if (angles[0] < -ACTION_AIM_THRESHOLD) {
		open_menu id
	}
}
public action_melee(wid) {
	new id = entity_get_edict(wid, EV_ENT_owner);
	new Float:angles[3]; pev id, pev_v_angle, angles
	if (angles[0] > ACTION_AIM_THRESHOLD) {
		load_checkpoint id
	} else if (angles[0] < -ACTION_AIM_THRESHOLD) {
		set_custom_checkpoint id
	}
}
