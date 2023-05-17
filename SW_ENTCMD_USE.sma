/*
 * entity use command plugin for SkillzWorld
 *
 * This plugin adds santa hats to players in Team Fortress Classic
 * during the specified holiday season (December 1st to January 2nd).
 *
 * Written for AMX Mod X by skillzworld / MrKoala
 */

#include "include/global"
#include <engine>
#include <fakemeta>

new const BEAM_SPRITE[] = "sprites/laserbeam.spr"

new g_iBeamSprite;
public plugin_precache() {
    g_iBeamSprite = precache_model(BEAM_SPRITE);
}

public plugin_init() {
    RegisterPlugin();
    register_clcmd("e_use", "use_entity", ADMIN_KICK, "Use entity you are looking at");
}

public use_entity(id) {

    new entityIndex = GetAimEntity(id);

    if (!entityIndex) return PLUGIN_CONTINUE;

    dllfunc(DLLFunc_Use, entityIndex, id)

    /*		MDLL_Use(pUse, pEntity);

		Vector origin = Vector(0, 0, 0);

		if (pUse->v.origin == Vector(0, 0, 0))
			origin = ((pUse->v.absmin + pUse->v.absmax) * 0.5);
		else 
			origin = pUse->v.origin;
		int m_beamSprite = gSkillzServer.Precache("sprites/laserbeam.spr");*/

    new Float:vecOrigin[3], Float:absMin[3], Float:absMax[3], Float:vecDest[3], vecInt[3]
    vecOrigin = Float:{0.0, 0.0, 0.0};
    entity_get_vector(entityIndex, EV_VEC_origin, vecOrigin);
    entity_get_vector(entityIndex, EV_VEC_absmin, absMin);
    entity_get_vector(entityIndex, EV_VEC_absmax, absMax);

    if (equal_vectors(vecOrigin, Float:{0.0, 0.0, 0.0})) {
        vecDest[0] = ((absMin[0] + absMax[0]) * 0.5);
        vecDest[1] = ((absMin[1] + absMax[1]) * 0.5);
        vecDest[2] = ((absMin[2] + absMax[2]) * 0.5);
    } else {
        vecDest = vecOrigin;
    }/*
    if (!equal_vectors(vecOrigin, {0.0, 0.0, 0.0})) {
        //entity_get_vector(entityIndex, EV_VEC_origin, vecOrigin);
        vecDest = vecOrigin;
        console_print(0, "Entity is not brushed %f %f %f", vecDest[0], vecDest[1], vecDest[2]);
    } else {
        console_print(0, "Entity is brushed before: %f %f %f %f %f %f %f %f %f", absMin[0], absMin[1], absMin[2], absMax[0], absMax[1], absMax[2], vecDest[0], vecDest[1], vecDest[2]);
        vecDest[0] = (absMin[0] + absMax[0]) / 2;
        vecDest[1] = (absMin[1] + absMax[1]) / 2;
        vecDest[2] = (absMin[2] + absMax[2]) / 2;
        console_print(0, "Entity is brushed after: %f %f %f %f %f %f %f %f %f", absMin[0], absMin[1], absMin[2], absMax[0], absMax[1], absMax[2], vecDest[0], vecDest[1], vecDest[2]);
    }*/
    vecInt[0] = floatround(vecDest[0])
    vecInt[1] = floatround(vecDest[1])
    vecInt[2] = floatround(vecDest[2])
    broadcast_beam(id, vecInt);
    return PLUGIN_CONTINUE;
}

stock broadcast_beam(id, vecOrigin[3]) {
    console_print(0, "broadcasting beam: %d %d %d", vecOrigin[0], vecOrigin[1], vecOrigin[2]);
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    {
        write_byte(TE_BEAMENTPOINT);
        write_short(id);
        write_coord(vecOrigin[0]);
        write_coord(vecOrigin[1]);
        write_coord(vecOrigin[2]);
        write_short(g_iBeamSprite);
        write_byte(0);
        write_byte(0);
        write_byte(2);
        write_byte(5);
        write_byte(50);
        write_byte(20);
        write_byte(15);
        write_byte(175);
        write_byte(255);
        write_byte(20);
    }
    message_end();

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    {
        write_byte(TE_BEAMENTPOINT);
        write_short(id);
        write_coord(vecOrigin[0]);
        write_coord(vecOrigin[1]);
        write_coord(vecOrigin[2]);
        write_short(g_iBeamSprite);
        write_byte(0);
        write_byte(0);
        write_byte(2);
        write_byte(5);
        write_byte(10);
        write_byte(175);
        write_byte(125);
        write_byte(70);
        write_byte(255);
        write_byte(20);
   }
    message_end();
}
