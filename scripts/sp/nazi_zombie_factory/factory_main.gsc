#include maps\_zombiemode_tesla;
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

electric_trap_think_override( enable_flag )
{	
	self sethintstring(&"ZOMBIE_FLAMES_UNAVAILABLE");
	self.zombie_cost = 1000;
	
	self thread maps\nazi_zombie_factory::electric_trap_dialog();

	// get a list of all of the other triggers with the same name
	triggers = getentarray( self.targetname, "targetname" );
	flag_wait( "electricity_on" );

	// Get the damage trigger.  This is the unifying element to let us know it's been activated.
	self.zombie_dmg_trig = getent(self.target,"targetname");
	self.zombie_dmg_trig.in_use = 0;

	// Set buy string
	self sethintstring(&"ZOMBIE_BUTTON_NORTH_FLAMES");

	// Getting the light that's related is a little esoteric, but there isn't
	// a better way at the moment.  It uses linknames, which are really dodgy.
	light_name = "";	// scope declaration
	tswitch = getent(self.script_linkto,"script_linkname");
	switch ( tswitch.script_linkname )
	{
	case "10":	// wnuen
	case "11":
		light_name = "zapper_light_wuen";	
		break;

	case "20":	// warehouse
	case "21":
		light_name = "zapper_light_warehouse";
		break;

	case "30":	// Bridge
	case "31":
		light_name = "zapper_light_bridge";
		break;
	}

	// The power is now on, but keep it disabled until a certain condition is met
	//	such as opening the door it is blocking or waiting for the bridge to lower.
	if ( !flag( enable_flag ) )
	{
		self trigger_off();

		maps\nazi_zombie_factory::zapper_light_red( light_name );
		flag_wait( enable_flag );

		self trigger_on();
	}

	// Open for business!  
	maps\nazi_zombie_factory::zapper_light_green( light_name );

	while(1)
	{
		//valve_trigs = getentarray(self.script_noteworthy ,"script_noteworthy");		
	
		//wait until someone uses the valve
		self waittill("trigger",who);
		if( who maps\_zombiemode_utility::in_revive_trigger() )
		{
			continue;
		}
		
		if( maps\_zombiemode_utility::is_player_valid( who ) )
		{
			if( who.score >= self.zombie_cost )
			{				
				if(!self.zombie_dmg_trig.in_use)
				{
					self.zombie_dmg_trig.in_use = 1;

					//turn off the valve triggers associated with this trap until available again
					array_thread (triggers, ::trigger_off);

					maps\_zombiemode_utility::play_sound_at_pos( "purchase", who.origin );
					self thread maps\nazi_zombie_factory::electric_trap_move_switch(self);
					//need to play a 'woosh' sound here, like a gas furnace starting up
					self waittill("switch_activated");
					//set the score
					who maps\_zombiemode_score::minus_to_player_score( self.zombie_cost );

					//this trigger detects zombies walking thru the flames
					self.zombie_dmg_trig trigger_on();

					//play the flame FX and do the actual damage
					self thread activate_electric_trap_override( who );					

					//wait until done and then re-enable the valve for purchase again
					self waittill("elec_done");
					
					clientnotify(self.script_string +"off");
										
					//delete any FX ents
					if(isDefined(self.fx_org))
					{
						self.fx_org delete();
					}
					if(isDefined(self.zapper_fx_org))
					{
						self.zapper_fx_org delete();
					}
					if(isDefined(self.zapper_fx_switch_org))
					{
						self.zapper_fx_switch_org delete();
					}
										
					//turn the damage detection trigger off until the flames are used again
			 		self.zombie_dmg_trig trigger_off();
					wait(25);

					array_thread (triggers, ::trigger_on);

					//COLLIN: Play the 'alarm' sound to alert players that the traps are available again (playing on a temp ent in case the PA is already in use.
					//speakerA = getstruct("loudspeaker", "targetname");
					//playsoundatposition("warning", speakera.origin);
					self notify("available");

					self.zombie_dmg_trig.in_use = 0;
				}
			}
		}
	}
}

