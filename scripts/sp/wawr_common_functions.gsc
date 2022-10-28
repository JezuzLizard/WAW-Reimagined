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

door_think_pre_factory_override()
{

	// maybe the door the should just bust open instead of slowly opening.
	// maybe just destroy the door, could be two players from opposite sides..
	// breaking into chunks seems best.
	// or I cuold just give it no collision
	while( 1 )
	{
		self waittill( "trigger", who ); 

		if(isDefined(self.script_noteworthy) && self.script_noteworthy == "electric_door")
		{
			return;
		}

		if( !who UseButtonPressed() )
		{
			continue;
		}

		if( who maps\_zombiemode_utility::in_revive_trigger() )
		{
			continue;
		}

		if( maps\_zombiemode_utility::is_player_valid( who ) )
		{
			if( who.score >= self.zombie_cost )
			{
				// set the score
				who maps\_zombiemode_score::minus_to_player_score( self.zombie_cost ); 
				
				self.door connectpaths(); 
	
				maps\_zombiemode_utility::play_sound_at_pos( "purchase", self.door.origin );
	
				if( self.type == "rotate" )
				{
					self.door NotSolid(); 
					
					time = 1; 
					if( IsDefined( self.door.script_transition_time ) )
					{
						time = self.door.script_transition_time; 
					}
					
					maps\_zombiemode_utility::play_sound_at_pos( "door_rotate_open", self.door.origin );
	
					self.door RotateTo( self.door.script_angles, time, 0, 0 ); 
					self.door thread maps\_zombiemode_blockers::door_solid_thread(); 
				}
				else if( self.type == "move" )
				{
					self.door NotSolid(); 
					
					time = 1; 
					if( IsDefined( self.door.script_transition_time ) )
					{
						time = self.door.script_transition_time; 
					}
					
					maps\_zombiemode_utility::play_sound_at_pos( "door_slide_open", self.door.origin );
	
					self.door MoveTo( self.door.origin + self.door.script_vector, time, time * 0.25, time * 0.25 ); 
					self.door thread maps\_zombiemode_blockers::door_solid_thread();
				}
				
				else if( self.type == "slide_apart")
				{
					
					for(i=0;i<self.doors.size;i++)
					{
						self.doors[i] NotSolid(); 
					
						time = 1; 
						if( IsDefined( self.doors[i].script_transition_time ) )
						{
							time = self.doors[i].script_transition_time; 
						}
					
						maps\_zombiemode_utility::play_sound_at_pos( "door_slide_open", self.doors[i].origin );
						
						if(isDefined(self.clip) )
						{
							if( self.clip == self.doors[i])
							{
								self.doors[i] connectpaths();
							}
						}
						else
						{
							self.doors[i] connectpaths();
						}
						
						if(isDefined(self.doors[i].script_vector))
						{
							self.doors[i] MoveTo( self.doors[i].origin + self.doors[i].script_vector, time, time * 0.25, time * 0.25 ); 
							self.doors[i] thread maps\_zombiemode_blockers::door_solid_thread();
						}
						wait(randomfloat(.15));						
					}
					
				}
	
				//Chris_P - just in case no spawners are targetted
				if(isDefined(self.door.target))
				{
					// door needs to target new spawners which will become part
					// of the level enemy array
					self.door maps\_zombiemode_blockers::add_new_zombie_spawners(); 
				}
				
				//CHRIS_P
				//set any flags
				if( IsDefined( self.script_flag ) )
				{
					flag_set( self.script_flag );
				}				
				
				// get all trigs, we might want a trigger on both sides
				// of some junk sometimes
				all_trigs = getentarray( self.target, "target" ); 
				for( i = 0; i < all_trigs.size; i++ )
				{
					all_trigs[i] delete(); 
				}
	
				break; 	
			}
			else // Not enough money
			{
				maps\_zombiemode_utility::play_sound_at_pos( "no_purchase", self.door.origin );
			}
		}
	}
}

