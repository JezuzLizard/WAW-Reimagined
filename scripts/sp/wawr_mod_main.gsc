#include maps\_utility;
#include common_scripts\utility;

/*
#define XP_PER_NORMAL_KILL 2
#define XP_PER_HEAD_SHOT_KILL 2
#define XP_FOR_ROUND_COMPLETION_BASE 10
#define XP_FOR_ROUND_COMPLETION_CAP 300
#define XP_FOR_REVIVE 10
#define XP_FOR_DOOR_BUY 25
#define XP_FOR_POWER_ACTIVATE 50
*/
main()
{
	level.script = Tolower( GetDvar( "mapname" ) );
	replaceFunc( maps\_zombiemode_powerups::nuke_powerup, scripts\sp\wawr_common_functions::nuke_powerup_override );
	replaceFunc( maps\_zombiemode_utility::spawn_zombie, ::spawn_zombie_override );
	replaceFunc( maps\_zombiemode_powerups::include_zombie_powerup, ::include_zombie_powerup_override );
	replaceFunc( maps\_zombiemode_powerups::full_ammo_powerup, scripts\sp\wawr_common_functions::full_ammo_powerup_override );
	if ( level.script != "mazi_zombie_prototype" && level.script != "nazi_zombie_asylum" )
	{
		replaceFunc( maps\_zombiemode::round_wait, scripts\sp\wawr_common_functions::round_wait_override );
		replaceFunc( maps\_zombiemode::round_spawning, scripts\sp\wawr_common_functions::round_spawning_override );
		replaceFunc( maps\_zombiemode::spectators_respawn, scripts\sp\wawr_common_functions::spectators_respawn_override );
	}
	dog_spawn_wait_func = getFunction( "maps/_zombiemode_dogs", "waiting_for_next_dog_spawn" );
	if ( isDefined( dog_spawn_wait_func ) )
	{
		replaceFunc( dog_spawn_wait_func, scripts\sp\wawr_common_functions::waiting_for_next_dog_spawn_override );
	}
	if ( !isDefined( level._custom_funcs_table ) )
	{
		level._custom_funcs_table = [];
	}
	level._custom_func_table[ "special_dog_spawn" ] = getFunction( "maps/_zombiemode_dogs", "special_dog_spawn" );
	level._custom_func_table[ "is_magic_bullet_shield_enabled" ] = getFunction( "maps/_zombiemode_utility", "is_magic_bullet_shield_enabled" );
	level._custom_func_table[ "enemy_is_dog" ] = getFunction( "maps/_zombiemode_utility", "enemy_is_dog" );
	level._custom_func_table[ "spectator_respawn_prototype" ] = getFunction( "maps/_zombiemode_prototype", "spectator_respawn" );
	level._end_of_round_funcs = [];
	level thread on_player_connect();
}

init()
{
	precacheShader( "damage_feedback" );
	level.zombie_counter_zombies = 0;
	SetDvar( "player_lastStandBleedoutTime", 45 );
	SetDvar( "g_fix_tesla_bug", 1 );
	SetDvar( "g_disable_zombie_grab", 1 );
	SetDvar( "perk_weaprateEnhanced", 1 );
	setDvar( "scr_damagefeedback", 1 );
	setDvar( "g_friendlyFireDist", 0 );
	level thread enemy_counter_hud();
	level thread calculate_sph();
	level thread sph_hud();
	level thread insta_kill_rounds_tracker();
	level.sph_hud_counter = 0;
	level.zombie_kill_times = [];

	level.zombie_vars["zombie_spawn_delay"] = 1.5;
}

on_player_connect()
{
	level endon( "end_game" );
	while ( true )
	{
		level waittill( "connected", player );
		player init_damage_feedback_hud();
		player setClientDvar( "aim_lockon_enabled", 1 );
	}
}


include_zombie_powerup_override( powerup )
{
	if ( powerup == "carpenter" )
	{
		return;
	}
	func = getFunction( "maps/_zombiemode_powerups", "include_zombie_powerup" );
	if ( isDefined( func ) )
	{
		disableDetourOnce( func );
		[[ func ]]( powerup );
	}
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
		guy thread monitor_damage_for_damage_feedback();
		return guy;  
	}

	return undefined;  
}

zombie_death()
{
	self waittill( "death" );
	level.zombie_kill_times[ getTime() + "" ] = true;
}

enemy_counter_hud()
{
	enemy_counter_hud = newHudElem();
	enemy_counter_hud.alignx = "left";
	enemy_counter_hud.aligny = "bottom";
	enemy_counter_hud.horzalign = "left";
	enemy_counter_hud.vertalign = "bottom";
	enemy_counter_hud.x += 5;
	enemy_counter_hud.y -= 90;
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
			enemy_counter_hud setText( "" );
			wait 1;
		}
		enemy_counter_hud.alpha = 1;
		enemies = maps\_zombiemode_utility::get_enemy_count() + level.zombie_total;
		enemy_counter_hud setValue( enemies );
		wait 0.05;
	}
}

is_round_ongoing()
{
	return ( maps\_zombiemode_utility::get_enemy_count() > 0 || level.zombie_total > 0 );
}

