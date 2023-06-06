/*	========================================================
*	- NAME:
*	  + AltmodX
*
*	- DESCRIPTION:
*	  + This plugin is a remake of the metamod plugin 'Altmod'.
*	  + I made this because Altmod didn't have support for
*	  + linux servers. AltmodX is a lot easier to use and
*	  + has a few more features.
*
*	- CREDITS:
*	  + Everyone that helped test the plugin.
*	  + Basic-Master for the keyvalue stock.
*	  + Looking at how AssKicR did the class change.
*	  + jRaven for the post about creating quad powerups
*
*	--------------
*	User Commands:
*	--------------
*	- say '/altmodx' to see all of the commands and more.
*
*	---------
*	Versions:
*	---------
*	1.0 - First version made and works (06-10-2007).
*	1.1 - Converting the plugin to FakeMeta (08-27-2007).
*	2.0 - Added instant respawn and optimized code (08-24-2009).
*	2.1 - Optimized the ShowCredits function a bit (10-29-2010).
* 
*/

#include <amxmodx>
#include <fakemeta>
#include <tfcx>

#define PLUGIN "AltmodX"
#define VERSION "2.1"
#define AUTHOR "hlstriker"

enum
{
	CLASS_SCOUT = 1,
	CLASS_SNIPER,
	CLASS_SOLDIER,
	CLASS_DEMOMAN,
	CLASS_MEDIC,
	CLASS_HWGUY,
	CLASS_PYRO,
	CLASS_SPY,
	CLASS_ENGINEER,
	CLASS_RANDOM,
	CLASS_CIVILIAN
}

#define MAX_PLAYERS 32
#define CLASS_SWITCH_DELAY 1.0
new Float:g_flClassDelay[MAX_PLAYERS+1];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_cvar("altmodx_version", VERSION, FCVAR_SERVER|FCVAR_SPONLY);
	register_clcmd("say", "hook_say");
	register_clcmd("say /altmodx", "ShowCredits");
}

public plugin_precache()
{
	precache_sound("items/protect.wav");
	precache_sound("items/protect2.wav");
	precache_sound("items/protect3.wav");
	precache_sound("FVox/HEV_logon.wav");
	precache_sound("FVox/hev_shutdown.wav");
	precache_sound("items/inv1.wav");
	precache_sound("items/inv2.wav");
	precache_sound("items/inv3.wav");
	precache_sound("items/damage.wav");
	precache_sound("items/damage2.wav");
	precache_sound("items/damage3.wav");
}

