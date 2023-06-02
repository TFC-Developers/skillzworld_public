#include "include/global"
#include <engine>
#include <time>
#include <fakemeta>


new g_laserbeam_model = 0;
public plugin_init() {
    RegisterPlugin();
    register_clcmd("say /fakewall", "cmd_StartBlock"); 
    // Register the think function to be called every second
    register_think("FakeWallThink", "sw_fakewall");
}

public plugin_precache() {
    g_laserbeam_model = precache_model("sprites/laserbeam.spr");
}


/*
void FakeWallThink(edict_t *pEntity) {
	if (pEntity->v.euser4 != NULL) {
		edict_t *pAdmin = pEntity->v.euser4;

		entvars_t *pPev = VARS(pAdmin);
		TraceResult tr;
		UTIL_MakeVectors(pPev->v_angle);
		UTIL_TraceLine(pPev->origin + pPev->view_ofs, pPev->origin + pPev->view_ofs + gpGlobals->v_forward * pEntity->v.fuser1, dont_ignore_monsters, ENT(pPev), &tr);

		Vector endposition = tr.vecEndPos;

		//Vector endposition = (pAdmin->v.origin + pAdmin->v.view_ofs + gpGlobals->v_forward) * pEntity->v.fuser1;

		Vector center = (pEntity->v.vuser1 + endposition) * 0.5;

		SET_ORIGIN(pEntity, center);

		DrawBox(pEntity->v.vuser1, endposition);

		pEntity->v.vuser2 = endposition;

		Vector fmin = -1 * (endposition - pEntity->v.vuser1) * 0.5;
		Vector fmax = (endposition - pEntity->v.vuser1) * 0.5;
		float temp = 0;


		if (fmin.x > fmax.x)  {
			temp = fmin.x;
			fmin.x = fmax.x;
			fmax.x = temp;
		}
		if (fmin.y > fmax.y)  {
			temp = fmin.y;
			fmin.y = fmax.y;
			fmax.y = temp;
		}
		if (fmin.z > fmax.z)  {
			temp = fmin.z;
			fmin.z = fmax.z;
			fmax.z = temp;
		}
		UTIL_SetSize(VARS(pEntity), fmin, fmax);


		pEntity->v.nextthink = gpGlobals->time + 0.1;
		return;
	}
	else if (CVAR_GET_FLOAT("sw_showfakewalls") == 1)
	{
		pEntity->v.rendermode = 0;
		pEntity->v.renderamt = 255;
		DrawBox(pEntity->v.vuser1, pEntity->v.vuser2,Vector(0,255,0),50);
		pEntity->v.nextthink = gpGlobals->time + 5;
		return;
	}
	pEntity->v.rendermode = 1;
	pEntity->v.renderamt = 0;
	pEntity->v.nextthink = gpGlobals->time + 5;
}

int __CmdFunc_StartBlock(int plindex) {

	edict_t *pAdmin = INDEXENT(plindex);
	entvars_t *pPev = VARS(pAdmin);
	edict_t* pScan = NULL;


	while ((pScan = FindEntityByString(pScan, "classname", "sw_fakewall")))
	{
		if (pScan->v.euser4 == pAdmin) {
			SayOne(pAdmin, "* Cannot spawn two fake walls at once! Finish the current one first.");
			return 0;
		}
	}
	TraceResult tr;
	UTIL_MakeVectors(pPev->v_angle);
	UTIL_TraceLine(pPev->origin + pPev->view_ofs, pPev->origin + pPev->view_ofs + gpGlobals->v_forward	* 1300, dont_ignore_monsters, ENT(pPev), &tr);

	Vector startbox = tr.vecEndPos;
	edict_t *pBox = NULL;
	pBox = CREATE_NAMED_ENTITY(MAKE_STRING("info_target"));
	MDLL_Spawn(pBox);
	pBox->v.origin = pAdmin->v.origin;
	pBox->v.angles = Vector(0, 0, 0);
	pBox->v.velocity = Vector(0, 0, 0);
	pBox->v.takedamage = DAMAGE_NO;
	pBox->v.health = 1;
	pBox->v.movetype = MOVETYPE_FLY;
	pBox->v.nextthink = gpGlobals->time;
	pBox->v.vuser1 = startbox; 
	pBox->v.fuser1 = ((pPev->origin + pPev->view_ofs) - startbox).Length();
	pBox->v.solid = SOLID_BBOX;
	pBox->v.euser4 = pAdmin;

	SET_MODEL(pBox, "models/nail.mdl");
	UTIL_SetSize(VARS(pBox), Vector(0, 0, 0), Vector(0, 0, 0));
	pBox->v.classname = MAKE_STRING("sw_fakewall");
	CLIENT_PRINTF(INDEXENT(plindex), print_console, UTIL_VarArgs("Spawning fake_wall...\n"));

	return 1;
}

*/

