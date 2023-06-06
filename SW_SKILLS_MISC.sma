/**
 *	Based on Ghost Recorder by TeddyDesTodes

The primary data written to the replay file are:

1. Player information, map name, and server name (File header).
2. Player position, angles, velocity, sequence, and gaitsequence every tick if they have changed since the last tick (prethink).

File size:

1. File header: The total size of the header is 201 bytes (4 + 4 + 32 + 35 + 32 + 32 + 32 + 32). This size is consistent across all files.

2. Premove calculations: The size of data being written for each player update is 88 bytes (4*10 + 4*3 + 4*3 + 4*3 + 4*2). This data is not written for every game tick. It is only written if the player's position, angles, or velocity has changed since the last tick. The frequency of this update is determined by the `RECLIMITER` constant. 

The total size of a replay file will depend on how much a player moves around. For example, if a player is moving continuously, then there will be more updates and hence larger file sizes. On the contrary, if a player doesn't move a lot, the file size will be much smaller.

Estimate file sizes:

- 201 bytes are written in the header of the file.
- 88 bytes are written per frame in pre-think function.

Given RECLIMITER is set to 0.03 seconds, it means that there will be approximately 33.33 write operations in a second (1 / RECLIMITER).

per Second:

33.33 frames/second * 88 bytes/frame = 2933 bytes/second

Various run times:

- 10-minute run: 10 minutes * 60 seconds/minute * 2933 bytes/second = ~1.76 MB
- 30-minute run: 3 * 1.76 MB = ~5.28 MB
- 60-minute run: 2 * 5.28 MB = ~10.56 MB
- 90-minute run: 3 * 5.28 MB = ~15.84 MB

1GB storage fits: 1,073,741,824 bytes / 2933 bytes/second ≈ 366,139 seconds
                    366,139 seconds / 60 seconds/minute ≈ 6,102 minutes = 4,24 days

 * 
 **/


#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include "include/global"

#define FILEVERSION 24
#define MAXPLAYERS 33
#define RECLIMITER 0.03
#define SAVEPATH "addons/amxmodx/replays/"

new g_FileHandler[MAXPLAYERS]
new g_MapName[33],g_HostName[33]
new g_SteamId[MAXPLAYERS][35]
new g_szFileName[MAXPLAYERS][128];
new g_Rate[MAXPLAYERS];
new Float:g_LastThink[MAXPLAYERS]
new Float:g_LastAngle[MAXPLAYERS][3]
new Float:g_LastOrigin[MAXPLAYERS][3]
new Float:g_LastVelocity[MAXPLAYERS][3]
new g_isRecording[MAXPLAYERS]

/* Initializes the plugin when the server is started.
 * Register forwards, get the map and hostname and create the replay directory if it doesn't exist.
 */
public plugin_init()
{
    RegisterPlugin();
	register_forward(FM_Think,"fm_ghost_think",0)
	register_forward(FM_PlayerPostThink,"fm_plr_prethink",0)

	if(!dir_exists(SAVEPATH)){
		log_amx("Save dir does not exist, creating it for you.")
		if(mkdir(SAVEPATH) != 0){
			log_amx("Couldn't create dir, please do it manually!")
		}
	}
	get_mapname(g_MapName,32);
	get_cvar_string("hostname",g_HostName,32);

    register_clcmd("say /record", "toggle_record");
}


public toggle_record(id) {
    if (g_isRecording[id] == 0) {
        start_record(id);
        client_print(id, print_chat, "Recording started");
    } else {
        stop_record(id);
        client_print(id, print_chat, "Recording stopped");
    }
    return PLUGIN_HANDLED;
}

/* Triggered when a client enters the server.
 * Initializes variables for the client.
 */
public client_putinserver(id)
{
	g_FileHandler[id] = 0;
	g_isRecording[id] = 0;
    g_Rate[id] = 0;
	g_LastThink[id] = get_gametime();
}

/* Triggered when a client is authorized.
 * Stores the client's Steam ID.
 */
public client_authorized(id)
{
	get_user_authid(id,g_SteamId[id][0],34)
	replace_all(g_SteamId[id][0],34,":","_")
}

/* Triggered when the server is shut down.
 * Closes all open file handlers.
 */
