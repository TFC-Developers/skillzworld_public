#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <engine>


new g_blocked[ 16 ][ 128 ];
new g_block_count;


public plugin_init() {

    register_plugin( "Block Knockback Plugin", "1.0", "Skillzworld / Vancold.at" );

    g_block_count = 0;

    block_weapon();
    RegisterHam( Ham_TakeDamage, "player", "block_knockback" );
    register_forward( FM_Spawn, "unset_solid", 0);
}


public block_weapon() {

    block_this( "tf_weapon_caltrop" );
    block_this( "tf_weapon_normalgrenade" );
    block_this( "tf_weapon_nailgrenade" );
    block_this( "tf_weapon_mirvgrenade" );
    block_this( "tf_weapon_mirvbomblet" );
    block_this( "detpack" );
    block_this( "tf_gl_grenade" );
    block_this( "tf_gl_pipebomb" );
    block_this( "tf_rpg_rocket" );
    block_this( "tf_flamethrower_burst" );
    block_this( "tf_weapon_napalmgrenade" );
    block_this( "tf_weapon_gasgrenade" );
    block_this( "tf_weapon_empgrenade" );

}


public block_this( classname[] ) {

    copy( g_blocked[ g_block_count ] , 127, classname );
    g_block_count += 1;

}


public block_knockback( victim, inflictorId, attackerId, Float: damage, bitsDamageType ) {

    if( victim != attackerId && should_be_blocked( inflictorId ) ) {
        SetHamParamFloat( 4, 0.0 );
    }

    return HAM_HANDLED;
}


public should_be_blocked( ent ) {

    new classname[ 128 ];
    pev( ent, pev_classname, classname, charsmax( classname ) );

    for( new i = 0; i < g_block_count; i++ ) {

        if( equali( classname, g_blocked[ i ] ) ) {
            return true;
        }

    }

    return false;
}


public unset_solid( toucher, touched ) {

    if( touched != 0 && touched < MAX_PLAYERS + 1 ) {

        if( should_be_blocked( toucher ) ) {
            set_pev( toucher, pev_solid, SOLID_NOT );
        }
    }
}