#include maps\_utility;
#include common_scripts\utility;

give_player_score( points )
{
	if( level.intermission )
	{
		return;
	}
	if( !maps\_zombiemode_utility::is_player_valid( self ) )
	{
		return;
	}
	points = maps\_zombiemode_utility::round_up_to_ten( points ) * level.zombie_vars["zombie_point_scalar"];
	self.score += points; 
	self.score_total += points;
	//stat tracking
	self.stats["score"] = self.score_total;
	self maps\_zombiemode_score::set_player_score_hud(); 
}

round_wait_override()
{
	printConsole( "round_wait_override()" );
	level notify( "start_of_round" );
	func = getFunction( "maps/_zombiemode", "round_wait" );
	disableDetourOnce( func );
	[[ func ]]();
	if ( isDefined( level._end_of_round_funcs ) && level._end_of_round_funcs.size > 0 )
	{
		for ( i = 0; i < level._end_of_round_funcs.size; i++ )
		{
			level thread [[ level._end_of_round_funcs[ i ] ]]();
		}
	}
	level notify( "end_of_round" );
}

round_spawning_override()
{
	level endon( "intermission" );
/#
	level endon( "kill_round" );
#/

	if( level.intermission )
	{
		return;
	}

	if( level.enemy_spawns.size < 1 )
	{
		ASSERTMSG( "No spawners with targetname zombie_spawner in map." ); 
		return; 
	}

/#
	if ( GetDVarInt( "zombie_cheat" ) == 2 || GetDVarInt( "zombie_cheat" ) >= 4 ) 
	{
		return;
	}
#/

	maps\_zombiemode::ai_calculate_health(); 

	count = 0; 

	//CODER MOD: TOMMY K
	players = get_players();
	for( i = 0; i < players.size; i++ )
	{
		players[i].zombification_time = 0;
	}

	max = level.zombie_vars["zombie_max_ai"];

	multiplier = level.round_number / 5;
	if( multiplier < 1 )
	{
		multiplier = 1;
	}

	// After round 10, exponentially have more AI attack the player
	if( level.round_number >= 10 )
	{
		multiplier *= level.round_number * 0.15;
	}

	player_num = get_players().size;

	if( player_num == 1 )
	{
		max += int( ( 0.5 * level.zombie_vars["zombie_ai_per_player"] ) * multiplier ); 
	}
	else
	{
		max += int( ( ( player_num - 1 ) * level.zombie_vars["zombie_ai_per_player"] ) * multiplier ); 
	}


	
	if(level.round_number < 3 && level.script == "nazi_zombie_asylum")
	{
		if(get_players().size > 1)
		{
			
			max = get_players().size * 3 + level.round_number;

		}
		else
		{

			max = 6;	

		}
	}
	else if ( level.first_round )
	{
		max = int( max * 0.2 );	
	}
	else if (level.round_number < 3)
	{
		max = int( max * 0.4 );
	}
	else if (level.round_number < 4)
	{
		max = int( max * 0.6 );
	}
	else if (level.round_number < 5)
	{
		max = int( max * 0.8 );
	}


	level.zombie_total = max;
	mixed_spawns = 0;	// Number of mixed spawns this round.  Currently means number of dogs in a mixed round

	// DEBUG HACK:	
	//max = 1;
	old_spawn = undefined;
	while( count < max )
	{

		spawn_point = level.enemy_spawns[RandomInt( level.enemy_spawns.size )]; 

		if( !IsDefined( old_spawn ) )
		{
				old_spawn = spawn_point;
		}
		else if( Spawn_point == old_spawn )
		{
				spawn_point = level.enemy_spawns[RandomInt( level.enemy_spawns.size )]; 
		}
		old_spawn = spawn_point;

	//	iPrintLn(spawn_point.targetname + " " + level.zombie_vars["zombie_spawn_delay"]);
		while( maps\_zombiemode_utility::get_enemy_count() > 31 )
		{
			wait( 0.05 );
		}

		// MM Mix in dog spawns...
		if ( isDefined( level._custom_func_table[ "special_dog_spawn" ] ) && IsDefined( level.mixed_rounds_enabled ) && level.mixed_rounds_enabled == 1 )
		{
			spawn_dog = false;
			if ( level.round_number > 30 )
			{
				if ( RandomInt(100) < 3 )
				{
					spawn_dog = true;
				}
			}
			else if ( level.round_number > 25 && mixed_spawns < 3 )
			{
				if ( RandomInt(100) < 2 )
				{
					spawn_dog = true;
				}
			}
			else if ( level.round_number > 20 && mixed_spawns < 2 )
			{
				if ( RandomInt(100) < 2 )
				{
					spawn_dog = true;
				}
			}
			else if ( level.round_number > 15 && mixed_spawns < 1 )
			{
				if ( RandomInt(100) < 1 )
				{
					spawn_dog = true;
				}
			}

			if ( spawn_dog )
			{
				keys = GetArrayKeys( level.zones );
				for ( i=0; i<keys.size; i++ )
				{
					if ( level.zones[ keys[i] ].is_occupied )
					{
						akeys = GetArrayKeys( level.zones[ keys[i] ].adjacent_zones );
						for ( k=0; k<akeys.size; k++ )
						{
							if ( level.zones[ akeys[k] ].is_active &&
								 !level.zones[ akeys[k] ].is_occupied &&
								 level.zones[ akeys[k] ].dog_locations.size > 0 )
							{
								level [[ level._custom_func_table[ "special_dog_spawn" ] ]]( undefined, 1 );
								level.zombie_total--;
								count++;
								wait_network_frame();
							}
						}
					}
				}
				continue;
			}
		}

		ai = maps\_zombiemode_utility::spawn_zombie( spawn_point ); 
		if( IsDefined( ai ) )
		{
			level.zombie_total--;
			ai thread maps\_zombiemode::round_spawn_failsafe();
			count++; 
		}
		wait( level.zombie_vars["zombie_spawn_delay"] ); 
		wait_network_frame();
	}

	if( level.round_number > 3 )
	{
		zombies = getaiarray( "axis" );
		while( zombies.size > 0 )
		{
			if( zombies.size == 1 && zombies[0].has_legs == true )
			{
				var = randomintrange(1, 4);
				zombies[0] set_run_anim( "sprint" + var );                       
				zombies[0].run_combatanim = level.scr_anim[zombies[0].animname]["sprint" + var];
			}
			wait(0.5);
			zombies = getaiarray("axis");
		}

	}

}

