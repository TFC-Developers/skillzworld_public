#include "include/global"
#include <engine>
#include <time>
#include <fakemeta>


new g_laserbeam_model = 0;
public plugin_init() {
	RegisterPlugin();
	register_clcmd("say /fakewall", "cmd_StartBlock"); 
	register_think("sw_fakewall", "FakeWallThink"); // Register the think function to be called every second
}

public plugin_precache() {
	g_laserbeam_model = precache_model("sprites/laserbeam.spr");
}

const pev_vfakewallorigin  = pev_vuser1
const pev_vfakewallorigin2 = pev_vuser2
const pev_efakewalladmin   = pev_euser4

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

stock get_trace_hit_origin(id, Float:trEndPos[3]) {
	new Float:fVecOrigin[3], Float:fVecForward[3]
	entity_get_vector(id, EV_VEC_origin, fVecOrigin)
	get_global_vector(GL_v_forward, fVecForward);
	static Float:fAngles[3]; pev(id, pev_v_angle, fAngles)
	engfunc(EngFunc_MakeVectors, fAngles) // Convert view angle to normalised vector
	new Float:fViewOfs[3]; pev(id, pev_view_ofs, fViewOfs);
	new Float:origin1[3], Float:origin2[3];
	
	for(new i = 0; i < 3; i++) origin1[i] = fVecOrigin[i] + fViewOfs[i];
	for(new i = 0; i < 3; i++) origin2[i] = fVecOrigin[i] + fViewOfs[i] + fVecForward[i] * 8192.0;

	new tr = create_tr2(); // Initialized variable here
	engfunc(EngFunc_TraceLine, origin1, origin2, IGNORE_MONSTERS, 0, tr);
	get_tr2(tr, TR_vecEndPos, trEndPos);
	free_tr2(tr)
}

public FakeWallThink(pEntity) {
	static classname[0x20]
	entity_get_string pEntity, EV_SZ_classname, classname, charsmax(classname)
	new pAdmin = pev(pEntity, pev_efakewalladmin);

	if (pAdmin) {
		new Float:trEndPos[3]; get_trace_hit_origin pAdmin, trEndPos

		new Float:fFakeWallOrigin[3]; pev(pEntity, pev_vfakewallorigin, fFakeWallOrigin);

		new Float:fCenter[3];
		for(new i = 0; i < 3; i++) fCenter[i] = (fFakeWallOrigin[i] + trEndPos[i]) * 0.5;

		set_pev(pEntity, pev_origin, fCenter);
		console_print 0, "Origin:{%f %f %f}, End:{%f %f %f}", fFakeWallOrigin[0], fFakeWallOrigin[1], fFakeWallOrigin[2], trEndPos[0], trEndPos[1], trEndPos[2]
		DrawBox(fFakeWallOrigin, trEndPos, {255, 0, 0}, 2); 

		set_pev(pEntity, pev_vfakewallorigin2, trEndPos);

		new Float:fMin[3], Float:fMax[3]
		for(new i = 0; i < 3; i++) fMin[i] = fMax[i] = (trEndPos[i] - fFakeWallOrigin[i]) * 0.5;
		
		new Float:temp
		if (fMin[0] > fMax[0]) { temp = fMin[0]; fMin[0] = fMax[0]; fMax[0] = temp; }
		if (fMin[1] > fMax[1]) { temp = fMin[1]; fMin[1] = fMax[1]; fMax[1] = temp; }
		if (fMin[2] > fMax[2]) { temp = fMin[2]; fMin[2] = fMax[2]; fMax[2] = temp; }

		set_pev(pEntity, pev_mins, fMin);
		set_pev(pEntity, pev_maxs, fMax);

		entity_set_float(pEntity, EV_FL_nextthink, get_gametime() + 0.1)
	} else {
		new Float:fVecUser1[3], Float:fVecUser2[3];
		pev(pEntity, pev_vfakewallorigin, fVecUser1);
		pev(pEntity, pev_vfakewallorigin2, fVecUser2);
		set_pev(pEntity, pev_rendermode, kRenderNormal);
		set_pev(pEntity, pev_renderamt, 255.0);
		DrawBox(fVecUser1, fVecUser2, {0, 255, 0}, 2); 
		entity_set_float(pEntity, EV_FL_nextthink, get_gametime() + 5.0)
	}
	return
	set_pev(pEntity, pev_rendermode, kRenderTransAlpha);
	set_pev(pEntity, pev_renderamt, 0.0);
	entity_set_float(pEntity, EV_FL_nextthink, get_gametime() + 5.0);
}