door_think_factory_override()
{
	// maybe the door the should just bust open instead of slowly opening.
	// maybe just destroy the door, could be two players from opposite sides..
	// breaking into chunks seems best.
	// or I cuold just give it no collision
	while( 1 )
	{
		if(isDefined(self.script_noteworthy) && self.script_noteworthy == "electric_door")
		{
			flag_wait( "electricity_on" );
		}
		else
		{
			self waittill( "trigger", who ); 
			if( !who UseButtonPressed() )
			{
				continue;
			}

			if( who maps\_zombiemode_utility::in_revive_trigger() )
			{
				continue;
			}

			if( maps\_zombiemode_utility::is_player_valid( who ) )
			{
				if( who.score >= self.zombie_cost )
				{
					// set the score
					who maps\_zombiemode_score::minus_to_player_score( self.zombie_cost ); 
					if( isDefined( level.achievement_notify_func ) )
					{
						level [[ level.achievement_notify_func ]]( "DLC3_ZOMBIE_ALL_DOORS" );
					}
					bbPrint( "zombie_uses: playername %s playerscore %d round %d cost %d name %s x %f y %f z %f type door", who.playername, who.score, level.round_number, self.zombie_cost, self.target, self.origin );
				}
				else // Not enough money
				{
					maps\_zombiemode_utility::play_sound_at_pos( "no_purchase", self.doors[0].origin );
					// who thread maps\_zombiemode_perks::play_no_money_perk_dialog();
					continue;
				}
			}
		}

		// Door has been activated, make it do its thing
		for(i=0;i<self.doors.size;i++)
		{
			self.doors[i] NotSolid(); 
			self.doors[i] connectpaths();
			
			// Prevent multiple triggers from making doors move more than once
			if ( IsDefined(self.doors[i].door_moving) )
			{
				continue;
			}
			self.doors[i].door_moving = 1;
			
			if ( ( IsDefined( self.doors[i].script_noteworthy )	&& self.doors[i].script_noteworthy == "clip" ) ||
				 ( IsDefined( self.doors[i].script_string )		&& self.doors[i].script_string == "clip" ) )
			{
				continue;
			}

			if ( IsDefined( self.doors[i].script_sound ) )
			{
				maps\_zombiemode_utility::play_sound_at_pos( self.doors[i].script_sound, self.doors[i].origin );
			}
			else
			{
				maps\_zombiemode_utility::play_sound_at_pos( "door_slide_open", self.doors[i].origin );
			}

			time = 1; 
			if( IsDefined( self.doors[i].script_transition_time ) )
			{
				time = self.doors[i].script_transition_time; 
			}

			// MM - each door can now have a different opening style instead of
			//	needing to be all the same
			switch( self.doors[i].script_string )
			{
			case "rotate":
				if(isDefined(self.doors[i].script_angles))
				{
					self.doors[i] RotateTo( self.doors[i].script_angles, time, 0, 0 ); 
					self.doors[i] thread maps\_zombiemode_blockers_new::door_solid_thread(); 
				}
				wait(randomfloat(.15));						
				break;
			case "move":
			case "slide_apart":
				if(isDefined(self.doors[i].script_vector))
				{
					self.doors[i] MoveTo( self.doors[i].origin + self.doors[i].script_vector, time, time * 0.25, time * 0.25 ); 
					self.doors[i] thread maps\_zombiemode_blockers_new::door_solid_thread();
				}
				wait(randomfloat(.15));						
				break;

			case "anim":
//						self.doors[i] animscripted( "door_anim", self.doors[i].origin, self.doors[i].angles, level.scr_anim[ self.doors[i].script_animname ] );
				self.doors[i] [[ level.blocker_anim_func ]]( self.doors[i].script_animname ); 
				self.doors[i] thread maps\_zombiemode_blockers_new::door_solid_thread_anim();
				wait(randomfloat(.15));						
				break;
			}

			// Just play purchase sound on the first door
			if( i == 0 )
			{
				maps\_zombiemode_utility::play_sound_at_pos( "purchase", self.doors[i].origin );
			}
				
			//Chris_P - just in case spawners are targeted
			if( isDefined( self.doors[i].target ) )
			{
				// door needs to target new spawners which will become part
				// of the level enemy array
				self.doors[i] maps\_zombiemode_blockers_new::add_new_zombie_spawners();
			}
		}
	
		//CHRIS_P
		//set any flags
		if( IsDefined( self.script_flag ) )
		{
			flag_set( self.script_flag );
		}				
		
		// get all trigs, we might want a trigger on both sides
		// of some junk sometimes
		all_trigs = getentarray( self.target, "target" ); 
		for( i = 0; i < all_trigs.size; i++ )
		{
			all_trigs[i] trigger_off(); 
		}
		break;
	}
}