public plugin_end()
{
	for(new i = 0; i < MAXPLAYERS; i++){
		if(g_FileHandler[i] != 0){
			fclose(g_FileHandler[i])
			g_FileHandler[i] = 0
		}
	}
}

/* Triggered when a client disconnects.
 * Closes the file handler for the client.
 */
public client_disconnect(id)
{
	if(g_FileHandler[id] != 0){
		fclose(g_FileHandler[id]);
		g_FileHandler[id] = 0;
	}
}


public start_record(id){
    if (get_user_team(id) < 1 || get_user_team(id) > 4) {
        DebugPrintLevel(0,"%d is not in a valid team to record",id);
        return PLUGIN_HANDLED;
    }
	new fileName[128]; new szTemp[128];
    formatex(szTemp, sizeof(szTemp), "%s%d", g_SteamId[id], get_systime());     //szTemp = g_SteamId[id] + get_systime()
    //native hash_string(const string[], const HashType:type, output[], const outputSize);
    new szHash[128]; hash_string(szTemp, Hash_Sha1, szHash, sizeof(szHash));    //szHash = hash_string(szTemp, Hash_Sha1)

	formatex(fileName, sizeof(fileName),"%s%s.rec",SAVEPATH,szHash);	            //fileName = SAVEPATH + szHash + ".rec"
    formatex(g_szFileName[id], 128, "%s", fileName);       //g_szFileName[id] = fileName
	g_FileHandler[id] = fopen(fileName,"wb");                                   //g_FileHandler[id] = fopen(fileName,"wb") (w=write b=binary)
	write_fileheader(id);                                                       //write_fileheader(id)
	g_isRecording[id] = 1;                                                      //player is recording               
	client_print(id,print_chat,"* Recording started")                           //notify player
    DebugPrintLevel(0,"Recording started for %d (%s)",id, fileName);            
    return PLUGIN_HANDLED;
}
public stop_record(id){
	g_isRecording[id] = 0;                                                      //player is not recording anymore
	fclose(g_FileHandler[id]);
	g_FileHandler[id] = 0;                                                      //close file
	client_print(id,print_chat,"* Recording stopped")                           //notify player
    DebugPrintLevel(0,"Recording stopped for %d (%s)",id, g_szFileName[id]);
}

public write_fileheader(id){
	new name[33],weapon_model[33],model[33];                //init vars
	fwrite(g_FileHandler[id],FILEVERSION,BLOCK_INT)         //write fileversion
	fwrite(g_FileHandler[id],get_systime(),BLOCK_INT)       //write systime
	get_user_name(id,name,32);                              //get name
	for(new i = 0;i < sizeof name;i++){
		fwrite(g_FileHandler[id],name[i],BLOCK_CHAR)        //write name
	}
	for(new i = 0;i < 35;i++){
		fwrite(g_FileHandler[id],g_SteamId[id][i],BLOCK_CHAR); //write steamid
	}
	for(new i = 0;i < sizeof g_MapName;i++){
		fwrite(g_FileHandler[id],g_MapName[i],BLOCK_CHAR);  //write mapname
	}

	for(new i = 0;i < sizeof g_HostName;i++){
		fwrite(g_FileHandler[id],g_HostName[i],BLOCK_CHAR); //write hostname
	}

	pev(id,pev_weaponmodel2,weapon_model,32)                //get weaponmodel
	for(new i = 0;i < sizeof weapon_model;i++){
		fwrite(g_FileHandler[id],weapon_model[i],BLOCK_CHAR); //write weaponmodel
	}

	pev(id,pev_model,model,32)                              //get model
	for(new i = 0;i < sizeof model;i++){
		fwrite(g_FileHandler[id],model[i],BLOCK_CHAR);      //write model
	}
    //total size of header: 4 + 4 + 32 + 35 + 32 + 32 + 32 + 32 = 201
}

/* Handles the PlayerPostThink event.
 * Records player actions, like movement and actions, to the replay file.
 */
