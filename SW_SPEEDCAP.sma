#include <amxmodx>
#include <amxmisc>
#include <orpheu>
#include <orpheu_memory>

#define PLUGIN "Skillzworld Speedcap"
#define VERSION "1.0"
#define AUTHOR "Skillzworld"

// This plugin hacks the speed cap out of the bytecode of PM_Jump.
// Requires the config file configs/orpheu/memory/Speedcap
// As an alternative to this, others have reimplemented PM_Jump entirely:
//   https://forums.alliedmods.net/showthread.php?p=610329?p=610329

#define USE_2003 false

public plugin_init() {
	console_print 0, "Initing speedcap"
	register_plugin PLUGIN, VERSION, AUTHOR
	register_concmd "sv_speedcap", "cmd_speedcap", ADMIN_ADMIN, "Sets the damned blasted speedcap"
}

new g_Speedcap_OriginalLong
new bool:g_SpeedcapOn = true


#if USE_2003
stock const SPEEDCAP_PATTERN[] = "Speedcap-1FD7C79A5D253224CBFA4B6A92AFC533"
#else
stock const SPEEDCAP_PATTERN[] = "Speedcap-B442FF5F79DBE23FB246E679E62E7994"
#endif

stock enable_speedcap() {
	if (g_SpeedcapOn) return
	OrpheuMemorySet SPEEDCAP_PATTERN, 1, g_Speedcap_OriginalLong
	g_SpeedcapOn = true
}
stock disable_speedcap() {
	if (!g_SpeedcapOn) return
	g_Speedcap_OriginalLong = OrpheuMemoryGet(SPEEDCAP_PATTERN)
	console_print 0, "Speedcap: Saved original long: %d", g_Speedcap_OriginalLong
	
	// Opcodes: https://faydoc.tripod.com/cpu/jnc.htm
	// Linux: Parity of preceding instruction https://www.felixcloutier.com/x86/fcomi:fcomip:fucomi:fucomip

#if USE_2003
	// Linux only
	OrpheuMemorySet SPEEDCAP_PATTERN, 1, (g_Speedcap_OriginalLong & ~0xFF) | 0xEB
#else
	if (g_Speedcap_OriginalLong & 0xFF == 0x7B) { // Windows
		OrpheuMemorySet SPEEDCAP_PATTERN, 1, (g_Speedcap_OriginalLong & ~0xFF) | 0xEB
	} else { // Linux
		OrpheuMemorySet SPEEDCAP_PATTERN, 1, (g_Speedcap_OriginalLong & ~0xFFFF) | 0x8B0F
	}
#endif
	
	g_SpeedcapOn = false
}
public cmd_speedcap(id, level, cid) {
	if (read_argc() == 1) {
		console_print id, "^"sv_speedcap^" is ^"%d^"", _:g_SpeedcapOn
		return
	}
	if (read_argv_int(1)) enable_speedcap
	else disable_speedcap
}



public plugin_precache() {
	console_print 0, "Precaching speedcap"
	disable_speedcap
}
public plugin_end() {
	console_print 0, "Speedcap: Restoring original long: %d", g_Speedcap_OriginalLong
	enable_speedcap
}
