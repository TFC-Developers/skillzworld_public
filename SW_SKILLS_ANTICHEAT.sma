#include "include/global"
#include "include/utils"
#include <engine>

public plugin_init()
{
	RegisterPlugin();
	register_event("ScreenFade", "tele_used", "be")
}



public tele_used(player)
{
	static entlist[1], ents
	// *** entrance ***
		ents = find_sphere_class(player, "building_teleporter", 48.0, entlist, sizeof(entlist))
		if (ents > 0)
		{
            fm_strip_user_weapons(player);
            stock_slay(player);
            dllfunc(DLLFunc_Spawn, player);
		}

	// *** exit ***
    new ents1, entlist1[1];
		ents1 = find_sphere_class(player, "building_teleporter", 48.0, entlist1, sizeof(entlist1))
		if (ents1 > 0)
		{
            fm_strip_user_weapons(player);
            stock_slay(player);
            dllfunc(DLLFunc_Spawn, player);
		}
	
}