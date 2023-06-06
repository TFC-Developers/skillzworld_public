#include "include/global"
#include "include/api_thirdperson"

public plugin_init() {
	RegisterPlugin
	register_clcmd "say menu", "cmd_menu"
	register_clcmd "say /menu", "cmd_menu"
}
public plugin_natives() {	
	register_library "sw_menu"
	register_native "open_menu", "Native_OpenMenu"
}

public cmd_menu(id) {
	open_menu id
	return PLUGIN_HANDLED
}
public Native_OpenMenu(iPlugin, iParams) {
	open_menu(get_param(1))
}

public open_menu(id) {
	console_print id, "Showing menu"
	new menu = menu_create("Menu", "menu_handler")
	menu_additem menu, "Toggle third person mode",			"menu_third_person"
	menu_additem menu, "Nominate map",				"menu_nominate"
	menu_additem menu, "Choose custom model",			"menu_choose_model"
	menu_additem menu, "Model showcase",				"menu_model_showcase"
	menu_additem menu, "Toggle visibility of custom models",	"menu_toggle_custom_models"
	menu_additem menu, "Enlighten me!",				"menu_enlighten"
	menu_display id, menu, 0
}

public menu_handler(id, menu, item) {
	switch (item) {
	case 0: thirdperson id
	case 5: set_pev id, pev_effects, pev(id, pev_effects) ^ EF_BRIGHTLIGHT
	}
	menu_destroy menu
}
