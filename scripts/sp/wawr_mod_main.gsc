#include maps\_utility;
#include common_scripts\utility;

#define XP_PER_NORMAL_KILL 2
#define XP_PER_HEAD_SHOT_KILL 2
#define XP_FOR_ROUND_COMPLETION_BASE 10
#define XP_FOR_ROUND_COMPLETION_CAP 300

main()
{
	level.script = Tolower( GetDvar( "mapname" ) );
	replaceFunc( maps\_zombiemode_powerups::nuke_powerup, scripts\sp\wawr_common_functions::nuke_powerup_override );
	replaceFunc( maps\_zombiemode_utility::spawn_zombie, ::spawn_zombie_override );
	replaceFunc( maps\_zombiemode_powerups::include_zombie_powerup, ::include_zombie_powerup_override );
	replaceFunc( maps\_challenges_coop::ch_kills, ::ch_kills_override );
	if ( level.script != "mazi_zombie_prototype" && level.script != "nazi_zombie_asylum" )
	{
		replaceFunc( maps\_zombiemode::round_wait, scripts\sp\wawr_common_functions::round_wait_override );
		replaceFunc( maps\_zombiemode::round_spawning, scripts\sp\wawr_common_functions::round_spawning_override );
		replaceFunc( maps\_zombiemode::spectators_respawn, scripts\sp\wawr_common_functions::spectators_respawn_override );
	}
	replaceFunc( maps\_laststand::revive_success, ::revive_success_override );
	level._custom_func_table = [];
	level._custom_func_table[ "special_dog_spawn" ] = getFunction( "maps/_zombiemode_dogs", "special_dog_spawn" );
	level._custom_func_table[ "is_magic_bullet_shield_enabled" ] = getFunction( "maps/_zombiemode_utility", "is_magic_bullet_shield_enabled" );
	level._custom_func_table[ "enemy_is_dog" ] = getFunction( "maps/_zombiemode_utility", "enemy_is_dog" );
	level._custom_func_table[ "spectator_respawn_prototype" ] = getFunction( "maps/_zombiemode_prototype", "spectator_respawn" );
	level._custom_func_table[ "say_revived_vo" ] = getFunction( "maps/_laststand", "say_revived_vo" );
	level._end_of_round_funcs = [];
	level._end_of_round_funcs[ 0 ] = ::award_round_completion_xp;
	setDvar( "scr_xpscale", 1 );
}

init()
{
	level.zombie_counter_zombies = 0;
	SetDvar( "player_lastStandBleedoutTime", 45 );
	SetDvar( "g_fix_tesla_bug", 1 );
	SetDvar( "g_disable_zombie_grab", 1 );
	SetDvar( "perk_weaprateEnhanced", 1 );
	setDvar( "scr_damagefeedback", 1 );
	level thread enemy_counter_hud();
	level thread calculate_sph();
	level thread sph_hud();
	level thread insta_kill_rounds_tracker();
	level.sph_hud_counter = 0;
	level.zombie_kill_times = [];
	level thread on_player_connect();
	level thread add_trigger_callbacks();
}

add_trigger_callbacks()
{
	wait 1;
	use_triggers = getEntArray( "trigger_use", "classname" );
	for ( i = 0; i < use_triggers.size; i++ )
	{
		// This should never happen but if it does and this check isn't here...
		if ( !isDefined( use_triggers[ i ].targetname ) )
		{
			continue;
		}
		switch ( use_triggers[ i ].targetname )
		{
			case "zombie_debris":
			case "zombie_door":
			case "use_power_switch":
			case "use_master_switch":
				use_triggers[ i ] thread award_xp_for_purchased_trigger();
			default:
				break;
		}
	}
}

