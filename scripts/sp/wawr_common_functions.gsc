#include maps\_utility;
#include common_scripts\utility;
#include scripts\sp\wawr_utility;


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

	level endon( "end_of_round" );

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

	//CODER MOD: TOMMY K
	players = getPlayers();
	for( i = 0; i < players.size; i++ )
	{
		players[i].zombification_time = 0;
	}

	level.round_start_time = getTime();

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
	player_num = getPlayers().size;
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
		if(player_num > 1)
		{
			
			max = player_num * 3 + level.round_number;

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
	old_spawn = undefined;

	can_spawn_dogs = isDefined( level._custom_func_table[ "special_dog_spawn" ] ) && IsDefined( level.mixed_rounds_enabled ) && level.mixed_rounds_enabled == 1 && level.round_number > 16;
	chance_of_dog_wave = 0;
	should_spawn_guaranteed_dog_wave = false;
	guaranteed_dog_wave_time = level.round_start_time;
	dog_wave_count = 0;
	while ( true )
	{
		while( maps\_zombiemode_utility::get_enemy_count() >= 24 || level.zombie_total <= 0 )
		{
			wait( 0.05 );
		}

		chance_of_dog_wave += randomInt( 10 );

		should_spawn_dog_wave_random = chance_of_dog_wave >= 1000;
		should_spawn_guaranteed_dog_wave = ( ( guaranteed_dog_wave_time + 80000 ) <= getTime() );
		if ( can_spawn_dogs && ( should_spawn_dog_wave_random || should_spawn_guaranteed_dog_wave ) ) 
		{
			players = getPlayers();
			max_dogs_in_wave = 12;
			if ( players.size == 1 )
			{
				max_dogs_in_wave = 6;
			}
			while ( maps\_zombiemode_utility::get_enemy_count() > ( 24 - max_dogs_in_wave ) )
			{
				wait 0.5;
			}
			players = getPlayers();
			spawned_dog_count = 0;
			max_dogs_in_wave = min( level.zombie_total, max_dogs_in_wave );
			while ( spawned_dog_count < max_dogs_in_wave )
			{
				dog_spawn_success = level [[ level._custom_func_table[ "special_dog_spawn" ] ]]( undefined, 1 );
				if ( dog_spawn_success )
				{
					spawned_dog_count++;
				}
				wait( level.zombie_vars["zombie_spawn_delay"] ); 
			}
			players = getPlayers();
			logPrint( "round_spawning() event: dog wave playercount: " + players.size + "  round: " + level.round_number + " count: " + dog_wave_count + " random: " + cast_bool_to_str( should_spawn_dog_wave_random, "yes no" ) + " time: " + cast_bool_to_str( should_spawn_guaranteed_dog_wave, "yes no" ) );
			dog_wave_count++;
			guaranteed_dog_wave_time = getTime() + ( 80000 * dog_wave_count );
			chance_of_dog_wave = 0;
			wait( level.zombie_vars["zombie_spawn_delay"] ); 
			continue;
		}

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

		ai = maps\_zombiemode_utility::spawn_zombie( spawn_point ); 
		if( IsDefined( ai ) )
		{
			level.zombie_total--;
			ai thread maps\_zombiemode::round_spawn_failsafe();
		}
		wait( level.zombie_vars["zombie_spawn_delay"] ); 
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
	//	players = getPlayers();
	//	array_thread (players, ::nuke_flash);
	level thread maps\_zombiemode_powerups::nuke_flash();

	

	zombies = get_array_of_closest( drop_item.origin, zombies );
	xp_value = 0;
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
		xp_value++;
	}
	if ( !isdefined( level.flag[ "dog_round" ] ) || !flag( "dog_round" ) )
	{
		new_zombie_total = level.zombie_total - 24;
		if ( new_zombie_total < 0 )
		{
			new_zombie_total = 0;
		}
		level.zombie_total = new_zombie_total;
	}
	players = getPlayers();
	for(i = 0; i < players.size; i++)
	{
		players[i] give_player_score( 400 );
		if ( isDefined( level._custom_func_table[ "giveRankXP" ] ) )
		{
			players[ i ] [[ level._custom_func_table[ "giveRankXP" ] ]]( "nuke_kill", xp_value );
		}
	}
}

full_ammo_powerup_override( drop_item )
{
	players = getPlayers();

	for (i = 0; i < players.size; i++)
	{
		primaryWeapons = players[i] GetWeaponsListPrimaries(); 
		for( x = 0; x < primaryWeapons.size; x++ )
		{
			clipsize = weaponClipSize( primaryWeapons[ x ] );
			players[ i ] setWeaponAmmoClip( primaryWeapons[ x ], clipsize );
		}
		allweapons = players[ i ] getWeaponsList();
		for( x = 0; x < allweapons.size; x++ )
		{
			players[ i ] GiveMaxAmmo( allweapons[ x ] );
		}
	}
	//	array_thread (players, ::full_ammo_on_hud, drop_item);
	level thread maps\_zombiemode_powerups::full_ammo_on_hud( drop_item );
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
		players = getPlayers();
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

waiting_for_next_dog_spawn_override( count, max )
{
	if ( !flag( "dog_round" ) )
	{
		return;
	}

	default_wait = 1.5;

	if( level.dog_round_count == 1)
	{
		default_wait = 3;
	}
	else if( level.dog_round_count == 2)
	{
		default_wait = 2.5;
	}
	else if( level.dog_round_count == 3)
	{
		default_wait = 2;
	}
	else 
	{
		default_wait = 1.5;
	}

	default_wait = default_wait - ( count / max );

	wait( default_wait );

}
