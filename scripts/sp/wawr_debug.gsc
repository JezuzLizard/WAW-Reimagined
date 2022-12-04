#include scripts\sp\wawr_utility;

main()
{
	while ( !isDefined( level.zm_command_init_done ) )
	{
		wait 0.05;
	}
	if ( isDefined( level.tcs_add_server_command_func ) )
	{
		level [[ level.tcs_add_server_command_func ]]( "setround", "setrd str", "setround <number>", ::cmd_setround_f, "cheat", 1, false );
		level [[ level.tcs_add_server_command_func ]]( "prevround", "prevr prr", "prevround", ::cmd_prevround_f, "cheat", 0, false );
		level [[ level.tcs_add_server_command_func ]]( "nextround", "nextr nxr", "nextround", ::cmd_prevround_f, "cheat", 0, false );
		level [[ level.tcs_add_server_command_func ]]( "forcedogwave", "fdw", "forcedogwave", ::cmd_forcedogwave_f, "cheat", 0, false );
		level thread [[ level.tcs_check_cmd_collisions ]]();
	}
	level.wawr_command_init_done = true;
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