sph_hud()
{
	enemy_counter_hud = newHudElem();
	enemy_counter_hud.alignx = "left";
	enemy_counter_hud.aligny = "bottom";
	enemy_counter_hud.horzalign = "left";
	enemy_counter_hud.vertalign = "bottom";
	enemy_counter_hud.x += 5;
	enemy_counter_hud.y -= 120;
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
		while ( level.sph_hud_counter == 0 )
		{
			enemy_counter_hud setText( "" );
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

insta_kill_rounds_tracker()
{
	level.post_insta_kill_rounds = 0;
	while ( 1 )
	{
		level waittill( "start_of_round" );
		wait 0.5;
		health = undefined;
		if ( level.round_number >= 31 )
		{
			health = calculate_insta_kill_rounds();
			level.post_insta_kill_rounds++;
		}
		if ( !isDefined( health ) )
		{
			level.zombie_health = calculate_normal_health();
		}
		else 
		{
			level.zombie_health = health;
		}
		if ( level.round_is_insta_kill )
		{
			iprintln( "All zombies are insta kill this round" );
		}
	}
}

calculate_insta_kill_rounds()
{
	level.round_is_insta_kill = 0;
	if ( level.round_number >= 163 )
	{
		return undefined;
	}
	health = level.zombie_vars[ "zombie_health_start" ];
	for ( i = 2; i <= ( level.post_insta_kill_rounds + 163 ); i++ )
	{
		if ( i >= 10 )
		{
			health += int( health * level.zombie_vars[ "zombie_health_increase_percent" ] );
		}
		else
		{
			health = int( health + level.zombie_vars[ "zombie_health_increase" ] );
		}
	}
	if ( health < 0 )
	{
		level.round_is_insta_kill = 1;
		return 20;
	}
	return undefined;
}

calculate_normal_health()
{
	level.round_is_insta_kill = 0;
	health = level.zombie_vars[ "zombie_health_start" ];
	for ( i = 2; i <= level.round_number; i++ )
	{
		if ( i >= 10 )
		{
			health += int( health * level.zombie_vars[ "zombie_health_increase_percent" ] );
		}
		else
		{
			health = int( health + level.zombie_vars[ "zombie_health_increase" ] );
		}
	}
	if ( health < 0 )
	{
		level.round_is_insta_kill = 1;
		return 20;
	}
	return health;
}

/*
purchase_xp_on_hud()
{
	hud = set_hudelem( "Save Successful", 320, 100, 1.5 );
	hud.alignX = "center";
	hud.color = ( 0, 1, 0 );

	hud_msg = set_hudelem( msg, 320, 120, 1.3 );
	hud_msg.alignX = "center";
	hud_msg.color = ( 1, 1, 1 );

	wait( 2 );

	hud FadeOverTime( 3 );
	hud.alpha = 0;

	hud_msg FadeOverTime( 3 );
	hud_msg.alpha = 0;

	wait( 3 );
	hud Destroy();
	hud_msg Destroy();
}
*/

init_damage_feedback_hud()
{
	if ( !getDvarInt( "scr_damagefeedback" ) )
		return;

	self.hud_damagefeedback = newClientHudElem( self );
	self.hud_damagefeedback.alignX = "center";
	self.hud_damagefeedback.alignY = "middle";
	self.hud_damagefeedback.horzAlign = "center";
	self.hud_damagefeedback.vertAlign = "middle";
	self.hud_damagefeedback.alpha = 0;
	self.hud_damagefeedback.archived = true;
	self.hud_damagefeedback.color = ( 1, 1, 1 );
	self.hud_damagefeedback setShader( "damage_feedback", 24, 24 );

	self.hud_damagefeedback_kill = newClientHudElem( self );
	self.hud_damagefeedback_kill.alignX = "center";
	self.hud_damagefeedback_kill.alignY = "middle";
	self.hud_damagefeedback_kill.horzAlign = "center";
	self.hud_damagefeedback_kill.vertAlign = "middle";
	self.hud_damagefeedback_kill.alpha = 0;
	self.hud_damagefeedback_kill.archived = true;
	self.hud_damagefeedback_kill.color = ( 1, 0, 0 );
	self.hud_damagefeedback_kill setShader( "damage_feedback", 24, 24 );
}

updateDamageFeedback()
{
	//self playlocalsound( "SP_hit_alert" );
	
	self.hud_damagefeedback.alpha = 1;
	self.hud_damagefeedback fadeOverTime( 1 );
	self.hud_damagefeedback.alpha = 0;
}

updateDamageFeedback_kill()
{
	//self playlocalsound( "SP_hit_alert" );
	
	self.hud_damagefeedback_kill.alpha = 1;
	self.hud_damagefeedback_kill fadeOverTime( 1 );
	self.hud_damagefeedback_kill.alpha = 0;
}

monitor_damage_for_damage_feedback()
{
	if ( !getDvarInt( "scr_damagefeedback" ) )
		return;

	for ( ;; )
	{
		self waittill( "damage", amount, attacker );
		
		if ( !isPlayer( attacker ) )
		{
			continue;
		}
		if ( self.health < 1 )
		{
			attacker updateDamageFeedback_kill();
			return;
		}
		else 
		{
			attacker updateDamageFeedback();
		}
	}
}