public DrawBox(const Float:start[3], const Float:end[3], const color[3], iDispTime) {
	new Float:x1 = start[0], Float:y1 = start[1], Float:z1 = start[2], Float:x2 = end[0], Float:y2 = end[1], Float:z2 = end[2]
	drawBeam(x1,y1,z1, x2,y1,z1, iDispTime, color) // Bottom
	drawBeam(x1,y1,z1, x1,y2,z1, iDispTime, color)
	drawBeam(x2,y2,z1, x2,y1,z1, iDispTime, color)
	drawBeam(x2,y2,z1, x1,y2,z1, iDispTime, color)
	drawBeam(x1,y1,z2, x2,y1,z2, iDispTime, color) // Top
	drawBeam(x1,y1,z2, x1,y2,z2, iDispTime, color)
	drawBeam(x2,y2,z2, x2,y1,z2, iDispTime, color)
	drawBeam(x2,y2,z2, x1,y2,z2, iDispTime, color)
	drawBeam(x1,y1,z1, x1,y1,z2, iDispTime, color) // Sides
	drawBeam(x2,y2,z1, x2,y2,z2, iDispTime, color)
	drawBeam(x1,y2,z1, x1,y2,z2, iDispTime, color)
	drawBeam(x2,y1,z1, x2,y1,z2, iDispTime, color)
	
	/* German code with broken shape buddy
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

	for(new i = 0; i < 3; i++) {
		new Float:draw[3]; for(new i = 0; i < 3; i++) draw[i] = center[i];
		new Float:draw1[3]; for(new i = 0; i < 3; i++) draw1[i] = center[i];
		draw[i] += 5.0;
		draw1[i] -= 5.0;
		drawBeam(draw1, draw, iDispTime, color);
	}
	*/
}

public drawBeam(Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2, /*const Float:from[3], const Float:to[3], */life, const color[3]) {
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	{
		write_byte TE_BEAMPOINTS
		/*
		for (new i = 0; i < 3; i++) write_coord_f from[i]
		for (new i = 0; i < 3; i++) write_coord_f to[i]
		*/
		write_coord_f x1
		write_coord_f y1
		write_coord_f z1
		write_coord_f x2
		write_coord_f y2
		write_coord_f z2
		write_short g_laserbeam_model
		write_byte 1 // Starting frame
		write_byte 10 // Framerate
		write_byte life
		write_byte 10 // Width
		write_byte 0 // Noise
		for (new i = 0; i < 3; i++) write_byte color[i]
		write_byte 255 // Brightness
		write_byte 10 // Scroll speed
	}
	message_end
}


public cmd_StartBlock(id) {
	if (!is_user_alive(id)) return PLUGIN_CONTINUE;

	new sw_fakewall = -1; 
	while ( (sw_fakewall = find_ent_by_class(sw_fakewall, "sw_fakewall")) ) { 
		if (pev(sw_fakewall, pev_efakewalladmin) == id) {
			client_print(id, print_chat, "* Cannot spawn two fake walls at once! Finish the current one first.");
			return PLUGIN_CONTINUE;
		}
	}
	new Float:trEndPos[3]; get_trace_hit_origin id, trEndPos

	new Float:fVecOrigin[3]; entity_get_vector id, EV_VEC_origin, fVecOrigin
	new box = create_entity("info_target");
	set_pev(box, pev_origin, fVecOrigin);
	set_pev(box, pev_takedamage, DAMAGE_NO);
	set_pev(box, pev_health, 1.0);
	set_pev(box, pev_movetype, MOVETYPE_FLY);
	set_pev(box, pev_nextthink, get_gametime());
	set_pev(box, pev_vfakewallorigin, trEndPos);
	
	new Float:length[3];
	new Float:fViewOfs[3]; pev id, pev_view_ofs, fViewOfs
	for(new i = 0; i < 3; i++) length[i] = fVecOrigin[i] + fViewOfs[i] - trEndPos[i];
	set_pev(box, pev_fuser1, vector_length(length));
	set_pev(box, pev_solid, SOLID_BBOX);
	set_pev(box, pev_efakewalladmin, id);

	engfunc(EngFunc_SetModel, box, "models/nail.mdl");
	//  set_pev(box, pev_size, Float:{0.0, 0.0, 0.0});
	set_pev(box, pev_classname, "sw_fakewall");

	client_print(id, print_chat, "* Spawning fake_wall...\n");

	return PLUGIN_HANDLED;
}