activate_electric_trap_override( who )
{
	if(isDefined(self.script_string) && self.script_string == "warehouse")
	{
		clientnotify("warehouse");
	}
	else if(isDefined(self.script_string) && self.script_string == "wuen")
	{
		clientnotify("wuen");
	}
	else
	{
		clientnotify("bridge");
	}	
		
	clientnotify(self.target);
	
	fire_points = getstructarray(self.target,"targetname");
	
	for(i=0;i<fire_points.size;i++)
	{
		wait_network_frame();
		fire_points[i] thread maps\nazi_zombie_factory::electric_trap_fx(self);		
	}
	
	//do the damage
	self.zombie_dmg_trig thread elec_barrier_damage_override( who );
	
	// reset the zapper model
	level waittill("arc_done");
}

elec_barrier_damage_override( trap_activator )
{	
	while(1)
	{
		self waittill("trigger",ent);
		
		//player is standing electricity, dumbass
		if(isplayer(ent) )
		{
			ent thread maps\nazi_zombie_factory::player_elec_damage();
		}
		else
		{
			if(!isDefined(ent.marked_for_death))
			{
				ent.marked_for_death = true;
				trap_activator.kills++;
				trap_activator give_player_score( 10 );
				ent thread zombie_elec_death_override( randomint(100) );
			}
		}
	}
}

zombie_elec_death_override(flame_chance)
{
	self endon("death");
	if(flame_chance > 90 && level.burning_zombies.size < 6)
	{
		level.burning_zombies[level.burning_zombies.size] = self;
		self thread maps\nazi_zombie_factory::zombie_flame_watch();
		self playsound("ignite");
		self thread animscripts\death::flame_death_fx();
		//wait(randomfloat(1.25));		
	}
	else
	{
		refs[0] = "guts";
		refs[1] = "right_arm"; 
		refs[2] = "left_arm"; 
		refs[3] = "right_leg"; 
		refs[4] = "left_leg"; 
		refs[5] = "no_legs";
		refs[6] = "head";
		self.a.gib_ref = refs[randomint(refs.size)];
		playsoundatposition("zombie_arc", self.origin);
		if( !self maps\_zombiemode_utility::enemy_is_dog() && randomint(100) > 50 )
		{
			self thread maps\nazi_zombie_factory::electroctute_death_fx();
			self thread maps\nazi_zombie_factory::play_elec_vocals();
		}
		//wait(randomfloat(1.25));
		self playsound("zombie_arc");
	}
	self dodamage(self.health + 666, self.origin);
}

include_powerups_override()
{
	maps\_zombiemode_utility::include_powerup( "nuke" );
	maps\_zombiemode_utility::include_powerup( "insta_kill" );
	maps\_zombiemode_utility::include_powerup( "double_points" );
	maps\_zombiemode_utility::include_powerup( "full_ammo" );
}

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

