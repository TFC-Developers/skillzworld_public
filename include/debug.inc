// code by watch/fm see https://github.com/ben-watch/feckinmad, modified by MrKoala in order to migrate skillzworld 
// from the c++ metamod plugin to amxmodx

#if defined _debug_included
  #endinput
#endif
#define _debug_included

stock const g_sTextDebug[] = "DEBUG: [%s] %s"

stock DebugPrintLevel(iLevelReq, sFormat[], any:...)
{
	static iDebugStatus

	// Check if debugging has been disabled until mapchange
	if (iDebugStatus == -1)
		return 0 
	
	static pCvarDebugLevel, pCvarDebugDest, pCvarDebugFilter

	// Check if the debug cvars have been registered and get pointers to them
	if (iDebugStatus == 0)
	{
		pCvarDebugLevel = register_cvar("sw_debug_level", "0") // amxx will check if its already registered and still return its pointers
		pCvarDebugFilter = register_cvar("sw_debug_filter", "")
		pCvarDebugDest = register_cvar("sw_debug_dest", "0")
		iDebugStatus = 1
	}
	
	static iDebugLevel; iDebugLevel = get_pcvar_num(pCvarDebugLevel)

	// If the debug cvar is set to < 0, totally disable debug logging until mapchange
	// This allows me to forgo the ability to enable logging midmap in order to make it more efficient
	if (iDebugLevel < 0)
	{
		iDebugStatus = -1
		return 0
	}

	// Allow stages of debugging similar to "meta_debug" or "developer"
	if (iDebugLevel < iLevelReq)
		return 0

	// Get the name of the plugin
	static sFileName[32]
	if (!sFileName[0])
		get_plugin(-1, sFileName, charsmax(sFileName))

	// Check if we want to filter out all debug not belonging to a specific plugin
	static sPluginFilter[32]
	get_pcvar_string(pCvarDebugFilter, sPluginFilter, charsmax(sPluginFilter))	

	if (sPluginFilter[0] != '\0' && !equali(sPluginFilter, sFileName))
		return 0

	static sMessage[255]; sMessage[0] = '\0'
	vformat(sMessage, charsmax(sMessage), sFormat, 3)

	switch(get_pcvar_num(pCvarDebugDest))
	{
		case 1: 
		{
			static sLogFile[32]; get_time("debug_%Y%m%d.log", sLogFile, charsmax(sLogFile))
			log_to_file(sLogFile, g_sTextDebug, sFileName, sMessage)
		}
		case 2: log_message(g_sTextDebug, sFileName, sMessage)
		case 3: client_print(0, print_chat, g_sTextDebug, sFileName, sMessage)
		case 4: client_print(0, print_console, g_sTextDebug, sFileName, sMessage)
		default: server_print(g_sTextDebug, sFileName, sMessage)
	}

	return 1
}