public fm_plr_prethink(id){
	if(is_user_alive(id) && g_isRecording[id] != 0){
        if (get_user_team(id) < 1 || get_user_team(id) > 4) {
            stop_record(id);
            return PLUGIN_HANDLED;
        }
		static Float:ago,Float:origin[3],Float:angles[3],Float:veloc[3],Float:rate;
		static sequence,gaitsequence
		ago = get_gametime()-g_LastThink[id]
		if(ago < RECLIMITER) return FMRES_IGNORED
		rate = floatdiv(1.0,ago)
		rate = floatmul(rate,48.0)
		g_Rate[id] = floatround(rate);
		pev(id,pev_origin,origin)
		pev(id,pev_velocity,veloc)
		pev(id,pev_angles,angles)
		sequence = pev(id,pev_sequence)
		gaitsequence = pev(id,pev_gaitsequence)
        if((g_LastAngle[id][0] == angles[0] && g_LastAngle[id][1] == angles[1] && g_LastAngle[id][2] == angles[2] ) 
            && (g_LastOrigin[id][0] == origin[0] && g_LastOrigin[id][1] == origin[1] && g_LastOrigin[id][2] == origin[2] ) 
            && (g_LastVelocity[id][0] == veloc[0] && g_LastVelocity[id][1] == veloc[1] && g_LastVelocity[id][2] == veloc[2])) 
        {
            return FMRES_IGNORED;
        }
		g_LastAngle[id][0] = angles[0]
		g_LastAngle[id][1] = angles[1]
		g_LastAngle[id][2] = angles[2]
		g_LastOrigin[id][0] = origin[0]
		g_LastOrigin[id][1] = origin[1]
		g_LastOrigin[id][2] = origin[2]
		g_LastVelocity[id][0] = veloc[0]
		g_LastVelocity[id][1] = veloc[1]
		g_LastVelocity[id][2] = veloc[2]
		g_LastThink[id] = get_gametime()
		fwrite(g_FileHandler[id],_:ago,BLOCK_INT)
		fwrite(g_FileHandler[id],_:angles[0],BLOCK_INT)
		fwrite(g_FileHandler[id],_:angles[1],BLOCK_INT)
		fwrite(g_FileHandler[id],_:angles[2],BLOCK_INT)
		fwrite(g_FileHandler[id],_:origin[0],BLOCK_INT)
		fwrite(g_FileHandler[id],_:origin[1],BLOCK_INT)
		fwrite(g_FileHandler[id],_:origin[2],BLOCK_INT)
		fwrite(g_FileHandler[id],_:veloc[0],BLOCK_INT)
		fwrite(g_FileHandler[id],_:veloc[1],BLOCK_INT)
		fwrite(g_FileHandler[id],_:veloc[2],BLOCK_INT)
		fwrite(g_FileHandler[id],sequence,BLOCK_INT)
		fwrite(g_FileHandler[id],gaitsequence,BLOCK_INT)
		return FMRES_HANDLED
        //sice of a prethink write in byte: 4*10 + 4*3 + 4*3 + 4*3 + 4*2 = 88
	}
	return FMRES_IGNORED
}


