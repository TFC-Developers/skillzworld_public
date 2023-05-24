

//description: Teleport player to given location
stock stock_teleport(id, Float:origin[3]) {
	new Float:foldOrigin[3];
	pev(id, pev_origin, foldOrigin);
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_TELEPORT);
	write_coord(floatround(foldOrigin[0]));
	write_coord(floatround(foldOrigin[1]));
	write_coord(floatround(foldOrigin[2]));
	message_end();
	
	set_pev(id, pev_origin, origin);
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_TELEPORT);
	write_coord(floatround(origin[0]));
	write_coord(floatround(origin[1]));
	write_coord(floatround(origin[2]));
	message_end();
}

public stock_slay(id) {
	if(!is_user_connected(id)) return PLUGIN_HANDLED
	
	new Float:origin[3]
	pev(id,pev_origin,origin) //get the origin of the player
	
	new entity = create_entity("trigger_hurt")
	entity_set_origin(entity, origin)
	//add the flag SF_NORESPAWN so the entity will be removed after it has been used
	set_pev(entity, pev_spawnflags, pev(entity, pev_spawnflags) | SF_NORESPAWN);
	// this will set the damage of the entity to 1000
	entity_set_float(entity, EV_FL_dmg, 1000.0);
	// this will set the classname of the entity to slayskills
	entity_set_string(entity, EV_SZ_classname, "slayskills");
	DispatchSpawn(entity);
	
	
	// this will deal the damage to the player
	fake_touch(entity, id)
	
	//emit the sound to all players
	emit_sound(id, CHAN_AUTO, "ambience/thunder_clap.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
	
	// this will remove the godmode from the player in case he has it
	entity_set_float(id, EV_FL_takedamage, 0.0);
	
	
	new pos[3]; get_user_origin(id, pos); // Get integer position
	message_begin(MSG_PAS, SVC_TEMPENTITY, pos);
	{
		write_byte(TE_LAVASPLASH);
		write_coord(pos[0]);
		write_coord(pos[1]);
		write_coord(pos[2]);
	}
	message_end();
	
	return PLUGIN_HANDLED
}

stock CreateTeleportEffect(id, model_index)
{
	new origin[3]; get_user_origin(id, origin) // Integer player position
	message_begin(MSG_ONE,105,{0,0,0}, id);
	{
		write_short(1 << 10);
		write_short(1 << 10);
		write_short(1 << 1);
		write_byte(0);
		write_byte(0);
		write_byte(255);
		write_byte(255);
	}
	message_end();

	message_begin(MSG_PAS, SVC_TEMPENTITY, origin);
	{
		write_byte(TE_BEAMTORUS);
		write_coord(origin[0]);
		write_coord(origin[1]);
		write_coord(origin[2]);
		write_coord(origin[0]);
		write_coord(origin[1]);
		write_coord(origin[2] + floatround(floatdiv(floatmul(random_float(50.0, 80.0), 2.0), 0.2))); // reach damage radius over .3 seconds
		write_short(model_index);
		write_byte(0); // startframe
		write_byte(1); // framerate
		write_byte(2); // life
		write_byte(random_num(30, 150)); // width
		write_byte(0); // noise	
		write_byte(random_num(50, 255)); // r
		write_byte(random_num(50, 255)); // g
		write_byte(random_num(50, 255)); // b
		write_byte(255); // brightness
		write_byte(0); // speed
	}
	message_end();
}
stock send_motd(id, const sFormat[], any:...) {
	new iMsgID = get_user_msgid("MOTD");

	if (iMsgID == 0) {
		DebugPrintLevel(0,"MOTD message not found");
		return;
	}
	new szMessage[256];
	vformat(szMessage, charsmax(szMessage), sFormat, 3)

	message_begin(MSG_ONE, iMsgID, .player = id);
	{
		write_byte(false);
		write_string(szMessage);
	}
	message_end();

}

stock display_motd(id, const sFormat[], any:...) {
	new iMsgID = get_user_msgid("MOTD");
	new iMsgIDServer = get_user_msgid("ServerName");
	new szHostname[63]; get_cvar_string("hostname",szHostname,63);
	new szMessage[256];

	if (iMsgID == 0 || iMsgIDServer == 0) {
		DebugPrintLevel(0,"MOTD message not found");
		return;
	}

	vformat(szMessage, charsmax(szMessage), sFormat, 3)
	if (strlen(szMessage) >= 2) {
		message_begin(MSG_ONE, iMsgIDServer, .player = id);
		write_string(szMessage);
		message_end();
	}

	message_begin(MSG_ONE, iMsgID, .player = id);
	write_byte(true);
	write_string("");
	message_end();

	if (strlen(szMessage) >= 2) {
		message_begin(MSG_ONE, iMsgIDServer, .player = id);
		write_string(szHostname);
		message_end();
	}
}

stock format_seconds(target[], Float:s, target_sz = sizeof target) {
	target_sz -= 1 // As charsmax
	new iTotalSeconds = floatround(s)      ; new iSeconds = iTotalSeconds % 60
	new iTotalMinutes = iTotalSeconds / 60 ; new iMinutes = iTotalMinutes % 60
	new iTotalHours   = iTotalMinutes / 60 ; new iHours = iTotalHours % 24
	new iTotalDays    = iTotalHours   / 24 ; new iDays = iTotalDays % 7
	new iWeeks        = iTotalDays / 7
	new write_i = 0
	if (iWeeks) {
		if (iWeeks == 1) formatex target[write_i], target_sz, "1 week, "
		else              formatex target[write_i], target_sz, "%d weeks, ", iWeeks
		write_i += strlen(target[write_i]); target_sz -= write_i
	}
	if (iDays) {
		if (iDays == 1) formatex target[write_i], target_sz, "1 day, "
		else             formatex target[write_i], target_sz, "%d days, ", iDays % 7
		write_i += strlen(target[write_i]); target_sz -= write_i
	}
	if (iHours) {
		if (iHours == 1) formatex target[write_i], target_sz, "1 hour, "
		else              formatex target[write_i], target_sz, "%d hours, ", iHours % 60
		write_i += strlen(target[write_i]); target_sz -= write_i
	}
	if (iMinutes) {
		if (iMinutes == 1) formatex target[write_i], target_sz, "1 minute, "
		else                formatex target[write_i], target_sz, "%d minutes, ", iMinutes % 60
		write_i += strlen(target[write_i]); target_sz -= write_i
	}
	if (iSeconds || !write_i) { // Any seconds, or nothing at all else was written
		if (iSeconds == 1) formatex target[write_i], target_sz, "1 second"
		else                formatex target[write_i], target_sz, "%d seconds", iSeconds % 60
	} else if (write_i) /* Something else was written, so remove comma */ target[write_i - 2] = EOS
}

public plugin_init() {
	new Squanch[0x100]
	format_seconds Squanch, 5340.0; console_print 0, Squanch
	format_seconds Squanch, 13080.0; console_print 0, Squanch
	format_seconds Squanch, 604800.0; console_print 0, Squanch
	format_seconds Squanch, 3600.0; console_print 0, Squanch
}

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang2057\\ f0\\ fs16 \n\\ par }
*/
