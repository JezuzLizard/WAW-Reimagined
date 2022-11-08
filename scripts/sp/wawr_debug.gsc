main()
{
	while ( !isDefined( level.zm_command_init_done ) )
	{
		wait 0.05;
	}
	if ( isDefined( level.tcs_add_server_command_func ) )
	{
		level [[ level.tcs_add_server_command_func ]]( "setround", "setround setrd str", "setround <number>", ::cmd_setround_f, level.cmd_power_cheat, 1 );
		level [[ level.tcs_add_server_command_func ]]( "prevround", "prevround prevr prr", "prevround", ::cmd_prevround_f, level.cmd_power_cheat, 0 );
		level [[ level.tcs_add_server_command_func ]]( "nextround", "nextround nextr nxr", "nextround", ::cmd_prevround_f, level.cmd_power_cheat, 0 );
		level [[ level.tcs_add_server_command_func ]]( "forcedogwave", "forcedogwave fdw", "forcedogwave", ::cmd_forcedogwave_f, level.cmd_power_cheat, 0 );
		level thread [[ level.tcs_check_cmd_collisions ]]();
	}
	level.wawr_command_init_done = true;
}

kill_round()
{
	level notify( "debug_kill_round" );
	level.zombie_total = 0;
	ais = getAiArray( "axis" );
	for ( i = 0; i < ais.size; i++ )
	{
		zombie = ais[ i ];
		if ( isdefined( zombie ) )
		{
			zombie dodamage( zombie.health + 100, (0,0,0) );
		}
	}
	ais = getAiSpeciesArray( "axis", "dog" );
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
		level.starting_zombie_spawn_delay = 2;
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
	level.zombie_vars["zombie_spawn_delay"] = timer;
}

set_zombie_move_speed_for_round( round_number )
{
	level.zombie_move_speed = round_number * 8;
}

set_zombie_health_for_round( round_number )
{
	level.zombie_health = level.zombie_vars["zombie_health_start"];
	for ( i = 2; i <= round_number; i++ )
	{
		if ( i >= 10 )
		{
			level.zombie_health += int( level.zombie_health * level.zombie_vars["zombie_health_increase_percent"] );
		}
		else
			level.zombie_health = int( level.zombie_health + level.zombie_vars["zombie_health_increase"] );
	}
}

set_zombies_stats_for_round( round_number )
{
	set_zombie_spawn_rate_for_round( round_number );
	set_zombie_move_speed_for_round( round_number );
	set_zombie_health_for_round( round_number );
}

cmd_setround_f( arg_list )
{
	result = [];
	if ( !isDefined( arg_list ) || arg_list.size <= 0 )
	{
		result[ "filter" ] = "cmderror";
		result[ "message" ] = "Usage: setround <number>";
		return result;
	}
	round_number = int( arg_list[ 0 ] );
	if ( round_number <= 0 )
	{
		result[ "filter" ] = "cmderror";
		result[ "message" ] = "Invalid value";
		return result;
	}
	kill_round();
	level.round_number = round_number - 1; //-1 because the game will increment it anyway
	set_zombies_stats_for_round( level.round_number );
	result[ "filter" ] = "cmdinfo";
	result[ "message" ] = "Successfully set the round to " + round_number;
	return result;
}

cmd_prevround_f( arg_list )
{
	result = [];
	kill_round();
	level.round_number = level.round_number - 2; //-2 because the game will increment it anyway
	set_zombies_stats_for_round( level.round_number );
	result[ "filter" ] = "cmdinfo";
	result[ "message" ] = "Successfully set the round to " + ( level.round_number + 1 );
	return result;	
}

cmd_nextround_f( arg_list )
{
	result = [];
	kill_round();
	round_number = level.round_number;
	set_zombies_stats_for_round( round_number );
	result[ "filter" ] = "cmdinfo";
	result[ "message" ] = "Successfully set the round to " + ( round_number + 1 );
	return result;	
}

cmd_forcedogwave_f( arg_list )
{
	result = [];
	level.force_dog_wave = true;
	result[ "filter" ] = "cmdinfo";
	result[ "message" ] = "Forcing dog wave";
}