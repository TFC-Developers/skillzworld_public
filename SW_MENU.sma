#include <amxmodx>
#include <amxmisc>
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
	new menu = menu_create("Got some shit here", "menu_handler")
	menu_additem menu, "\wToggle third person mode", "menu_thirdperson"
	menu_display id, menu, 0
}

public menu_handler(id, menu, item) {
	switch (item) {
	case 0: {
		thirdperson id
	}}
	menu_destroy menu
	return PLUGIN_HANDLED
}
