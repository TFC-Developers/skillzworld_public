#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include "include/api_thirdperson"

#define PLUGIN "SkillzWorld Menu"
#define VERSION "1.0"
#define AUTHOR "SkillzWorld"

public plugin_init() {
	register_plugin PLUGIN, VERSION, AUTHOR
	register_clcmd "say menu", "open_menu"
	register_clcmd "say /menu", "open_menu"
}

public open_menu(id) {
	new menu = menu_create("Menu", "menu_handler")
	menu_additem menu, "Toggle third person mode",			"menu_third_person"
	menu_additem menu, "Nominate map",				"menu_nominate"
	menu_additem menu, "Choose custom model",			"menu_choose_model"
	menu_additem menu, "Model showcase",				"menu_model_showcase"
	menu_additem menu, "Toggle visibility of custom models",	"menu_toggle_custom_models"
	menu_additem menu, "Enlighten me!",				"menu_enlighten"
	menu_display id, menu, 0
	return PLUGIN_HANDLED
}

public menu_handler(id, menu, item) {
	switch (item) {
	case 0: thirdperson id
	case 5: set_pev id, pev_effects, pev(id, pev_effects) ^ EF_BRIGHTLIGHT
	}
	menu_destroy menu
	return PLUGIN_HANDLED
}