include_weapons_override()
{
	maps\_zombiemode_utility::include_weapon( "zombie_colt" );
	maps\_zombiemode_utility::include_weapon( "zombie_colt_upgraded", false );
	maps\_zombiemode_utility::include_weapon( "zombie_sw_357" );
	maps\_zombiemode_utility::include_weapon( "zombie_sw_357_upgraded", false );

	// Bolt Action
	maps\_zombiemode_utility::include_weapon( "zombie_kar98k", false );
	maps\_zombiemode_utility::include_weapon( "zombie_kar98k_upgraded", false );
//	include_weapon( "springfield");		
//	include_weapon( "zombie_type99_rifle" );
//	include_weapon( "zombie_type99_rifle_upgraded", false );

	// Semi Auto
	maps\_zombiemode_utility::include_weapon( "zombie_m1carbine" );
	maps\_zombiemode_utility::include_weapon( "zombie_m1carbine_upgraded", false );
	maps\_zombiemode_utility::include_weapon( "zombie_m1garand" );
	maps\_zombiemode_utility::include_weapon( "zombie_m1garand_upgraded", false );
	maps\_zombiemode_utility::include_weapon( "zombie_gewehr43", false );
	maps\_zombiemode_utility::include_weapon( "zombie_gewehr43_upgraded", false );

	// Full Auto
	maps\_zombiemode_utility::include_weapon( "zombie_stg44", false );
	maps\_zombiemode_utility::include_weapon( "zombie_stg44_upgraded", false );
	maps\_zombiemode_utility::include_weapon( "zombie_thompson", false );
	maps\_zombiemode_utility::include_weapon( "zombie_thompson_upgraded", false );
	maps\_zombiemode_utility::include_weapon( "zombie_mp40", false );
	maps\_zombiemode_utility::include_weapon( "zombie_mp40_upgraded", false );
	maps\_zombiemode_utility::include_weapon( "zombie_type100_smg", false );
	maps\_zombiemode_utility::include_weapon( "zombie_type100_smg_upgraded", false );

	// Scoped
	maps\_zombiemode_utility::include_weapon( "ptrs41_zombie" );
	maps\_zombiemode_utility::include_weapon( "ptrs41_zombie_upgraded", false );
//	include_weapon( "kar98k_scoped_zombie" );	// replaced with type99_rifle_scoped
//	include_weapon( "type99_rifle_scoped_zombie" );	//

	// Grenade
	maps\_zombiemode_utility::include_weapon( "molotov" );
	maps\_zombiemode_utility::include_weapon( "stielhandgranate" );

	// Grenade Launcher	
	maps\_zombiemode_utility::include_weapon( "m1garand_gl_zombie" );
	maps\_zombiemode_utility::include_weapon( "m1garand_gl_zombie_upgraded", false );
	maps\_zombiemode_utility::include_weapon( "m7_launcher_zombie" );
	maps\_zombiemode_utility::include_weapon( "m7_launcher_zombie_upgraded", false );

	// Flamethrower
	maps\_zombiemode_utility::include_weapon( "m2_flamethrower_zombie" );
	maps\_zombiemode_utility::include_weapon( "m2_flamethrower_zombie_upgraded", false );

	// Shotgun
	maps\_zombiemode_utility::include_weapon( "zombie_doublebarrel", false );
	maps\_zombiemode_utility::include_weapon( "zombie_doublebarrel_upgraded", false );
	//include_weapon( "zombie_doublebarrel_sawed" );
	maps\_zombiemode_utility::include_weapon( "zombie_shotgun", false );
	maps\_zombiemode_utility::include_weapon( "zombie_shotgun_upgraded", false );

	// Heavy MG
	maps\_zombiemode_utility::include_weapon( "zombie_bar" );
	maps\_zombiemode_utility::include_weapon( "zombie_bar_upgraded", false );
	maps\_zombiemode_utility::include_weapon( "zombie_fg42" );
	maps\_zombiemode_utility::include_weapon( "zombie_fg42_upgraded", false );

	maps\_zombiemode_utility::include_weapon( "zombie_30cal" );
	maps\_zombiemode_utility::include_weapon( "zombie_30cal_upgraded", false );
	maps\_zombiemode_utility::include_weapon( "zombie_mg42", false );
	maps\_zombiemode_utility::include_weapon( "zombie_mg42_upgraded", false );
	maps\_zombiemode_utility::include_weapon( "zombie_ppsh" );
	maps\_zombiemode_utility::include_weapon( "zombie_ppsh_upgraded", false );

	// Rocket Launcher
	maps\_zombiemode_utility::include_weapon( "panzerschrek_zombie" );
	maps\_zombiemode_utility::include_weapon( "panzerschrek_zombie_upgraded", false );

	// Special
	maps\_zombiemode_utility::include_weapon( "ray_gun", true, maps\nazi_zombie_factory::factory_ray_gun_weighting_func );
	maps\_zombiemode_utility::include_weapon( "ray_gun_upgraded", false );
	maps\_zombiemode_utility::include_weapon( "tesla_gun", true );
	maps\_zombiemode_utility::include_weapon( "tesla_gun_upgraded", false );
	maps\_zombiemode_utility::include_weapon( "zombie_cymbal_monkey", true, maps\nazi_zombie_factory::factory_cymbal_monkey_weighting_func );


	//bouncing betties
	maps\_zombiemode_utility::include_weapon("mine_bouncing_betty", false);

	// limited weapons
	maps\_zombiemode_weapons::add_limited_weapon( "zombie_colt", 0 );
	//maps\_zombiemode_weapons::add_limited_weapon( "zombie_type99_rifle", 0 );
	maps\_zombiemode_weapons::add_limited_weapon( "zombie_gewehr43", 0 );
	maps\_zombiemode_weapons::add_limited_weapon( "zombie_m1garand", 0 );
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

		if( maps\_zombiemode_utility::is_magic_bullet_shield_enabled( zombies[i] ) )
		{
			continue;
		}

		if( i < 5 && !( zombies[i] maps\_zombiemode_utility::enemy_is_dog() ) )
		{
			zombies[i] thread animscripts\death::flame_death_fx();

		}

		if( !( zombies[i] maps\_zombiemode_utility::enemy_is_dog() ) )
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

teleport_pad_active_think_override( index )
{
	self setcursorhint( "HINT_NOICON" );
	self.teleport_active = true;
	user = undefined;
	while ( 1 )
	{
		self waittill( "trigger", user );
		if ( maps\_zombiemode_utility::is_player_valid( user ) && user.score >= level.teleport_cost && !level.is_cooldown )
		{
			for ( i = 0; i < level.teleporter_pad_trig.size; i++ )
			{
				level.teleporter_pad_trig[i] maps\nazi_zombie_factory_teleporter::teleport_trigger_invisible( true );
			}
			user maps\_zombiemode_score::minus_to_player_score( level.teleport_cost );
			self maps\nazi_zombie_factory_teleporter::player_teleporting( index );
			level.teleport_cost += 3000;
		}
	}
}

reset_teleporter_cost()
{
	while ( true )
	{
		level waittill( "start_of_round" );
		level.teleport_cost = 1500;
	}
}

special_drop_setup_override()
{
	powerup = undefined;
	is_powerup = true;
	powerup = maps\_zombiemode_powerups::get_next_powerup();
	switch ( powerup )
	{
	case "nuke":
	case "insta_kill":
	case "double_points":
	case "full_ammo":
		break;
	default:
		is_powerup = false;
		Playfx( level._effect["lightning_dog_spawn"], self.origin );
		playsoundatposition( "pre_spawn", self.origin );
		wait( 1.5 );
		playsoundatposition( "bolt", self.origin );
		Earthquake( 0.5, 0.75, self.origin, 1000);
		PlayRumbleOnPosition("explosion_generic", self.origin);
		playsoundatposition( "spawn", self.origin );
		wait( 1.0 );
		thread maps\_zombiemode_utility::play_sound_2d( "sam_nospawn" );
		self Delete();
	}
	if ( is_powerup )
	{
		Playfx( level._effect["lightning_dog_spawn"], self.origin );
		playsoundatposition( "pre_spawn", self.origin );
		wait( 1.5 );
		playsoundatposition( "bolt", self.origin );
		Earthquake( 0.5, 0.75, self.origin, 1000);
		PlayRumbleOnPosition("explosion_generic", self.origin);
		playsoundatposition( "spawn", self.origin );
		struct = level.zombie_powerups[powerup];
		self SetModel( struct.model_name );
		playsoundatposition("spawn_powerup", self.origin);
		self.powerup_name 	= struct.powerup_name;
		self.hint 			= struct.hint;
		if( IsDefined( struct.fx ) )
		{
			self.fx = struct.fx;
		}
		self PlayLoopSound("spawn_powerup_loop");
		self thread maps\_zombiemode_powerups::powerup_timeout();
		self thread maps\_zombiemode_powerups::powerup_wobble();
		self thread maps\_zombiemode_powerups::powerup_grab();
	}
}