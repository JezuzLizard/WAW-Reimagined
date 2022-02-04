#include maps\_zombiemode_utility;
#include maps\_utility;
#include common_scripts\utility;

main()
{
	replaceFunc( maps\_zombiemode_utility::spawn_zombie, ::spawn_zombie_override );
}

init()
{
	level.zombie_counter_zombies = 0;
	SetDvar( "player_lastStandBleedoutTime", 45 );
	level thread enemy_counter_hud();
	level thread track_round_enemies();
	level thread calculate_sph();
	level thread sph_hud();
	level.sph_hud_counter = 0;
	level.zombie_kill_times = [];
}

spawn_zombie_override( spawner, target_name ) 
{ 
	spawner.script_moveoverride = true; 

	if( IsDefined( spawner.script_forcespawn ) && spawner.script_forcespawn ) 
	{ 
		guy = spawner StalingradSpawn();  
	} 
	else 
	{ 
		guy = spawner DoSpawn();  
	} 

	spawner.count = 666; 

//	// sometimes we want to ensure a zombie will go to a particular door node
//	// so we target the spawner at a struct and put the struct near the entry point
//	if( isdefined( spawner.target ) )
//	{
//		guy.forced_entry = getstruct( spawner.target, "targetname" ); 
//	}

	if( !spawn_failed( guy ) ) 
	{ 
		if( IsDefined( target_name ) ) 
		{ 
			guy.targetname = target_name; 
		} 
		guy thread zombie_death();
		return guy;  
	}

	return undefined;  
}

zombie_death()
{
	self waittill( "death" );
	level.zombie_counter_zombies--;
	level.zombie_kill_times[ getTime() + "" ] = true;
}

enemy_counter_hud()
{
	enemy_counter_hud = newHudElem();
	enemy_counter_hud.alignx = "left";
	enemy_counter_hud.aligny = "top";
	enemy_counter_hud.horzalign = "user_left";
	enemy_counter_hud.vertalign = "user_top";
	enemy_counter_hud.x += 5;
	enemy_counter_hud.y += 2;
	enemy_counter_hud.fontscale = 1.4;
	enemy_counter_hud.alpha = 0;
	enemy_counter_hud.color = ( 1, 1, 1 );
	enemy_counter_hud.hidewheninmenu = 1;
	enemy_counter_hud.label = "Enemies Remaining: ";

	flag_wait( "all_players_connected" );
	wait 10;
	enemy_counter_hud.alpha = 1;
	while (1)
	{
		while ( !is_round_ongoing() )
		{
			enemy_counter_hud.alpha = 0;
			wait 1;
		}
		enemy_counter_hud.alpha = 1;
		enemies = level.zombie_counter_zombies;
		enemy_counter_hud setValue( enemies );
		wait 0.05;
	}
}

is_round_ongoing()
{
	return ( get_enemy_count() + level.zombie_total ) > 0;
}

track_round_enemies()
{
	flag_wait( "all_players_connected" );
	wait 10;

	while ( true )
	{
		while ( !is_round_ongoing() )
		{
			wait 1;
		} 
		level.zombie_counter_zombies = level.zombie_total;
		level.zombie_starting_total = level.zombie_total;
		while ( is_round_ongoing() )
		{
			wait 1;
		}
	}
}

sph_hud()
{
	enemy_counter_hud = newHudElem();
	enemy_counter_hud.alignx = "left";
	enemy_counter_hud.aligny = "top";
	enemy_counter_hud.horzalign = "user_left";
	enemy_counter_hud.vertalign = "user_top";
	enemy_counter_hud.x += 5;
	enemy_counter_hud.y += 12;
	enemy_counter_hud.fontscale = 1.4;
	enemy_counter_hud.alpha = 0;
	enemy_counter_hud.color = ( 1, 1, 1 );
	enemy_counter_hud.hidewheninmenu = 1;
	enemy_counter_hud.label = "SPH: ";

	flag_wait( "all_players_connected" );
	wait 10;
	enemy_counter_hud.alpha = 1;
	while (1)
	{
		while ( !is_round_ongoing() || level.sph_hud_counter == 0 )
		{
			enemy_counter_hud.alpha = 0;
			wait 1;
		}
		enemy_counter_hud.alpha = 1;
		enemy_counter_hud setValue( level.sph_hud_counter );
		wait 0.05;
	}
}

calculate_sph()
{
	flag_wait( "all_players_connected" );
	wait 10;

	while ( true )
	{
		wait 0.05;
		kill_times = getArrayKeys( level.zombie_kill_times );
		now = getTime();
		kills_this_minute = 0;
		for ( i = 0; i < kill_times.size; i++ )
		{
			kill_time = kill_times[ i ];
			if ( ( now - int( kill_time ) ) > 60000 )
			{
				level.zombie_kill_times[ kill_time ] = undefined;
				continue;
			}
			kills_this_minute++;
		}
		if ( kills_this_minute > 0 )
		{
			hordes_per_minute = kills_this_minute / 24;
			hordes_per_second = hordes_per_minute / 60;
			seconds_per_horde = 1 / hordes_per_second;
			level.sph_hud_counter = seconds_per_horde;
		}
		else 
		{
			level.sph_hud_counter = 0;
		}
	}
}