public FakeWallThink(pEntity)
{
    new pAdmin = pev(pEntity, pev_euser4);

    if(pAdmin != 0)
    {
        new Float:fVecOrigin[3], Float:fVecAngle[3], Float:fVecForward[3], Float:trEndPos[3];
        get_user_origin(pAdmin, fVecOrigin);
        get_global_vector(GL_v_forward, fVecForward);
        static Float:fAngles[3]; pev(pEntity, pev_v_angle, fAngles)
        engfunc(EngFunc_MakeVectors, fAngles) // Convert view angle to normalised vector
        new Float:fViewOfs[3]; pev(pEntity, pev_view_ofs, fViewOfs);
        new Float:origin1[3], Float:origin2[3];
        for(new i = 0; i < 3; i++) origin1[i] = fVecOrigin[i] + fViewOfs[i];
        for(new i = 0; i < 3; i++) origin2[i] = fVecOrigin[i] + fViewOfs[i] + fVecForward[i] * 8192.0;

        new tr[5]; // Initialized variable here
        engfunc(EngFunc_TraceLine, origin1, origin2, DONT_IGNORE_MONSTERS, 0, tr);

        get_tr2(tr, TR_vecEndPos, trEndPos);

        new Float:fVecUser[3]; pev(pEntity, pev_vuser1,fVecUser);

        new Float:fCenter[3];
        for(new i = 0; i < 3; i++) fCenter[i] = (fVecUser[i] + trEndPos[i]) * 0.5;

        set_pev(pEntity, pev_origin, fCenter);
    
        new Float:fA[3]; pev(pEntity, pev_vuser1, fA);
        DrawBox(fA, trEndPos, {255,0,0}, 10); 

        set_pev(pEntity, pev_vuser2, trEndPos);

        new Float:fMin[3], Float:fMax[3], Float:temp;
        for(new i = 0; i < 3; i++) fMin[i] = fMax[i] = (trEndPos[i] - fVecUser[i]) * 0.5;
        
        if (fMin[0] > fMax[0]) { temp = fMin[0]; fMin[0] = fMax[0]; fMax[0] = temp; }
        if (fMin[1] > fMax[1]) { temp = fMin[1]; fMin[1] = fMax[1]; fMax[1] = temp; }
        if (fMin[2] > fMax[2]) { temp = fMin[2]; fMin[2] = fMax[2]; fMax[2] = temp; }

        set_pev(pEntity, pev_mins, fMin);
        set_pev(pEntity, pev_maxs, fMax);

        entity_set_float(pEntity, EV_FL_nextthink, (get_gametime() + 0.1) )
        return;
    }
    else
    {
        new Float:fVecUser1[3], Float:fVecUser2[3];
        pev(pEntity, pev_vuser1, fVecUser1);
        pev(pEntity, pev_vuser2, fVecUser2);
        set_pev(pEntity, pev_rendermode, kRenderNormal);
        set_pev(pEntity, pev_renderamt, 255.0);
        DrawBox(fVecUser1, fVecUser2, {0.0, 255.0, 0.0}, 50); 
        entity_set_float(pEntity, EV_FL_nextthink, (get_gametime() + 5.0) )
        return;
    }
    set_pev(pEntity, pev_rendermode, kRenderTransAlpha);
    set_pev(pEntity, pev_renderamt, 0.0);
    entity_set_float(pEntity, EV_FL_nextthink, (get_gametime() + 5.0) );
}