debris_think_pre_factory_override()
{
	
	
	//this makes the script_model not-solid ( for asylum only! )
	if(level.script == "nazi_zombie_asylum")
	{
		ents = getentarray( self.target, "targetname" ); 
		for( i = 0; i < ents.size; i++ )
		{	
			if( IsDefined( ents[i].script_linkTo ) )
			{
				ents[i] notsolid();
			}
		}
	}
		
	
	while( 1 )
	{
		self waittill( "trigger", who ); 

		if( !who UseButtonPressed() )
		{
			continue;
		}

		if( who maps\_zombiemode_utility::in_revive_trigger() )
		{
			continue;
		}

		if( maps\_zombiemode_utility::is_player_valid( who ) )
		{
			if( who.score >= self.zombie_cost )
			{
				// set the score
				who maps\_zombiemode_score::minus_to_player_score( self.zombie_cost ); 
	
				// delete the stuff
				junk = getentarray( self.target, "targetname" ); 
	
				if( IsDefined( self.script_flag ) )
				{
					flag_set( self.script_flag );
				}

				maps\_zombiemode_utility::play_sound_at_pos( "purchase", self.origin );
	
				move_ent = undefined;
				clip = undefined;
				for( i = 0; i < junk.size; i++ )
				{	
					junk[i] connectpaths(); 
					junk[i] maps\_zombiemode_blockers::add_new_zombie_spawners(); 
					
	
					level notify ("junk purchased");
	
					if( IsDefined( junk[i].script_noteworthy ) )
					{
						if( junk[i].script_noteworthy == "clip" )
						{
							clip = junk[i];
							continue;
						}
					}
	
					struct = undefined;
					if( IsDefined( junk[i].script_linkTo ) )
					{
						struct = getstruct( junk[i].script_linkTo, "script_linkname" );
						if( IsDefined( struct ) )
						{
							move_ent = junk[i];
							junk[i] thread maps\_zombiemode_blockers::debris_move( struct );
						}
						else
						{
							junk[i] Delete();
						}
					}
					else
					{
						junk[i] Delete();
					}
				}
				
				// get all trigs, we might want a trigger on both sides
				// of some junk sometimes
				all_trigs = getentarray( self.target, "target" ); 
				for( i = 0; i < all_trigs.size; i++ )
				{
					all_trigs[i] delete(); 
				}
	
				if( IsDefined( clip ) )
				{
					if( IsDefined( move_ent ) )
					{
						move_ent waittill( "movedone" );
						move_ent notsolid();
					}
	
					clip Delete();
				}
				
				break; 								
			}
			else
			{
				maps\_zombiemode_utility::play_sound_at_pos( "no_purchase", self.origin );
			}
		}
	}
}

debris_think_factory_override()
{
	
	
	//this makes the script_model not-solid ( for asylum only! )
	if(level.script == "nazi_zombie_asylum")
	{
		ents = getentarray( self.target, "targetname" ); 
		for( i = 0; i < ents.size; i++ )
		{	
			if( IsDefined( ents[i].script_linkTo ) )
			{
				ents[i] notsolid();
			}
		}
	}
		
	
	while( 1 )
	{
		self waittill( "trigger", who ); 

		if( !who UseButtonPressed() )
		{
			continue;
		}

		if( who maps\_zombiemode_utility::in_revive_trigger() )
		{
			continue;
		}

		if( maps\_zombiemode_utility::is_player_valid( who ) )
		{
			if( who.score >= self.zombie_cost )
			{
				// set the score
				who maps\_zombiemode_score::minus_to_player_score( self.zombie_cost ); 
				if( isDefined( level.achievement_notify_func ) )
				{
					level [[ level.achievement_notify_func ]]( "DLC3_ZOMBIE_ALL_DOORS" );
				}
				bbPrint( "zombie_uses: playername %s playerscore %d round %d cost %d name %s x %f y %f z %f type debris", who.playername, who.score, level.round_number, self.zombie_cost, self.target, self.origin );
				
				// delete the stuff
				junk = getentarray( self.target, "targetname" ); 
	
				if( IsDefined( self.script_flag ) )
				{
					flag_set( self.script_flag );
				}

				maps\_zombiemode_utility::play_sound_at_pos( "purchase", self.origin );
	
				move_ent = undefined;
				clip = undefined;
				for( i = 0; i < junk.size; i++ )
				{	
					junk[i] connectpaths(); 
					junk[i] maps\_zombiemode_blockers_new::add_new_zombie_spawners(); 
					
	
					level notify ("junk purchased");
	
					if( IsDefined( junk[i].script_noteworthy ) )
					{
						if( junk[i].script_noteworthy == "clip" )
						{
							clip = junk[i];
							continue;
						}
					}
	
					struct = undefined;
					if( IsDefined( junk[i].script_linkTo ) )
					{
						struct = getstruct( junk[i].script_linkTo, "script_linkname" );
						if( IsDefined( struct ) )
						{
							move_ent = junk[i];
							junk[i] thread maps\_zombiemode_blockers_new::debris_move( struct );
						}
						else
						{
							junk[i] Delete();
						}
					}
					else
					{
						junk[i] Delete();
					}
				}
				
				// get all trigs, we might want a trigger on both sides
				// of some junk sometimes
				all_trigs = getentarray( self.target, "target" ); 
				for( i = 0; i < all_trigs.size; i++ )
				{
					all_trigs[i] delete(); 
				}
	
				if( IsDefined( clip ) )
				{
					if( IsDefined( move_ent ) )
					{
						move_ent waittill( "movedone" );
						move_ent notsolid();
					}
	
					clip Delete();
				}
				
				break; 								
			}
			else
			{
				maps\_zombiemode_utility::play_sound_at_pos( "no_purchase", self.origin );
				// who thread maps\nazi_zombie_sumpf_blockers::play_no_money_purchase_dialog();
			}
		}
	}
}