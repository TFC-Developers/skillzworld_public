#include <amxmodx>

#define PLUGIN "SkillzWorld Concblock"
#define VERSION "1.0"
#define AUTHOR "SkillzWorld"

public plugin_init() {
    register_plugin PLUGIN, VERSION, AUTHOR
    register_message get_user_msgid("Concuss"), "message_concuss"
}

public message_concuss() return PLUGIN_HANDLED
