

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
	
	
	new pos[3];
	get_user_origin(id, pos); // Get integer position
	message_begin(MSG_PAS, SVC_TEMPENTITY, pos);
	write_byte(TE_LAVASPLASH);
	write_coord(pos[0]);
	write_coord(pos[1]);
	write_coord(pos[2]);
	message_end();
	
	return PLUGIN_HANDLED
}