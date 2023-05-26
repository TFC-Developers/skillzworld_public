#include "include/global"                       // Include file for general functions
#include <engine>
#include <fakemeta>
#include "include/utils"                        // Include file for utility functions
#include "include/effects"

// Sprite Index
new ls_dot, fire, white, sprSmoke, sprLightning, sprBflare, sprRflare, sprGflare, sprTflare, sprOflare, sprPflare, sprYflare, garbgibs, flare3, sprFlare6, shockwave;

public plugin_init()
{
	RegisterPlugin();
	register_think("sw_idle_fireworks","fireworks_think");
	register_think("sw_firework","fireworks_think");

	register_touch("*","sw_firework","fireworks_touch");
	register_touch("*","sw_idle_fireworks","fireworks_touch");

}

public plugin_natives() {
	register_native("api_firework", "HandleFirework");
	register_library("sw_effects");
}


public plugin_precache() {
	precache_sound("weapons/explode3.wav")	
	precache_sound("weapons/explode4.wav")
	precache_sound("weapons/explode5.wav")

	precache_sound("weapons/rocketfire1.wav")
	precache_sound("weapons/mortarhit.wav")
	precache_sound( "ambience/thunder_clap.wav")

	flare3 = precache_model("sprites/flare3.spr")
	garbgibs = precache_model("models/garbagegibs.mdl")
	//l_tube = precache_model("models/w_flare.mdl")

	if (file_exists("sound/fireworks/rocket1.wav")) {
		precache_sound("fireworks/rocket1.wav")
	} else {

	}

	if (file_exists("sound/fireworks/weapondrop1.wav")) {
		precache_sound("fireworks/weapondrop1.wav")

	} else {
		precache_sound("items/weapondrop1.wav")
	}

	precache_model("models/rpgrocket.mdl")
	precache_model("models/w_rpgammo.mdl")

	sprSmoke = precache_model("sprites/smoke.spr")
	sprFlare6 = precache_model("sprites/Flare6.spr")
	sprLightning = precache_model("sprites/lgtning.spr")
	white = precache_model("sprites/white.spr") 
	fire = precache_model("sprites/explode1.spr") 

	sprBflare = precache_model("sprites/fireworks/bflare.spr")
	sprRflare = precache_model("sprites/fireworks/rflare.spr")
	sprGflare = precache_model("sprites/fireworks/gflare.spr")
	sprTflare = precache_model("sprites/fireworks/tflare.spr")
	sprOflare = precache_model("sprites/fireworks/oflare.spr")
	sprPflare = precache_model("sprites/fireworks/pflare.spr")
	sprYflare = precache_model("sprites/fireworks/yflare.spr")
	ls_dot = precache_model("sprites/laserdot.spr")

	precache_sound("fvox/bell.wav");
	shockwave = precache_model("sprites/shockwave.spr")

	return PLUGIN_CONTINUE
}

public HandleFirework(iPlugin, iParams){
    new id = get_param(1);
    new amount = get_param(2);
    if (amount <= 0) amount = 1;
    if (amount >= 3) amount = 3;
    if (is_user_connected(id)) {
        for (new i = 0; i < amount; i++) {
            fireworks_spawn(id,"sw_firework","abcdefsz");
        }
    }
}
public fireworks_cmd(id) {
    fireworks_spawn(id,"sw_firework","abcdefsz");
    return PLUGIN_HANDLED;
}
//fireworks_spawn(id,"sw_firework","abcdefsz",0,0,0)


