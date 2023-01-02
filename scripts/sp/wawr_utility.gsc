struct_class_init_override()
{
	assertEx( !isdefined( level.struct_class_names ), "level.struct_class_names is being initialized in the wrong place! It shouldn't be initialized yet." );
	
	level.struct_class_names = [];
	level.struct_class_names[ "target" ] = [];
	level.struct_class_names[ "targetname" ] = [];
	level.struct_class_names[ "script_noteworthy" ] = [];
	level.struct_class_names[ "script_linkname" ] = [];
	
	for ( i=0; i < level.struct.size; i++ )
	{
		add_struct( level.struct[ i ] );
	}
	if ( !isDefined( level._custom_structs ) || level._custom_structs.size < 1 )
	{
		return;
	}
	for ( i = 0; i < level._custom_structs; i++ )
	{
		add_struct( level._custom_structs[ i ] );
	}
}

add_struct( s_struct )
{
	if ( isDefined( s_struct.targetname ) )
	{
		if ( !isDefined( level.struct_class_names[ "targetname" ][ s_struct.targetname ] ) )
		{
			level.struct_class_names[ "targetname" ][ s_struct.targetname ] = [];
		}
		size = level.struct_class_names[ "targetname" ][ s_struct.targetname ].size;
		level.struct_class_names[ "targetname" ][ s_struct.targetname ][ size ] = s_struct;
	}
	if ( isDefined( s_struct.script_noteworthy ) )
	{
		if ( !isDefined( level.struct_class_names[ "script_noteworthy" ][ s_struct.script_noteworthy ] ) )
		{
			level.struct_class_names[ "script_noteworthy" ][ s_struct.script_noteworthy ] = [];
		}
		size = level.struct_class_names[ "script_noteworthy" ][ s_struct.script_noteworthy ].size;
		level.struct_class_names[ "script_noteworthy" ][ s_struct.script_noteworthy ][ size ] = s_struct;
	}
	if ( isDefined( s_struct.target ) )
	{
		if ( !isDefined( level.struct_class_names[ "target" ][ s_struct.target ] ) )
		{
			level.struct_class_names[ "target" ][ s_struct.target ] = [];
		}
		size = level.struct_class_names[ "target" ][ s_struct.target ].size;
		level.struct_class_names[ "target" ][ s_struct.target ][ size ] = s_struct;
	}
	if ( isDefined( s_struct.script_linkname ) )
	{
		level.struct_class_names[ "script_linkname" ][ s_struct.script_linkname ][ 0 ] = s_struct;
	}
}

register_perk_struct( name, model, origin, angles )
{
	perk_struct = spawnStruct();
	perk_struct.script_noteworthy = name;
	perk_struct.model = model;
	perk_struct.angles = angles;
	perk_struct.origin = origin;
	perk_struct.targetname = "zm_perk_machine";

	if ( name == "specialty_weapupgrade" )
	{
		flag_struct = spawnStruct();
		flag_struct.targetname = "weapupgrade_flag_targ";
		flag_struct.model = "zombie_sign_please_wait";
		flag_struct.angles = angles + ( 0, 180, 180 );
		flag_struct.origin = origin + ( anglesToForward( angles ) * 29 ) + ( anglesToRight( angles ) * -13.5 ) + ( anglesToUp( angles ) * 49.5 );
		perk_struct.target = flag_struct.targetname;
		add_struct( flag_struct );
	}

	add_struct( perk_struct );
}

cast_bool_to_str( bool, binary_string_options )
{
	options = strTok( binary_string_options, " " );
	if ( options.size == 2 )
	{
		if ( bool )
		{
			return options[ 0 ];
		}
		else 
		{
			return options[ 1 ];
		}
	}
	return bool + "";
}

kill_round()
{
	level notify( "debug_kill_round" );
	level.zombie_total = 0;
	ais = getAiSpeciesArray( "axis", "all" );
	for ( i = 0; i < ais.size; i++ )
	{
		zombie = ais[ i ];
		if ( isdefined( zombie ) )
		{
			zombie dodamage( zombie.health + 100, (0,0,0) );
		}
	}
}

set_zombie_spawn_rate_for_round( round_number )
{
	if ( !isDefined( level.starting_zombie_spawn_delay ) )
	{
		level.starting_zombie_spawn_delay = level.zombie_vars[ "zombie_spawn_delay" ];
	}
	timer = level.starting_zombie_spawn_delay;
	for ( i = 1; i <= round_number; i++ )
	{
		if ( timer > 0.08 )
		{
			timer = timer * 0.95;
			continue;
		}

		if ( timer < 0.08 )
		{
			timer = 0.08;
			break;
		}
	}
	level.zombie_vars[ "zombie_spawn_delay" ] = timer;
	if ( isDefined( level.zombie_spawnrate_bonus_func ) )
	{
		level [[ level.zombie_spawnrate_bonus_func ]]();
	}
}

set_zombie_move_speed_for_round( round_number )
{
	if ( round_number <= 1 )
	{
		level.zombie_move_speed = 1;
	}
	else 
	{
		level.zombie_move_speed = round_number * 8;
	}
	if ( isDefined( level.zombie_movespeed_bonus_func ) )
	{
		level [[ level.zombie_movespeed_bonus_func ]]();
	}
}

set_zombie_health_for_round( round_number )
{
	level.zombie_health = level.zombie_vars["zombie_health_start"];
	for ( i = 2; i <= round_number; i++ )
	{
		if ( i >= 10 )
			level.zombie_health += int( level.zombie_health * level.zombie_vars["zombie_health_increase_percent"] );
		else
			level.zombie_health = int( level.zombie_health + level.zombie_vars["zombie_health_increase"] );
	}
	if ( isDefined( level.zombie_health_bonus_func ) )
	{
		level [[ level.zombie_health_bonus_func ]]();
	}
}

register_weapon_actor_damage_callback( weapon, callback )
{
	if ( !isDefined( level.weapon_actor_damage_callbacks ) )
	{
		level.weapon_actor_damage_callbacks = [];
	}
	level.weapon_actor_damage_callbacks[ weapon ] = callback;
}

is_true( value )
{
	return isDefined( value ) && value;
}