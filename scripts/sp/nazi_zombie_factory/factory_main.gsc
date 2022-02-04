#include maps\_zombiemode;
#include maps\_zombiemode_tesla;
#include maps\_zombiemode_utility;
#include maps\_utility;
#include common_scripts\utility;

tesla_arc_damage_override( source_enemy, player, arc_num )
{
	player endon( "disconnect" );

	is_upgraded = player getCurrentWeapon() == "tesla_gun_upgraded";
	tesla_flag_hit( self, true );
	wait_network_frame();
	self thread tesla_do_damage( source_enemy, arc_num, player );

	radius_decay = level.zombie_vars["tesla_radius_decay"] * arc_num;
	enemies = tesla_get_enemies_in_area( self GetTagOrigin( "j_head" ), level.zombie_vars["tesla_radius_start"] - radius_decay, player );
	tesla_flag_hit( enemies, true );

	for( i = 0; i < enemies.size; i++ )
	{
		if( enemies[i] == self )
		{
			continue;
		}
		
		if ( tesla_end_arc_damage( arc_num + 1, player.tesla_enemies_hit, is_upgraded ) )
		{			
			tesla_flag_hit( enemies[i], false );
			continue;
		}

		player.tesla_enemies_hit++;
		enemies[i] tesla_arc_damage( self, player, arc_num + 1 );
	}
}

tesla_end_arc_damage_override( arc_num, enemies_hit_num, is_upgraded )
{
	if ( is_upgraded )
	{
		return false;
	}
	if ( arc_num >= level.zombie_vars["tesla_max_arcs"] )
	{
		return true;
		//TO DO Play Super Happy Tesla sound
	}

	if ( enemies_hit_num >= level.zombie_vars["tesla_max_enemies_killed" ] )
	{	
		return true;
	}

	radius_decay = level.zombie_vars["tesla_radius_decay"] * arc_num;
	if ( level.zombie_vars["tesla_radius_start"] - radius_decay <= 0 )
	{
		return true;
	}

	return false;
	//TO DO play Tesla Missed sound (sad)
}

//Added start_of_round and end_of_round notifies.
// round_think_override()
// {
// 	for( ;; )
// 	{
// 		maxreward = 50 * level.round_number;
// 		if ( maxreward > 500 )
// 			maxreward = 500;
// 		level.zombie_vars["rebuild_barrier_cap_per_round"] = maxreward;
// 		level.round_timer = level.zombie_vars["zombie_round_time"]; 
// 		add_later_round_spawners();
// 		chalk_one_up();
// 		maps\_zombiemode_powerups::powerup_round_start();
// 		players = get_players();
// 		array_thread( players, maps\_zombiemode_blockers_new::rebuild_barrier_reward_reset );
// 		level thread award_grenades_for_survivors();
// 		level.round_start_time = getTime();
// 		level thread [[level.round_spawn_func]]();
// 		level notify( "start_of_round" );
// 		round_wait(); 
// 		level notify( "end_of_round" );
// 		level.first_round = false;
// 		level thread spectators_respawn();
// 		level thread chalk_round_hint();
// 		wait( level.zombie_vars["zombie_between_round_time"] ); 
// 			timer = level.zombie_vars["zombie_spawn_delay"];
// 		if( timer < 0.08 )
// 		{
// 			timer = 0.08; 
// 		}	
// 		level.zombie_vars["zombie_spawn_delay"] = timer * 0.95;
// 		level.zombie_move_speed = level.round_number * 8;

// 		level.round_number++;

// 		level notify( "between_round_over" );
// 	}
// }

round_wait_override()
{
	level notify( "start_of_round" );
	func = getFunction( "maps/_zombiemode", "round_wait" );
	disableDetourOnce( func );
	[[ func ]]();
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

	ai_calculate_health(); 

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
		while( get_enemy_count() > 31 )
		{
			wait( 0.05 );
		}

		// MM Mix in dog spawns...
		if ( IsDefined( level.mixed_rounds_enabled ) && level.mixed_rounds_enabled == 1 )
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
								maps\_zombiemode_dogs::special_dog_spawn( undefined, 1 );
								level.zombie_total--;
								wait_network_frame();
							}
						}
					}
				}
				continue;
			}
		}

		ai = spawn_zombie( spawn_point ); 
		if( IsDefined( ai ) )
		{
			level.zombie_total--;
			ai thread round_spawn_failsafe();
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