#include <amxmodx>
#include <amxmisc>
#include <orpheu>

#define PLUGIN "Test plugin"
#define VERSION "1.0"
#define AUTHOR "SkillzWorld"

new OrpheuHook:hook_PM_Move

public plugin_init() {
	register_plugin PLUGIN, VERSION, AUTHOR
	hook_PM_Move = OrpheuRegisterHook(OrpheuGetFunction("PM_Move"), "hooker", OrpheuHookPost)
}

public hooker(ppmove, server) {
	console_print 0, "Snickersby %d %d", ppmove, server
	OrpheuUnregisterHook hook_PM_Move
}
