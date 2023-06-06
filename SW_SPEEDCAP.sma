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

#define USE_2003 true

public plugin_init() {
	register_plugin PLUGIN, VERSION, AUTHOR
	register_concmd "sv_speedcap", "cmd_speedcap", ADMIN_ADMIN, "Sets the damned blasted speedcap"
}

new g_Speedcap_OriginalLong
new bool:g_SpeedcapOn = true


stock const SPEEDCAP_PATTERN_2003[] = "Speedcap-1FD7C79A5D253224CBFA4B6A92AFC533"
stock const SPEEDCAP_PATTERN_2020[] = "Speedcap-B442FF5F79DBE23FB246E679E62E7994"

stock enable_speedcap() {
	if (g_SpeedcapOn) return
	
	if (is_linux_server()) {
#if USE_2003
		OrpheuMemorySet SPEEDCAP_PATTERN_2003, 1, g_Speedcap_OriginalLong
#else
		OrpheuMemorySet SPEEDCAP_PATTERN_2020, 1, g_Speedcap_OriginalLong
#endif
	} else {
		OrpheuMemorySet SPEEDCAP_PATTERN_2020, 1, g_Speedcap_OriginalLong
	}

	g_SpeedcapOn = true
}
stock disable_speedcap() {
	if (!g_SpeedcapOn) return
#if USE_2003
	g_Speedcap_OriginalLong = OrpheuMemoryGet(SPEEDCAP_PATTERN_2003)
#else
	g_Speedcap_OriginalLong = OrpheuMemoryGet(SPEEDCAP_PATTERN_2020)
#endif
	
	// Opcodes: https://faydoc.tripod.com/cpu/jnc.htm
	// Linux: Parity of preceding instruction https://www.felixcloutier.com/x86/fcomi:fcomip:fucomi:fucomip

	if (is_linux_server()) {
#if USE_2003
		OrpheuMemorySet SPEEDCAP_PATTERN_2003, 1, (g_Speedcap_OriginalLong & ~0xFF) | 0xEB
#else
		OrpheuMemorySet SPEEDCAP_PATTERN_2020, 1, (g_Speedcap_OriginalLong & ~0xFFFF) | 0x8B0F
#endif
	} else {
		OrpheuMemorySet SPEEDCAP_PATTERN_2020, 1, (g_Speedcap_OriginalLong & ~0xFF) | 0xEB
	}
	
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

public plugin_end() {
	enable_speedcap
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang2057\\ f0\\ fs16 \n\\ par }
*/