/*
public hud(){
	static filename[128],size
	for(new i = 0; i< MAXPLAYERS; i++){
		if(is_user_connected(i) && g_isRecording[i]){
			get_filename(i,g_SaveSlot[i],filename)
			size = filesize(filename)/1024
			set_hudmessage(255,0,0,-0.9,-0.9,_,_,0.4,0.3,0.3);
			if(get_pcvar_num(g_CVar_maxsize) > 0){
				ShowSyncHudMsg(i,g_syncHud,"[ REC %d/%d kb (%d byte/s) ]",size,get_pcvar_num(g_CVar_maxsize),g_Rate[i]);
			}else{
				ShowSyncHudMsg(i,g_syncHud,"[ REC %d (%d byte/s) ]",size,get_pcvar_num(g_CVar_maxsize),g_Rate[i]);
			}
		}else if(is_user_connected(i) && g_isRecording[i] == 0 && g_FileHandler[i] != 0){
			set_hudmessage(255,255,255,-0.9,-0.9,_,_,0.4,0.3,0.3);
			if(g_isPause[i] == 1){
				ShowSyncHudMsg(i,g_syncHud,"[ PAUSE ]^n(%s(%s) on %s@%s %d%% )",g_Rec_Playername[i],g_Rec_Steamid[i],g_Rec_HostName[i],g_Rec_Time[i],(g_Rec_Bytes[i][1]*100)/g_Rec_Bytes[i][0]);
			}else{
				ShowSyncHudMsg(i,g_syncHud,"[ PLAY ]^n%(%s(%s) on %s@%s %d%% )",g_Rec_Playername[i],g_Rec_Steamid[i],g_Rec_HostName[i],g_Rec_Time[i],(g_Rec_Bytes[i][1]*100)/g_Rec_Bytes[i][0]);
			}
		}
	}
}

public fm_ghost_think(id){
	static szClassname[13]
	pev(id,pev_classname, szClassname,12)
	if( !equal(szClassname, "ghost_player") )
		return FMRES_IGNORED;
	static Float:ago,Float:origin[3],Float:angles[3],Float:veloc[3];
	static owner,data,sequence,gaitsequence
	owner = pev(id,pev_owner);
	//check weather paused
	if(g_isPause[owner] == 1 && is_user_connected(owner)){
		//let ghost wait
		set_pev(id,pev_nextthink,get_gametime()+0.5)
		//set velocity (not working for some reason)
		veloc[0] = 0.0
		veloc[1] = 0.0
		veloc[2] = 0.0
		set_pev(id,pev_velocity,veloc)
		return FMRES_IGNORED
	}
	g_Rec_Bytes[owner][1] += 48
	fread(g_FileHandler[owner],_:angles[0],BLOCK_INT)
	fread(g_FileHandler[owner],_:angles[1],BLOCK_INT)
	fread(g_FileHandler[owner],_:angles[2],BLOCK_INT)
	fread(g_FileHandler[owner],_:origin[0],BLOCK_INT)
	fread(g_FileHandler[owner],_:origin[1],BLOCK_INT)
	fread(g_FileHandler[owner],_:origin[2],BLOCK_INT)
	fread(g_FileHandler[owner],_:veloc[0],BLOCK_INT)
	fread(g_FileHandler[owner],_:veloc[1],BLOCK_INT)
	fread(g_FileHandler[owner],_:veloc[2],BLOCK_INT)
	fread(g_FileHandler[owner],sequence,BLOCK_INT)
	fread(g_FileHandler[owner],gaitsequence,BLOCK_INT)
	data = fread(g_FileHandler[owner],_:ago,BLOCK_INT)
	//log_amx("%f (%f %f %f)(%f %f %f)(%f %f %f)%d %d",ago,origin[0],origin[1],origin[2],angles[0],angles[1],angles[2],veloc[0],veloc[1],veloc[2],sequence,gaitsequence)
	if(data != 1){
		if(g_FileHandler[owner] != 0){
			fclose(g_FileHandler[owner])
			g_FileHandler[owner] = 0
		}
		if(g_MenuOpen[owner]){
			menu_show(owner)
		}
		fm_remove_entity(g_GhostWeapon[owner]);
		fm_remove_entity(g_Ghost[owner]);
		if(is_user_connected(owner)){
			client_print(owner,print_chat,"[%s] Playback Finished",PREFIX)
		}else{
			log_amx("removed ghost due to disconnect");
		}
		return FMRES_IGNORED;
	}
	set_pev(id,pev_nextthink,get_gametime()+ago)
	set_pev(id,pev_origin,origin)
	set_pev(id,pev_angles,angles)
	if(get_pcvar_num(g_CVar_igveloc) == 0){
		set_pev(id,pev_velocity,veloc)
	}
	//small bugfix
	if(gaitsequence == 3) gaitsequence = 4
	//dont know why but i have to switch them
	set_pev(id,pev_sequence,gaitsequence)
	set_pev(id,pev_gaitsequence,sequence)
	return FMRES_HANDLED;

}
public start_replay(id){
	log_amx("starting replay")
	if(g_FileHandler[id] != 0){
		client_print(id,print_chat,"[%s] Can't open File, maybe you are still recording",PREFIX)
		return PLUGIN_CONTINUE;
	}
	new fileName[128]
	get_filename(id,g_SaveSlot[id],fileName)
	g_Rec_Bytes[id][0] = filesize(fileName);
	//log_amx(fileName);
	g_FileHandler[id] = fopen(fileName,"rb");
	if(g_FileHandler[id] == 0){
		client_print(id,print_chat,"[%s] Couldn't open file mybe none existent",PREFIX)
	}else{
		client_print(id,print_chat,"[%s] Playback started",PREFIX)
		new version
		fread(g_FileHandler[id],version,BLOCK_INT)
		log_amx("Loading fileversion %d",version)
		switch(version){
			case 24 : {
				new weapon_model[33],model[33],mapname[33],rectime
				fread(g_FileHandler[id],rectime,BLOCK_INT)
				//read username
				for(new i = 0;i < 33;i++){
					fread(g_FileHandler[id],g_Rec_Playername[id][i],BLOCK_CHAR)
				}
				//read steamid
				for(new i = 0;i < 35;i++){
					fread(g_FileHandler[id],g_Rec_Steamid[id][i],BLOCK_CHAR);
				}
				//read mapname not used for now maybe later to do checks
				for(new i = 0;i < sizeof mapname;i++){
					fread(g_FileHandler[id],mapname[i],BLOCK_CHAR);
				}
				//read hostname
				for(new i = 0;i < 33;i++){
					fread(g_FileHandler[id],g_Rec_HostName[id][i],BLOCK_CHAR);
				}
				//read weapon
				for(new i = 0;i < sizeof weapon_model;i++){
					fread(g_FileHandler[id],weapon_model[i],BLOCK_CHAR);
				}
				//read model
				for(new i = 0;i < sizeof model;i++){
					fread(g_FileHandler[id],model[i],BLOCK_CHAR);
				}
				format_time(g_Rec_Time[id],20,"%c",rectime);
				//read the first wait... its useless =)
				fread(g_FileHandler[id],version,BLOCK_INT)
				//log_amx("%d %s %s %s %s %s %s %f",rectime,g_Rec_Playername[id],g_Rec_Steamid[id],mapname,g_Rec_HostName[id],weapon_model,model,version)
				g_Ghost[id] = fnCreateGhost(id,model);
				g_GhostWeapon[id] = fnGhostGiveItem(g_Ghost[id],weapon_model);
				set_Ghost_Rendering(id)
				g_Rec_Bytes[id][1] = 212
			}
			default:{
				g_Ghost[id] = fnCreateGhost(id,"models/player/vip/vip.mdl");
				g_GhostWeapon[id] = fnGhostGiveItem(g_Ghost[id],"models/p_usp.mdl");
				set_Ghost_Rendering(id)
				g_Rec_Bytes[id][1] = 4
			}
		}		
	}
	return PLUGIN_HANDLED
}
public fm_plr_prethink(id){
	if(is_user_alive(id) && g_isRecording[id] != 0){
        if (get_user_team(id) < 1 || get_user_team(id) > 4) {
            stop_recording(id);
            return PLUGIN_HANDLED;
        }
		static Float:ago,Float:origin[3],Float:angles[3],Float:veloc[3],Float:rate;
		static sequence,gaitsequence
		ago = get_gametime()-g_LastThink[id]
		if(ago < RECLIMITER) return FMRES_IGNORED
		rate = floatdiv(1.0,ago)
		rate = floatmul(rate,48.0)
		g_Rate[id] = floatround(rate);
		pev(id,pev_origin,origin)
		pev(id,pev_velocity,veloc)
		pev(id,pev_angles,angles)
		sequence = pev(id,pev_sequence)
		gaitsequence = pev(id,pev_gaitsequence)
		if((g_LastAngle[id][0] == angles[0] && g_LastAngle[id][1] == angles[1] && g_LastAngle[id][2] == angles[2] ) && (g_LastOrigin[id][0] == origin[0] && g_LastOrigin[id][1] == origin[1] && g_LastOrigin[id][2] == origin[2] ) && (g_LastVelocity[id][0] == veloc[0] &&	g_LastVelocity[id][1] == veloc[1] && g_LastVelocity[id][2] == veloc[2])) return FMRES_IGNORED
		g_LastAngle[id][0] = angles[0]
		g_LastAngle[id][1] = angles[1]
		g_LastAngle[id][2] = angles[2]
		g_LastOrigin[id][0] = origin[0]
		g_LastOrigin[id][1] = origin[1]
		g_LastOrigin[id][2] = origin[2]
		g_LastVelocity[id][0] = veloc[0]
		g_LastVelocity[id][1] = veloc[1]
		g_LastVelocity[id][2] = veloc[2]
		g_LastThink[id] = get_gametime()
		fwrite(g_FileHandler[id],_:ago,BLOCK_INT)
		fwrite(g_FileHandler[id],_:angles[0],BLOCK_INT)
		fwrite(g_FileHandler[id],_:angles[1],BLOCK_INT)
		fwrite(g_FileHandler[id],_:angles[2],BLOCK_INT)
		fwrite(g_FileHandler[id],_:origin[0],BLOCK_INT)
		fwrite(g_FileHandler[id],_:origin[1],BLOCK_INT)
		fwrite(g_FileHandler[id],_:origin[2],BLOCK_INT)
		fwrite(g_FileHandler[id],_:veloc[0],BLOCK_INT)
		fwrite(g_FileHandler[id],_:veloc[1],BLOCK_INT)
		fwrite(g_FileHandler[id],_:veloc[2],BLOCK_INT)
		fwrite(g_FileHandler[id],sequence,BLOCK_INT)
		fwrite(g_FileHandler[id],gaitsequence,BLOCK_INT)
		return FMRES_HANDLED
	}
	return FMRES_IGNORED
}

public fnCreateGhost( iOwner ,szModel[]) {
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
		//make sure entity was created successfully
	if (pev_valid(ent)) {
		dllfunc(DLLFunc_Spawn,ent)
		engfunc(EngFunc_SetModel,ent,szModel)
		set_pev(ent, pev_classname, "ghost_player")
		set_pev(ent, pev_solid, SOLID_NOT)
		set_pev(ent,pev_movetype,MOVETYPE_PUSHSTEP)
		set_pev(ent, pev_owner, iOwner)
		set_pev(ent,pev_animtime, 2.0)
		set_pev(ent,pev_framerate, 1.0)
		set_pev(ent,pev_flags, FL_MONSTER)
		set_pev(ent,pev_controller_0, 125)
		set_pev(ent,pev_controller_1, 125)
		set_pev(ent,pev_controller_2, 125)
		set_pev(ent,pev_controller_3, 125)
		set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		return ent;
	}else{
		client_print(iOwner,print_chat,"[%s] Ghost couldn't be created",PREFIX)
		fclose(g_FileHandler[iOwner])
		g_FileHandler[iOwner] = 0
	}
	return 0;
}
public fnGhostGiveItem( iEntity, szModel[] ) {
	new iWeapon = fm_create_entity( "info_target" );
	dllfunc(DLLFunc_Spawn,iWeapon)
	set_pev( iWeapon, pev_classname, "ghost_weapon" );
	set_pev( iWeapon, pev_movetype, MOVETYPE_FOLLOW );
	set_pev( iWeapon, pev_solid, SOLID_NOT );
	set_pev( iWeapon, pev_aiment, iEntity );
	engfunc(EngFunc_SetModel,iWeapon,szModel)
	return iWeapon;
	
}
public set_Ghost_Rendering(id){
	new fx,type
	switch(g_RenderFx[id]){
		case 0:
			fx = kRenderFxNone
		case 1:
			fx = kRenderFxHologram
		case 2:
			fx = kRenderFxGlowShell
	}
	switch(g_RenderType[id]){
		case 0:
			type = kRenderNormal
		case 1:
			type = kRenderTransAlpha
		case 2:
			type = kRenderTransAdd
	}
	fm_set_rendering(g_Ghost[id],fx,g_RenderColors[g_RenderColor[id]][0],g_RenderColors[g_RenderColor[id]][1],g_RenderColors[g_RenderColor[id]][2],type,g_RenderAmount[id]);
	fm_set_rendering(g_GhostWeapon[id],fx,g_RenderColors[g_RenderColor[id]][0],g_RenderColors[g_RenderColor[id]][1],g_RenderColors[g_RenderColor[id]][2],type,g_RenderAmount[id]);
}
public addToFullPack(es, e, ent, host, hostflags, player, pSet)
{
	static szClassname[13]
	if(is_user_connected(host) && pev_valid(ent) && pev(ent,pev_owner) < MAXPLAYERS){
		pev(ent,pev_classname, szClassname,12)
		if(g_Ghost[host] != ent && g_GhostOwnerOnly[pev(ent,pev_owner)] && equali("ghost_player",szClassname))
		{
			set_es(es, ES_Solid, SOLID_NOT)
			set_es(es, ES_RenderFx,kRenderFxNone)
			set_es(es, ES_RenderMode,kRenderTransAlpha)
			set_es(es, ES_RenderAmt, 0)
		}
	}
}

*/