#include maps\_zombiemode_tesla;
#include maps\_utility;
#include common_scripts\utility;

main()
{
	replaceFunc( maps\_zombiemode_tesla::tesla_arc_damage, ::tesla_arc_damage_override );
	replaceFunc( maps\_zombiemode_tesla::tesla_end_arc_damage, ::tesla_end_arc_damage_override );
	replaceFunc( maps\nazi_zombie_factory::electric_trap_think, ::electric_trap_think_override );
	replaceFunc( maps\nazi_zombie_factory::include_weapons, ::include_weapons_override );
	replaceFunc( maps\nazi_zombie_factory_teleporter::teleport_pad_active_think, ::teleport_pad_active_think_override );
	replaceFunc( maps\_zombiemode_powerups::special_drop_setup, ::special_drop_setup_override );
	replaceFunc( maps\_zombiemode_dogs::special_dog_spawn, ::special_dog_spawn_override );
	level thread reset_teleporter_cost();
}

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
				if ( isDefined( level._custom_func_table[ "giveRankXP" ] ) )
				{
					trap_activator [[ level._custom_func_table[ "giveRankXP" ] ]]( "trap_kill", 3 );
				}
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
	maps\_zombiemode_utility::include_weapon( "zombie_m1carbine", false );
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
	maps\_zombiemode_utility::include_weapon( "zombie_fg42", false );
	maps\_zombiemode_utility::include_weapon( "zombie_fg42_upgraded", false );

	maps\_zombiemode_utility::include_weapon( "zombie_30cal" );
	maps\_zombiemode_utility::include_weapon( "zombie_30cal_upgraded", false );
	maps\_zombiemode_utility::include_weapon( "zombie_mg42" );
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

special_dog_spawn_override( spawners, num_to_spawn )
{
	if ( !IsDefined(num_to_spawn) )
	{
		num_to_spawn = 1;
	}

	if ( maps\_zombiemode_utility::get_enemy_count() >= 24 )
	{
		return false;
	}

	spawn_point = undefined;
	count = 0;
	spawn_attempts = 0;
	while ( count < num_to_spawn )
	{
		if ( spawn_attempts > 3 )
		{
			return false;
		}
		//update the player array.
		players = getPlayers();
		favorite_enemy = maps\_zombiemode_dogs::get_favorite_enemy();
		ai = undefined;
		if ( IsDefined( spawners ) )
		{
			spawn_point = spawners[ RandomInt(spawners.size) ];
			ai = maps\_zombiemode_utility::spawn_zombie( spawn_point );

			if( IsDefined( ai ) ) 	
			{
				spawn_point thread maps\_zombiemode_dogs::dog_spawn_fx( ai );
			}
		}
		else
		{
			if ( IsDefined( level.dog_spawn_func ) )
			{
				spawn_loc = [[level.dog_spawn_func]]( level.enemy_dog_spawns, favorite_enemy );

				ai = maps\_zombiemode_utility::spawn_zombie( level.enemy_dog_spawns[0] );
				if( IsDefined( ai ) ) 	
				{
					spawn_loc thread maps\_zombiemode_dogs::dog_spawn_fx( ai, spawn_loc );
				}
			}
			else
			{
				// Old method
				spawn_point = maps\_zombiemode_dogs::dog_spawn_sumpf_logic( level.enemy_dog_spawns, favorite_enemy );
				ai = maps\_zombiemode_utility::spawn_zombie( spawn_point );

				if( IsDefined( ai ) ) 	
				{
					spawn_point thread maps\_zombiemode_dogs::dog_spawn_fx( ai );

				}
			}
		}
		if ( isDefined( ai ) )
		{
			ai.favoriteenemy = favorite_enemy;
			level.zombie_total--;
			count++;
			flag_set( "dog_clips" );
			ai thread dog_spawn_failsafe();
		}
		spawn_attempts++;
	}

	return true;
}

dog_spawn_failsafe()
{
	self endon("death");

	prevorigin = self.origin;
	prevhealth = self.health;
	times_checked_health = 0;
	while ( true )
	{
		if( !level.zombie_vars["zombie_use_failsafe"] )
		{
			return;
		}

		wait( 30 );

		if ( self.origin[2] < level.zombie_vars["below_world_check"] )
		{
			self dodamage( self.health + 100, (0,0,0) );	
			break;
		}
		if ( DistanceSquared( self.origin, prevorigin ) < 576 ) 
		{
			self dodamage( self.health + 100, (0,0,0) );	
			break;
		}
		if ( self.health == prevhealth )
		{
			times_checked_health++;
			if ( times_checked_health > 2 )
			{
				self dodamage( self.health + 100, (0,0,0) );
				break;
			}
		}
		prevorigin = self.origin;
		prevhealth = self.health;
	}
}