public DrawBox(Float:vecStart[3], Float:vecEnd[3], Float:color[3], iDispTime)
{
    new Float:obenLinks[3]; for(new i = 0; i < 3; i++) obenLinks[i] = vecStart[i];
    obenLinks[0] = vecEnd[0];
    drawBeam(vecStart, obenLinks, iDispTime, color);

    new Float:UntenRechts[3]; for(new i = 0; i < 3; i++) UntenRechts[i] = vecStart[i];
    UntenRechts[0] = vecEnd[2];
    drawBeam(vecStart, UntenRechts, iDispTime, color);

    new Float:ObenRechts[3]; for(new i = 0; i < 3; i++) ObenRechts[i] = UntenRechts[i];
    ObenRechts[2] = obenLinks[2];
    drawBeam(UntenRechts, ObenRechts, iDispTime, color);

    drawBeam(ObenRechts, obenLinks, iDispTime, color);

    new Float:HintenUntenRechts[3]; for(new i = 0; i < 3; i++) HintenUntenRechts[i] = vecEnd[i];
    HintenUntenRechts[2] = vecStart[2];
    drawBeam(vecEnd, HintenUntenRechts, iDispTime, color);
    drawBeam(HintenUntenRechts, UntenRechts, iDispTime, color);

    new Float:HintenUntenLinks[3]; for(new i = 0; i < 3; i++) HintenUntenLinks[i] = HintenUntenRechts[i];
    HintenUntenLinks[0] = vecStart[0];
    drawBeam(HintenUntenLinks, HintenUntenRechts, iDispTime, color);
    drawBeam(vecStart, HintenUntenLinks, iDispTime, color);

    new Float:HintenObenLinks[3]; for(new i = 0; i < 3; i++) HintenObenLinks[i] = HintenUntenLinks[i];
    HintenObenLinks[2] = vecEnd[2];
    drawBeam(HintenObenLinks, HintenUntenLinks, iDispTime, color);
    drawBeam(vecEnd, HintenObenLinks, iDispTime, color);
    drawBeam(obenLinks, HintenObenLinks, iDispTime, color);
    drawBeam(vecEnd, ObenRechts, iDispTime, color);

    new Float:center[3];
    for(new i = 0; i < 3; i++) center[i] = (vecStart[i] + vecEnd[i]) * 0.5;

    for(new i = 0; i < 3; i++)
    {
        new Float:draw[3]; for(new i = 0; i < 3; i++) draw[i] = center[i];
        new Float:draw1[3]; for(new i = 0; i < 3; i++) draw1[i] = center[i];
        draw[i] += 5.0;
        draw1[i] -= 5.0;
        drawBeam(draw1, draw, iDispTime, color);
    }
}

public drawBeam(Float:from[3], Float:to[3], life, Float:color[3])
{
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_BEAMPOINTS);

    for(new i = 0; i < 3; i++) write_coord(from[i]);
    for(new i = 0; i < 3; i++) write_coord(to[i]);

    write_short(g_laserbeam_model);
    write_byte(1);
    write_byte(10);
    write_byte(life);
    write_byte(10);
    write_byte(0);

    for(new i = 0; i < 3; i++) write_byte(floatround(color[i]));
    write_byte(255);
    write_byte(10);

    message_end();
}


public cmd_StartBlock(id)
{
    if (!is_user_alive(id))
        return PLUGIN_CONTINUE;

    new sw_fakewall = -1; 
  
    while ( ( sw_fakewall = find_ent_by_class( sw_fakewall, "sw_fakewall" ) ) ) 
    { 
        if (pev(sw_fakewall, pev_euser4) == id)
        {
            client_print(id, print_chat, "* Cannot spawn two fake walls at once! Finish the current one first.");
            return PLUGIN_CONTINUE;
        }
    }
    new Float:fVecOrigin[3], Float:fVecAngle[3], Float:fVecForward[3], Float:trEndPos[3];
    get_user_origin(id, fVecOrigin);
    get_global_vector(GL_v_forward, fVecForward);
    static Float:fAngles[3]; pev(id, pev_v_angle, fAngles)
    engfunc(EngFunc_MakeVectors, fAngles) // Convert view angle to normalised vector
    
    new Float:fViewOfs[3]; pev(id, pev_view_ofs, fViewOfs);
    new Float:origin1[3], Float:origin2[3];
    for(new i = 0; i < 3; i++) origin1[i] = fVecOrigin[i] + fViewOfs[i];
    for(new i = 0; i < 3; i++) origin2[i] = fVecOrigin[i] + fViewOfs[i] + fVecForward[i] * 8192.0;
    engfunc(EngFunc_TraceLine, origin1, origin2, DONT_IGNORE_MONSTERS, 0, trEndPos);

    new box = create_entity("info_target");
    set_pev(box, pev_origin, fVecOrigin);
    set_pev(box, pev_angles, {0.0, 0.0, 0.0});
    set_pev(box, pev_velocity, {0.0, 0.0, 0.0});
    set_pev(box, pev_takedamage, DAMAGE_NO);
    set_pev(box, pev_health, 1.0);
    set_pev(box, pev_movetype, MOVETYPE_FLY);
    set_pev(box, pev_nextthink, get_gametime());
    set_pev(box, pev_vuser1, trEndPos);

    new Float:length[3];
    for(new i = 0; i < 3; i++) length[i] = fVecOrigin[i] + fViewOfs[i] - trEndPos[i];
    set_pev(box, pev_fuser1, vector_length(length));
    set_pev(box, pev_solid, SOLID_BBOX);
    set_pev(box, pev_euser4, id);

    engfunc(EngFunc_SetModel, box, "models/nail.mdl");
  //  set_pev(box, pev_size, {0.0, 0.0, 0.0});
    set_pev(box, pev_classname, "sw_fakewall");

    client_print(id, print_chat, "* Spawning fake_wall...\n");

    return PLUGIN_HANDLED;
}