public fireworks_spawn(id,type[],effects[]) {
	new Float:Origin[3]
	new Float:Angles[3]

	Angles[0] = 90.0
	Angles[1] = random_float(0.0,360.0)
	Angles[2] = 0.0

	pev(id,pev_origin,Origin)

	new Float:Mins[3] = {-4.0, -4.0, -1.0}
	new Float:Maxs[3] = {4.0, 4.0, 12.0}

	new Ent = create_entity("info_target") 
	if (!Ent) return PLUGIN_HANDLED;

	engfunc(EngFunc_SetOrigin,Ent,Origin)
	engfunc(EngFunc_SetSize,Ent,Mins,Maxs)
	engfunc(EngFunc_SetModel,Ent,"models/rpgrocket.mdl")

	entity_set_string(Ent,EV_SZ_classname,"sw_idle_fireworks")
	entity_set_string(Ent,EV_SZ_target,effects)
	entity_set_string(Ent,EV_SZ_targetname,type)
	set_pev(Ent,pev_angles,Angles)
	set_pev(Ent,pev_owner,id)
	set_pev(Ent,pev_solid,3)
	set_pev(Ent,pev_movetype,6)

	dllfunc(DLLFunc_Spawn,Ent)

	new r,g,b;
	r = random_num(0,255)
	g = random_num(0,255)
	b = random_num(0,255)
	
	set_rendering(Ent,kRenderFxGlowShell,r,g,b,kRenderNormal,20)
	set_pev(Ent,pev_iuser2,r)
	set_pev(Ent,pev_iuser3,g)
	set_pev(Ent,pev_iuser4,b)


	emit_sound(Ent, CHAN_WEAPON, "items/weapondrop1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

	entity_set_float(Ent,EV_FL_nextthink,halflife_time() + 5.0)

	new tname[200]
	entity_get_string(Ent,EV_SZ_targetname,tname,199)

	entity_set_string(Ent,EV_SZ_classname,tname)
	set_pev(Ent,pev_effects,64)

	emit_sound(Ent, CHAN_WEAPON, "weapons/rocketfire1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

	emit_sound(Ent, CHAN_VOICE, "fireworks/rocket1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	set_pev(Ent,pev_iuser1, 60)

	set_pev(Ent,pev_movetype,5)

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	{
		write_byte(22)
		write_short(Ent)
		write_short(sprSmoke)
		write_byte(45)
		write_byte(4)
		write_byte(r)
		write_byte(g)
		write_byte(b)
		write_byte(255)
	}
	message_end()

 	new Float:vVelocity[3]
	vVelocity[2] = random_float(400.0,1000.0)
	set_pev(Ent,pev_velocity,vVelocity)

	entity_set_float(Ent,EV_FL_nextthink,halflife_time() + 0.1)

	return PLUGIN_HANDLED
}

public fireworks_think(id){
	new classname[32], owner
	owner = pev(id,pev_owner)
	entity_get_string(id,EV_SZ_classname,classname,31)
	if(equali(classname,"sw_idle_fireworks")){
		set_pev(id,pev_velocity,{0.0,0.0,450.0})
		entity_set_float(id,EV_FL_nextthink,halflife_time() + 5.0)
	}
	else if(equali(classname,"sw_firework")){
		new Float:velo[3]
		pev(id,pev_velocity,velo)

		new Float:x = get_cvar_float("fireworks_xvelocity")
		new Float:y = get_cvar_float("fireworks_yvelocity")
		velo[0] += random_float((-1.0*x),x)
		velo[1] += random_float((-1.0*y),y)
		velo[2] += random_float(10.0,200.0)
		set_pev(id,pev_velocity,velo)
		entity_set_float(id,EV_FL_nextthink,halflife_time() + 0.1)
	}
	
	return 1;
}

public fireworks_touch(tid,id){
	new classname[32]
	entity_get_string(id,EV_SZ_classname,classname,31)

	new Float:origin[3]
	pev(id,pev_origin,origin)

	new r = pev(id,pev_iuser2)
	new g = pev(id,pev_iuser3)
	new b = pev(id,pev_iuser4)

	if(equali(classname,"sw_firework")){
		explode(id)
		remove_entity(id)
	}else if(equali(classname,"sw_idle_fireworks")) emit_sound(id,CHAN_ITEM, "fvox/bell.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

	touch_effect(origin,r,g,b)
	return 1;
}

public touch_effect(Float:Origin[3],r,g,b){
	// blast circles
	new origin[3];
	origin[0] = floatround(Origin[0])
	origin[1] = floatround(Origin[1])
	origin[2] = floatround(Origin[2])

	message_begin( MSG_PAS, SVC_TEMPENTITY, origin );
	write_byte( 21 );
	write_coord( origin[0]);
	write_coord( origin[1]);
	write_coord( origin[2] + 16);
	write_coord( origin[0]);
	write_coord( origin[1]);
	write_coord( origin[2] + 16 + 348); // reach damage radius over .3 seconds
	write_short( shockwave );

	write_byte( 0 ); // startframe
	write_byte( 0 ); // framerate
	write_byte( 3 ); // life
	write_byte( 30 );  // width
	write_byte( 0 );   // noise

	write_byte(r)
	write_byte(g)
	write_byte(b)

	write_byte( 255 ); //brightness
	write_byte( 0 );		// speed
	message_end();

	message_begin( MSG_PAS, SVC_TEMPENTITY, origin );
	write_byte( 21 );
	write_coord( origin[0]);
	write_coord( origin[1]);
	write_coord( origin[2] + 16);
	write_coord( origin[0]);
	write_coord( origin[1]);
	write_coord( origin[2] + 16 + ( 384 / 2 )); // reach damage radius over .3 seconds
	write_short( shockwave );

	write_byte( 0 ); // startframe
	write_byte( 0 ); // framerate
	write_byte( 3 ); // life
	write_byte( 30 );  // width
	write_byte( 0 );   // noise

	write_byte(256-r)
	write_byte(256-g)
	write_byte(256-b)
		
	write_byte( 255 ); //brightness
	write_byte( 0 );		// speed
	message_end();


	return 1;
}

// Explode Function
public explode(id) {
	if(!id) return 0;
	new Float:ent_origin2[3]
	pev(id,pev_origin,ent_origin2)

	new owner
	owner = pev(id,pev_owner)
	
	new ent_origin[3];
	new multi = 2;
	for(new i; i < 3; i++) ent_origin[i] = floatround(ent_origin2[i])

	new szType[64],type
	entity_get_string(id,EV_SZ_target,szType,63)
	type = read_flags(szType)

	new r = pev(id,pev_iuser2)
	new g = pev(id,pev_iuser3)
	new b = pev(id,pev_iuser4)

	if (type&(1<<0)) { //a -- Voogru Effect
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(20) 				// TE_BEAMDISK
		write_coord(ent_origin[0])			// coord coord coord (center position)
		write_coord(ent_origin[1])
		write_coord(ent_origin[2])
		write_coord(0)			// coord coord coord (axis and radius)
		write_coord(0)
		write_coord(100)
		switch(random_num(0,1)) {
			case 0: write_short(sprFlare6)			// short (sprite index)
			case 1: write_short(sprLightning)			// short (sprite index)
		}
		write_byte(0)				// byte (starting frame)
		write_byte(0)				// byte (frame rate in 0.1's)
		write_byte(50)				// byte (life in 0.1's)
		write_byte(0)				// byte (line width in 0.1's)
		write_byte(150)				// byte (noise amplitude in 0.01's)
		write_byte(r)				// byte,byte,byte (color)
		write_byte(g)
		write_byte(b)
		write_byte(255)				// byte (brightness)
		write_byte(0)				// byte (scroll speed in 0.1's)
		message_end()
	}
	if (type&(1<<1)){ //b -- Flares
		if (get_cvar_num("fireworks_colortype")) {
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte(15)				// TE_SPRITETRAIL
			write_coord(ent_origin[0])			// coord, coord, coord (start)
			write_coord(ent_origin[1])
			write_coord(ent_origin[2]-20)
			write_coord(ent_origin[0])			// coord, coord, coord (end)
			write_coord(ent_origin[1])
			write_coord(ent_origin[2]+20)
			if ((r > 128) && (g < 127) && (b < 127)) write_short(sprRflare)
			else if ((r < 127) && (g > 128) && (b < 127)) write_short(sprGflare)
			else if ((r < 127) && (g < 127) && (b > 128)) write_short(sprBflare)
			else if ((r < 127) && (g > 128) && (b > 128)) write_short(sprTflare)
			else if ((r > 128) && (g < 127) && (b < 200) && (b > 100)) write_short(sprPflare)
			else if ((r > 128) && (g > 128) && (b < 127)) write_short(sprYflare)
			else if ((r > 128) && (g > 100) && (g < 200) && (b < 127))write_short(sprOflare)

			else write_short(sprBflare)
			write_byte(get_cvar_num("fireworks_flare_count"))				// byte (count)
			write_byte(10)				// byte (life in 0.1's)
			write_byte(10)				// byte (scale in 0.1's)
			write_byte(random_num(40,100))		// byte (velocity along vector in 10's)
			write_byte(40)				// byte (randomness of velocity in 10's)
			message_end()
		}else{
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte(15)				// TE_SPRITETRAIL
			write_coord(ent_origin[0])			// coord, coord, coord (start)
			write_coord(ent_origin[1])
			write_coord(ent_origin[2]-20)
			write_coord(ent_origin[0])			// coord, coord, coord (end)
			write_coord(ent_origin[1])
			write_coord(ent_origin[2]+20)
			if ((r > 128) && (g < 127) && (b < 127)) write_short(sprRflare)
			else if ((r < 127) && (g > 128) && (b < 127)) write_short(sprGflare)
			else if ((r < 127) && (g < 127) && (b > 128)) write_short(sprBflare)
			else if ((r < 127) && (g > 128) && (b > 128)) write_short(sprTflare)
			else if ((r > 128) && (g < 127) && (b < 200) && (b > 100)) write_short(sprPflare)
			else if ((r > 128) && (g > 128) && (b < 127)) write_short(sprYflare)
			else if ((r > 128) && (g > 100) && (g < 200) && (b < 127))write_short(sprOflare)
			else write_short(sprBflare)

			write_byte(get_cvar_num("fireworks_flare_count"))				// byte (count)
			write_byte(2)				// byte (life in 0.1's)
			write_byte(5)				// byte (scale in 0.1's)
			write_byte(random_num(40,100))		// byte (velocity along vector in 10's)
			write_byte(40)				// byte (randomness of velocity in 10's)
			message_end()
		}
	}
	if (type&(1<<2)) { //c -- Falling flares
		new velo = random_num(30,70)
		new spr
		new choosespr = random_num(0,3) 

		switch(choosespr)
		{
			case 0: spr = flare3
			case 1: spr = sprBflare
			case 2: spr = sprFlare6
			case 3: spr = sprRflare	
		}

		//TE_SPRITETRAIL
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte (15)	// line of moving glow sprites with gravity, fadeout, and collisions
		write_coord(ent_origin[0])			// coord, coord, coord (start)
		write_coord(ent_origin[1])
		write_coord(ent_origin[2])
		write_coord(ent_origin[0])			// coord, coord, coord (start)
		write_coord(ent_origin[1])
		write_coord(ent_origin[2]-80)
		write_short(spr) // (sprite index)
		write_byte(50*multi) // (count)
		write_byte(random_num(1,3)) // (life in 0.1's) 
		write_byte(10) // byte (scale in 0.1's) 
		write_byte(velo) // (velocity along vector in 10's)
		write_byte(40) // (randomness of velocity in 10's)

		message_end()
	}
	if (type&(1<<3)) { //d - lightening
		//Lightning 
		message_begin( MSG_BROADCAST,SVC_TEMPENTITY) 
		write_byte( 0 ) 
		write_coord(ent_origin[0])			// coord, coord, coord (start)
		write_coord(ent_origin[1])
		write_coord(ent_origin[2]-50)
		write_coord(ent_origin[0])			// coord, coord, coord (End)
		write_coord(ent_origin[1])
		write_coord((ent_origin[2]-2000))
		write_short( sprLightning ) 
		write_byte( 1 ) // framestart 
		write_byte( 5 ) // framerate 
		write_byte( 3 ) // life 
		write_byte( 150*multi ) // width 
		write_byte( 30 ) // noise 
		write_byte( 200 ) // r, g, b 
		write_byte( 200 ) // r, g, b 
		write_byte( 200 ) // r, g, b 
		write_byte( 200 ) // brightness 
		write_byte( 100 ) // speed 
		message_end() 

		//Sparks 
		message_begin( MSG_PVS, SVC_TEMPENTITY) 
		write_byte( 9 ) 
		write_coord(ent_origin[0])			// coord, coord, coord (start)
		write_coord(ent_origin[1])
		write_coord((ent_origin[2]-1000))
		message_end() 	
	}
	if (type&(1<<4)) { //e -- Lights
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(27)
		write_coord(ent_origin[0])			// coord, coord, coord (start)
		write_coord(ent_origin[1])
		write_coord(ent_origin[2])
		write_byte(60)			// byte (radius in 10's) 
		write_byte(r)			// byte byte byte (color)
		write_byte(g)
		write_byte(b)
		write_byte(100)			// byte (life in 10's)
		write_byte(15)			// byte (decay rate in 10's)
		message_end()
	}
	if (type&(1<<5)) { //f -- Effect upward
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte( 100 );
		write_coord( ent_origin[0] );
		write_coord( ent_origin[1] );
		write_coord( ent_origin[2] - 64);
		write_short(sprFlare6);
		write_short(1);
		message_end();
	}
	if (type&(1<<6)) { //g -- Throw ents
		new velo = random_num(300,700)

		//define TE_EXPLODEMODEL
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(107) // spherical shower of models, picks from set
		write_coord(ent_origin[0])			// coord, coord, coord (start)
		write_coord(ent_origin[1])
		write_coord(ent_origin[2]-50)
		write_coord(velo) //(velocity)
		write_short (garbgibs) //(model index)
		write_short (25*multi) // (count)
		write_byte (15) // (life in 0.1's)		
		message_end()
	}
	if (type&(1<<7)) { //h
		//TE_TAREXPLOSION
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte( 4) // Quake1 "tarbaby" explosion with sound
		write_coord(ent_origin[0])			// coord, coord, coord (start)
		write_coord(ent_origin[1])
		write_coord((ent_origin[2]-40))
		message_end()
	}
	if (type&(1<<8)) { //i
		new color = random_num(0,255)
		new width = random_num(400,1000)
		//TE_PARTICLEBURST
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(122) // very similar to lavasplash.
		write_coord(ent_origin[0])			// coord, coord, coord (start)
		write_coord(ent_origin[1])
		write_coord(ent_origin[2])
		write_short (width)
		write_byte (color) // (particle color)
		write_byte (40) // (duration * 10) (will be randomized a bit)
		message_end()
	}
	if (type&(1<<9)) { //j...for random...blood
		message_begin( MSG_BROADCAST,SVC_TEMPENTITY) 
		write_byte( 10 ) 
		write_coord(ent_origin[0])			// coord, coord, coord (start)
		write_coord(ent_origin[1])
		write_coord(ent_origin[2])
		message_end() 
	}
	if (type&(1<<10)) { //k
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(14)
		write_coord(ent_origin[0])
		write_coord(ent_origin[1])
		write_coord((ent_origin[2]-100))
		write_byte(5000) // radius
		write_byte(80)
		write_byte(20)
		message_end()
	}
	if (type&(1<<11))  { //l Sprite field
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(123);
		write_coord(ent_origin[0])			// coord, coord, coord (start)
		write_coord(ent_origin[1])
		write_coord(ent_origin[2])
		write_short(256);
		if ((r > 128) && (g < 127) && (b < 127)) write_short(sprRflare)
		else if ((r < 127) && (g > 128) && (b < 127)) write_short(sprGflare)
		else if ((r < 127) && (g < 127) && (b > 128)) write_short(sprBflare)
		else if ((r < 127) && (g > 128) && (b > 128)) write_short(sprTflare)
		else if ((r > 128) && (g < 127) && (b < 200) && (b > 100)) write_short(sprPflare)
		else if ((r > 128) && (g > 128) && (b < 127)) write_short(sprYflare)
		else if ((r > 128) && (g > 100) && (g < 200) && (b < 127))write_short(sprOflare)
		else write_short(sprBflare)
		write_byte(10);
		write_byte(1);
		write_byte(20);
		message_end()
	}
	if (type&(1<<18)) { //s
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(20) 				// TE_BEAMDISK
		write_coord(ent_origin[0])			// coord coord coord (center position)
		write_coord(ent_origin[1])
		write_coord(ent_origin[2])
		write_coord(ent_origin[0])			// coord coord coord (axis and radius)
		write_coord(ent_origin[1])
		write_coord(ent_origin[2]+random_num(250,750))
		switch(random_num(0,1)) {
			case 0: write_short(sprFlare6)			// short (sprite index)
			case 1: write_short(sprLightning)			// short (sprite index)
		}
		write_byte(0)				// byte (starting frame)
		write_byte(0)				// byte (frame rate in 0.1's)
		write_byte(25)				// byte (life in 0.1's)
		write_byte(150)				// byte (line width in 0.1's)
		write_byte(0)				// byte (noise amplitude in 0.01's)
		write_byte(r)				// byte,byte,byte (color)
		write_byte(g)
		write_byte(b)
		write_byte(255)				// byte (brightness)
		write_byte(0)				// byte (scroll speed in 0.1's)
		message_end()
	}
	if (type&(1<<19)) { //t
		message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
		write_byte( 17 )
		write_coord( ent_origin[0] )
		write_coord( ent_origin[1] )
		write_coord( ent_origin[2] )
		write_short( sprSmoke )
		write_byte( 10 )
		write_byte( 150 )
		message_end( )
	}
	if (type&(1<<20)) { //u
		message_begin( MSG_BROADCAST,SVC_TEMPENTITY) 
		write_byte( 21 ) 
		write_coord(ent_origin[0])			// coord, coord, coord (start)
		write_coord(ent_origin[1])
		write_coord(ent_origin[2]-70)
		write_coord(ent_origin[0])			// coord, coord, coord (start)
		write_coord(ent_origin[1])
		write_coord(ent_origin[2]+136)
		write_short( white ) 
		write_byte( 0 ) // startframe 
		write_byte( 0 ) // framerate 
		write_byte( 2 ) // life 2 
		write_byte( 20 ) // width 16 
		write_byte( 0 ) // noise 
		write_byte( 188 ) // r 
		write_byte( 220 ) // g 
		write_byte( 255 ) // b 
		write_byte( 255 ) //brightness 
		write_byte( 0 ) // speed 
		message_end() 

		//Explosion2 
		message_begin( MSG_BROADCAST,SVC_TEMPENTITY) 
		write_byte( 12 ) 
		write_coord(ent_origin[0])			// coord, coord, coord (start)
		write_coord(ent_origin[1])
		write_coord(ent_origin[2])
		write_byte( 188 ) // byte (scale in 0.1's) 188 
		write_byte( 10 ) // byte (framerate) 
		message_end() 

		//TE_Explosion 
		message_begin( MSG_BROADCAST,SVC_TEMPENTITY) 
		write_byte( 3 ) 
		write_coord(ent_origin[0])			// coord, coord, coord (start)
		write_coord(ent_origin[1])
		write_coord(ent_origin[2])
		write_short( fire ) 
		write_byte( 60 ) // byte (scale in 0.1's) 188 
		write_byte( 10 ) // byte (framerate) 
		write_byte( 0 ) // byte flags 
		message_end() 

		//Smoke 
		message_begin( MSG_BROADCAST,SVC_TEMPENTITY) 
		write_byte( 5 ) // 5 
		write_coord(ent_origin[0])			// coord, coord, coord (start)
		write_coord(ent_origin[1])
		write_coord(ent_origin[2])
		write_short( sprSmoke ) 
		write_byte( 10 ) // 2 
		write_byte( 10 ) // 10 
		message_end() 
	}

	if (type&(1<<21)) emit_sound(id,CHAN_ITEM, "ambience/thunder_clap.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)//v
	if (type&(1<<22)) emit_sound(id, CHAN_VOICE, "weapons/explode3.wav", 1.0, ATTN_NORM, 0, PITCH_NORM) // w
	if (type&(1<<23)) emit_sound(id, CHAN_VOICE, "weapons/explode4.wav", 1.0, ATTN_NORM, 0, PITCH_NORM) //x
	if (type&(1<<24)) emit_sound(id, CHAN_VOICE, "weapons/explode5.wav", 1.0, ATTN_NORM, 0, PITCH_NORM) //y
	if (type&(1<<25)) emit_sound(id, CHAN_VOICE, "weapons/mortarhit.wav", 1.0, ATTN_NORM, 0, PITCH_NORM) //z

	return 1;
}
