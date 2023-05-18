

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
	write_coord_f(pos[0]);
	write_coord_f(pos[1]);
	write_coord_f(pos[2]);
	message_end();
	
	return PLUGIN_HANDLED
}


public FixedSigned16(value, scale)
{
    new output;
    
    // Convert to fixed point number and scale.
    // Multiply by 1000 assuming you're passing decimal numbers.
    output = floatround(value * 1000.0 * scale);
    
    if (output > 32767000)  // 32767 in fixed point format.
        output = 32767000;
        
    if (output < -32768000)  // -32768 in fixed point format.
        output = -32768000;
    
    // If you want to convert back to float before returning:
    return output / 1000.0;
}

stock FixedUnsigned16(value, scale)
{
    new output;
    
    output = floatround(value * 1000.0 * scale);
    
    if (output < 0)
        output = 0;
        
    if (output > 65535000)  // 0xFFFF in fixed point format
        output = 65535000;
    
    // If you want to convert back to float before returning:
    return output / 1000.0;
}

stock CreateTeleportEffect(id, model_index)
{
    // Player position
    new Float:origin[3];
    pev(id, pev_origin, origin);


	message_begin(MSG_ONE,105,{0,0,0}, id);
	write_short(1 << 10);
	write_short(1 << 10);
	write_short(1 << 1);
	write_byte(0);
	write_byte(0);
	write_byte(255);
	write_byte(255);
	message_end();

	message_begin(MSG_PAS, SVC_TEMPENTITY, origin);
	write_byte(TE_BEAMTORUS);
	write_coord_f(origin[0]);
	write_coord_f(origin[1]);
	write_coord_f(origin[2]);
	write_coord_f(origin[0]);
	write_coord_f(origin[1]);
	write_coord_f(origin[2] + random_float(50.0, 80.0) * 2.0 / 0.2); // reach damage radius over .3 seconds
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
	message_end();
}