public hook_say(iClient)
{
	if(!is_user_alive(iClient))
		return PLUGIN_CONTINUE;
	
	static szCommand[20];
	read_args(szCommand, sizeof(szCommand)-1);
	remove_quotes(szCommand);
	
	if(szCommand[0] != '/')
		return PLUGIN_CONTINUE;
	
	static szArg2[12], Float:flHalfLifeTime;
	strtok(szCommand, szCommand, sizeof(szCommand)-1, szArg2, sizeof(szArg2)-1, ' ');
	trim(szArg2);
	
	global_get(glb_time, flHalfLifeTime);
	
	if(equali(szCommand[1], "class"))
	{
		if(g_flClassDelay[iClient] > flHalfLifeTime)
		{
			client_print(iClient, print_chat, "[AltModX] You must wait %.2f more seconds to switch your class again.", g_flClassDelay[iClient]-flHalfLifeTime);
			return FMRES_HANDLED;
		}
		
		if(equali(szArg2, "scout")) set_pev(iClient, pev_playerclass, CLASS_SCOUT);
		else if(equali(szArg2, "sniper")) set_pev(iClient, pev_playerclass, CLASS_SNIPER);
		else if(equali(szArg2, "soldier")) set_pev(iClient, pev_playerclass, CLASS_SOLDIER);
		else if(equali(szArg2, "demoman")) set_pev(iClient, pev_playerclass, CLASS_DEMOMAN);
		else if(equali(szArg2, "medic")) set_pev(iClient, pev_playerclass, CLASS_MEDIC);
		else if(equali(szArg2, "hwguy")) set_pev(iClient, pev_playerclass, CLASS_HWGUY);
		else if(equali(szArg2, "pyro")) set_pev(iClient, pev_playerclass, CLASS_PYRO);
		else if(equali(szArg2, "spy")) set_pev(iClient, pev_playerclass, CLASS_SPY);
		else if(equali(szArg2, "engineer")) set_pev(iClient, pev_playerclass, CLASS_ENGINEER);
		else if(equali(szArg2, "random")) set_pev(iClient, pev_playerclass, CLASS_RANDOM);
		else if(equali(szArg2, "civilian")) set_pev(iClient, pev_playerclass, CLASS_CIVILIAN);
		else if(str_to_num(szArg2) >= CLASS_SCOUT && str_to_num(szArg2) <= CLASS_CIVILIAN) set_pev(iClient, pev_playerclass, str_to_num(szArg2));
		else
		{
			client_print(iClient, print_chat, "[AltModX] To change your class type, /class <classname> -OR- /class <class number>");
			return PLUGIN_CONTINUE;
		}
		
		fm_strip_user_weapons(iClient);
		dllfunc(DLLFunc_Spawn, iClient);
		g_flClassDelay[iClient] = flHalfLifeTime + CLASS_SWITCH_DELAY;
		
		return FMRES_HANDLED;
	}
	else if(equali(szCommand[1], "give"))
	{
		if(equali(szArg2, "all"))
		{
			PowerUp(iClient, 0, "99999");
			tfc_setbammo(iClient, TFC_AMMO_NADE1, 4);
			tfc_setbammo(iClient, TFC_AMMO_NADE2, 4);
			tfc_setbammo(iClient, TFC_AMMO_SHELLS, 225);
			tfc_setbammo(iClient, TFC_AMMO_BULLETS, 225);
			tfc_setbammo(iClient, TFC_AMMO_CELLS, 225);
			tfc_setbammo(iClient, TFC_AMMO_ROCKETS, 225);
		}
		else if(equali(szArg2, "god"))
			PowerUp(iClient, 1, "99999");
		else if(equali(szArg2, "quad"))
			PowerUp(iClient, 2, "99999");
		else if(equali(szArg2, "nades"))
		{
			tfc_setbammo(iClient, TFC_AMMO_NADE1, 4);
			tfc_setbammo(iClient, TFC_AMMO_NADE2, 4);
		}
		else if(equali(szArg2, "ammo"))
		{
			tfc_setbammo(iClient, TFC_AMMO_SHELLS, 225);
			tfc_setbammo(iClient, TFC_AMMO_BULLETS, 225);
			tfc_setbammo(iClient, TFC_AMMO_CELLS, 225);
			tfc_setbammo(iClient, TFC_AMMO_ROCKETS, 225);
		}
		else
		{
			client_print(iClient, print_chat, "[AltModX] To give yourself powerup(s) type, /give <quad, god, nades, ammo, or all>");
			return PLUGIN_CONTINUE;
		}
		
		return FMRES_HANDLED;
	}
	else if(equali(szCommand[1], "remove"))
	{
		if(equali(szArg2, "all"))
			PowerUp(iClient, 0, "1");
		else if(equali(szArg2, "god"))
			PowerUp(iClient, 1, "1");
		else if(equali(szArg2, "quad"))
			PowerUp(iClient, 2, "1");
		else
		{
			client_print(iClient, print_chat, "[AltModX] To remove a powerup(s) type, /remove <quad, god, or all>");
			return PLUGIN_CONTINUE;
		}
		
		return FMRES_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

PowerUp(iClient, iType, szTime[]="1")
{
	new iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_tfgoal"));
	dllfunc(DLLFunc_Spawn, iEnt);
	
	set_keyvalue(iEnt, "g_a", "1"); // Player touch activates
	set_keyvalue(iEnt, "g_e", "1"); // Affects AP only
	set_keyvalue(iEnt, "goal_state", "2"); // Active goal
	
	switch(iType)
	{
		case 0:
		{
			// Give all
			set_keyvalue(iEnt, "invincible_finished", szTime);
			set_keyvalue(iEnt, "super_damage_finished", szTime);
		}
		case 1: set_keyvalue(iEnt, "invincible_finished", szTime); // Give god
		case 2: set_keyvalue(iEnt, "super_damage_finished", szTime); // Give quad
	}
	
	dllfunc(DLLFunc_Use, iEnt, iClient);
	engfunc(EngFunc_RemoveEntity, iEnt);
}

public ShowCredits(iClient)
{
	new szMotd[2048], iLen;
	
	iLen += format(szMotd[iLen], sizeof(szMotd)-1-iLen, "\
		=======================================================^n\
		AltmodX was created by cLoWnEh (0:1:11980718)^n\
		This mod similar to Altmod by Alt+F4.^n\
		I created this mod mainly since Altmod didn't have a linux version.^n\
		=======================================================^n\
		AltmodX Usage (type following in chat):^n^n\
		To Change Class:^n\
		/class <classname> -OR- /class <class number>^n^n\
		To Give A Power Up:^n");
	
	iLen += format(szMotd[iLen], sizeof(szMotd)-1-iLen, "\
		/give <quad, god, nades, ammo, or all>^n^n\
		To Remove A Power Up:^n\
		/remove <quad, god, or all>^n\
		=======================================================^n\
		A special thanks goes to Janick (0:0:8752462) for helping me beta test!^n\
		=======================================================");
	
	show_motd(iClient, szMotd, "AltmodX - Made by cLoWnEh");
}

stock set_keyvalue(iEnt, szKey[], szValue[])
{
	static szClassName[32];
	
	pev(iEnt, pev_classname, szClassName, sizeof(szClassName)-1);
	set_kvd(0, KV_ClassName, szClassName);
	set_kvd(0, KV_KeyName, szKey);
	set_kvd(0, KV_Value, szValue);
	set_kvd(0, KV_fHandled, 0);
	
	dllfunc(DLLFunc_KeyValue, iEnt, 0);
}

stock fm_strip_user_weapons(iClient)
{
	new iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "player_weaponstrip"));
	if(!pev_valid(iEnt))
		return 0;
	
	dllfunc(DLLFunc_Spawn, iEnt);
	dllfunc(DLLFunc_Use, iEnt, iClient);
	engfunc(EngFunc_RemoveEntity, iEnt);
	
	return 1;
}