nuke_powerup_override( drop_item )
{
	zombies = getaispeciesarray("axis");

	PlayFx( drop_item.fx, drop_item.origin );
	//	players = get_players();
	//	array_thread (players, ::nuke_flash);
	level thread maps\_zombiemode_powerups::nuke_flash();

	

	zombies = get_array_of_closest( drop_item.origin, zombies );

	for (i = 0; i < zombies.size; i++)
	{
		if( !IsDefined( zombies[i] ) )
		{
			continue;
		}
		
		if( zombies[i].animname == "boss_zombie" )
		{
			continue;
		}

		if( isDefined( level._custom_func_table[ "is_magic_bullet_shield_enabled" ] ) && [[ level._custom_func_table[ "is_magic_bullet_shield_enabled" ] ]]( zombies[ i ] ) )
		{
			continue;
		}
		if ( isDefined( level._custom_func_table[ "enemy_is_dog" ] ) )
		{
			if( i < 5 && !( zombies[i] [[ level._custom_func_table[ "enemy_is_dog" ] ]]() ) )
			{
				zombies[i] thread animscripts\death::flame_death_fx();

			}

			if( !( zombies[i] [[ level._custom_func_table[ "enemy_is_dog" ] ]]() ) )
			{
				zombies[i] maps\_zombiemode_spawner::zombie_head_gib();
			}
		}
		else 
		{
			zombies[i] maps\_zombiemode_spawner::zombie_head_gib();
		}
		zombies[i] dodamage( zombies[i].health + 666, zombies[i].origin );
		playsoundatposition( "nuked", zombies[i].origin );
	}

	players = get_players();
	for(i = 0; i < players.size; i++)
	{
		players[i] give_player_score( 400 );
	}

}

spectators_respawn_override()
{
	level endon( "between_round_over" );

	if( !IsDefined( level.zombie_vars["spectators_respawn"] ) || !level.zombie_vars["spectators_respawn"] )
	{
		return;
	}

	if( !IsDefined( level.custom_spawnPlayer ) )
	{
		// Custom spawn call for when they respawn from spectator
		level.custom_spawnPlayer = maps\_zombiemode::spectator_respawn;
		if ( level.script == "nazi_zombie_prototype" )
		{
			level.custom_spawnPlayer = level._custom_func_table[ "spectator_respawn_prototype" ];
		}
	}

	while( 1 )
	{
		players = get_players();
		for( i = 0; i < players.size; i++ )
		{
			if( players[i].sessionstate == "spectator" )
			{
				players[i] [[level.spawnPlayer]]();
				if( isDefined( players[i].has_altmelee ) && players[i].has_altmelee )
				{
					players[i] SetPerk( "specialty_altmelee" );
				}
				if (isDefined(level.script) && players[ i ].score < (level.round_number * 500))
				{
					players[i].old_score = players[i].score;
					players[i].score = level.round_number * 500;
					players[i] maps\_zombiemode_score::set_player_score_hud();
				}
			}
		}

		wait( 1 );
	}
}