on_player_connect()
{
	level endon( "end_game" );
	while ( true )
	{
		level waittill( "connected", player );
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
	level.postInstaKillRounds = 0;
	while ( 1 )
	{
		level waittill( "start_of_round" );
		wait 0.5;
		health = undefined;
		if ( level.round_number >= 31 )
		{
			health = calculate_insta_kill_rounds();
			level.postInstaKillRounds++;
		}
		if ( !isDefined( health ) )
		{
			level.zombie_health = calculate_normal_health();
		}
		else 
		{
			level.zombie_health = health;
		}
		if ( level.roundIsInstaKill )
		{
			iprintln( "All zombies are insta kill this round" );
		}
	}
}

calculate_insta_kill_rounds()
{
	level.roundIsInstaKill = 0;
	if ( level.round_number >= 163 )
	{
		return undefined;
	}
	health = level.zombie_vars[ "zombie_health_start" ];
	for ( i = 2; i <= ( level.postInstaKillRounds + 163 ); i++ )
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
		level.roundIsInstaKill = 1;
		return 20;
	}
	return undefined;
}

calculate_normal_health()
{
	level.roundIsInstaKill = 0;
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
		level.roundIsInstaKill = 1;
		return 20;
	}
	return health;
}

award_round_completion_xp()
{
	xp_value = int( ( XP_FOR_ROUND_COMPLETION_BASE * level.round_number ) ); 
	if ( xp_value > XP_FOR_ROUND_COMPLETION_CAP )
	{
		xp_value = XP_FOR_ROUND_COMPLETION_CAP;
	}
	players = get_players();
	for ( i = 0; i < players.size; i++ )
	{
		player = players[ i ];
		player giveRankXP( "round_completion", xp_value );
		player iPrintlnBold( "+" + xp_value );
	}
}

mayProcessChallenges_override()
{
	return 1;
}

giveRankXP( type, value, levelEnd )
{
	self endon("disconnect");
	if(	!isDefined( levelEnd ) )
	{
		levelEnd = false;
	}	
	
	value = int( value * level.xpScale );

	switch( type )
	{
		case "challenge":
			self.summary_challenge += value;
			self.summary_xp += value;
			break;
		default:
			self.summary_xp += value;
			break;
	}
		
	self maps\_challenges_coop::incRankXP( value );

	if ( level.rankedMatch && maps\_challenges_coop::updateRank() && false == levelEnd )
		self thread maps\_challenges_coop::updateRankAnnounceHUD();

	// Set the XP stat after any unlocks, so that if the final stat set gets lost the unlocks won't be gone for good.
	self maps\_challenges_coop::syncXPStat();
}

ch_kills_override( victim )
{
	if ( !isDefined( victim.attacker ) || !isPlayer( victim.attacker ) || victim.team == "allies" )
		return;
	
	player = victim.attacker;

	xp_value = XP_PER_NORMAL_KILL;
	if ( victim.damagemod == "MOD_HEAD_SHOT" )
	{
		xp_value = XP_PER_HEAD_SHOT_KILL;
	}
	player giveRankXP( "kill", xp_value );
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

award_xp_for_purchased_trigger()
{
	level endon( "end_game" );
	level endon( "intermission" );

	while ( true )
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
			if ( self.targetname == "use_master_switch" || self.targetname == "use_power_switch" )
			{
				players = get_players();
				for ( i = 0; i < players.size; i++ )
				{
					players[ i ] giveRankXP( "purchase", 50 );
					players[ i ] iPrintlnBold( "+" + 50 );
				}
				break;
			}
		 	else if( isDefined( self.zombie_cost ) && who.score >= self.zombie_cost )
			{
				who giveRankXP( "purchase", 25 );
				who iPrintlnBold( "+" + 25 );
				break;
			}
		}
	}
}

revive_success_override( reviver )
{
	self notify ( "player_revived" );	
	self reviveplayer();
	
	//CODER_MOD: TOMMYK 06/26/2008 - For coop scoreboards
	reviver.revives++;
	//stat tracking
	reviver.stats["revives"] = reviver.revives;
	reviver giveRankXP( "purchase", 10 );
	reviver iPrintlnBold( "+" + 10 );
	// CODER MOD: TOMMY K - 07/30/08
	reviver thread maps\_arcademode::arcadeMode_player_revive();
	setClientSysState("lsm", "0", self);	// Notify client last stand ended.
	
	self.revivetrigger delete();
	self.revivetrigger = undefined;

	self maps\_laststand::laststand_giveback_player_weapons();
	
	self.ignoreme = false;
	
	if ( isDefined( level._custom_func_table[ "say_revived_vo" ] ) )
	{
		self thread [[ level._custom_func_table[ "say_revived_vo" ] ]]();
	}
}