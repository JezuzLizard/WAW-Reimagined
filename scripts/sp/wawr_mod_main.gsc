#include maps\_utility;
#include common_scripts\utility;
#include scripts\sp\wawr_utility;

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

	dog_health_increase_func = getFunction( "maps/_zombiemode_dogs", "dog_health_increase" );
	if ( isDefined( dog_health_increase_func ) )
	{
		replaceFunc( dog_health_increase_func, scripts\sp\wawr_common_functions::dog_health_increase_override );
	}
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
	replaceFunc( common_scripts\utility::struct_class_init, scripts\sp\wawr_utility::struct_class_init_override );
	if ( !isDefined( level._custom_funcs_table ) )
	{
		level._custom_funcs_table = [];
	}
	level._custom_func_table[ "special_dog_spawn" ] = getFunction( "maps/_zombiemode_dogs", "special_dog_spawn" );
	level._custom_func_table[ "is_magic_bullet_shield_enabled" ] = getFunction( "maps/_zombiemode_utility", "is_magic_bullet_shield_enabled" );
	level._custom_func_table[ "enemy_is_dog" ] = getFunction( "maps/_zombiemode_utility", "enemy_is_dog" );
	level._custom_func_table[ "spectator_respawn_prototype" ] = getFunction( "maps/_zombiemode_prototype", "spectator_respawn" );
	level._end_of_round_funcs = [];
	level._end_of_round_funcs[ 0 ] = ::increase_max_drops_based_on_round;
	level._start_of_round_funcs = [];
	level._start_of_round_funcs[ 0 ] = ::reset_first_nuke_of_round;
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
	setDvar( "player_backspeedscale", 1 );
	setDvar( "player_strafespeedscale", 1 );
	level thread enemy_counter_hud();
	level thread calculate_sph();
	level thread sph_hud();
	level.sph_hud_counter = 0;
	level.zombie_kill_times = [];

	level.zombie_vars["zombie_spawn_delay"] = 1.5;
	level.starting_zombie_spawn_delay = 1.5;
	level.shock_onpain = false;
	level.callbackActorDamage = ::Callback_ActorDamage;
	register_weapon_actor_damage_callback( "ray_gun", ::ray_gun_bonus_damage );
	register_weapon_actor_damage_callback( "ray_gun_upgraded", ::ray_gun_upgraded_bonus_damage );
	level.zombie_health_bonus_func = ::monkey_in_fire_zombie_health_bonus;
	level.dog_health_bonus_func = ::monkey_in_fire_dog_health_bonus;
	level.zombie_movespeed_bonus_func = ::monkey_in_fire_zombie_bonus_speed;
	level.zombie_spawnrate_bonus_func = ::monkey_in_fire_zombie_bonus_spawnrate;
	level.wawr_init_done = true;
}

on_player_connect()
{
	level endon( "end_game" );
	while ( true )
	{
		level waittill( "connected", player );
		//player thread spawn_random_hudelems();
		player thread health_bar_hud();
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
	enemy_counter_hud.aligny = "middle";
	enemy_counter_hud.horzalign = "left";
	enemy_counter_hud.vertalign = "middle";
	enemy_counter_hud.x += 5;
	enemy_counter_hud.y += 100;
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
	enemy_counter_hud.aligny = "middle";
	enemy_counter_hud.horzalign = "left";
	enemy_counter_hud.vertalign = "middle";
	enemy_counter_hud.x += 5;
	enemy_counter_hud.y += 112;
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
	self.hud_damagefeedback setShader( "damage_feedback", 24, 48 );

	self.hud_damagefeedback_kill = newClientHudElem( self );
	self.hud_damagefeedback_kill.alignX = "center";
	self.hud_damagefeedback_kill.alignY = "middle";
	self.hud_damagefeedback_kill.horzAlign = "center";
	self.hud_damagefeedback_kill.vertAlign = "middle";
	self.hud_damagefeedback_kill.alpha = 0;
	self.hud_damagefeedback_kill.archived = true;
	self.hud_damagefeedback_kill.color = ( 1, 0, 0 );
	self.hud_damagefeedback_kill setShader( "damage_feedback", 24, 48 );
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
		if ( !isDefined( self ) || !isAlive( self ) )
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

increase_max_drops_based_on_round()
{
	level.zombie_vars[ "zombie_powerup_drop_max_per_round" ] = 4 + int( floor( level.round_number * 0.05 ) );
}



reset_first_nuke_of_round()
{
	level.first_nuke_of_the_round = false;
}

health_bar_hud()
{
	level endon( "end_game" );
	self endon("disconnect");
	health_bar = self maps\_hud_util::createBar( (1, 1, 1), level.primaryProgressBarWidth, level.primaryProgressBarHeight );
	health_bar endon( "destroyed" );
	health_bar.hidewheninmenu = 1;
	health_bar.bar.hidewheninmenu = 1;
	health_bar.barframe.hidewheninmenu = 1;
	health_bar.alignx = "left";
	health_bar.aligny = "middle";
	health_bar.horzalign = "left";
	health_bar.vertalign = "middle";
	health_bar.bar.alignx = "left";
	health_bar.bar.aligny = "middle";
	health_bar.bar.horzalign = "left";
	health_bar.bar.vertalign = "middle";
	health_bar.barFrame.alignx = "left";
	health_bar.barFrame.aligny = "middle";
	health_bar.barFrame.horzalign = "left";
	health_bar.barFrame.vertalign = "middle";
	health_bar.x += 5;
	health_bar.bar.x += 5;
	health_bar.barFrame.x += 5;
	health_bar.y += 134;
	health_bar.bar.y += 134;
	health_bar.barFrame.y += 134;
	health_bar_text = maps\_hud_util::createfontstring( "objective", 1.4, self );
	health_bar_text.hidewheninmenu = 1;
	health_bar_text.alignx = "left";
	health_bar_text.aligny = "middle";
	health_bar_text.horzalign = "left";
	health_bar_text.vertalign = "middle";
	health_bar_text.x += 56;
	health_bar_text.y += 134;
	health_bar thread cleanup_health_bar_on_intermission( self );
	health_bar_text thread cleanup_health_bar_on_intermission( self );

	while ( true )
	{
		if ( !maps\_zombiemode_utility::is_player_valid( self ) || self maps\_laststand::player_is_in_laststand() )
		{
			if (health_bar.alpha != 0)
			{
				health_bar.alpha = 0;
				health_bar.bar.alpha = 0;
				health_bar.barframe.alpha = 0;
				health_bar_text.alpha = 0;
			}
			wait 1;
			continue;
		}
		if ( health_bar.alpha != 0.8 )
		{
			health_bar fadeOverTime( 0.25 );
			health_bar.alpha = 0.8;
			health_bar.bar fadeOverTime( 0.25 );
			health_bar.bar.alpha = 0.8;
			health_bar.barframe fadeOverTime( 0.25 );
			health_bar.barframe.alpha = 0.8;
			health_bar_text fadeOverTime( 0.25 );
			health_bar_text.alpha = 0.8;
			wait 0.25;
		}
		health_bar maps\_hud_util::updatebar( self.health / self.maxhealth );
		health_bar_text setvalue( self.health );
		wait 0.05;
	}
}

cleanup_health_bar_on_intermission( player )
{
	player endon( "disconnect" );
	level waittill( "intermission" );
	self notify( "destroyed" );
	self maps\_hud_util::destroyelem();
}

spawn_random_hudelems()
{
	for ( i = 0; i < 50; i++ )
	{
		text = maps\_hud_util::createfontstring( "objective", 1.4, self );
		text.alignx = "center";
		text.aligny = "middle";
		text.horzalign = "center";
		text.vertalign = "middle";
		text.x = randomIntRange( -100, 100 );
		text.y = randomIntRange( -100, 100 );
		text.alpha = ( i % 2 ) == 0;
		text setValue( i );
	}
}

Callback_ActorDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, iModelIndex, iTimeOffset )
{

	if ( isDefined( sWeapon ) && isDefined( level.weapon_actor_damage_callbacks ) && isDefined( level.weapon_actor_damage_callbacks[ sWeapon ] ) )
	{
		iDamage = self [[ level.weapon_actor_damage_callbacks[ sWeapon ] ]]( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, iModelIndex, iTimeOffset );
	}

	self FinishActorDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, iModelIndex, iTimeOffset );
}

ray_gun_bonus_damage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, iModelIndex, iTimeOffset )
{
	bonus_damage_flat = 25 * level.round_number;
	bonus_damage_percent = 0.10;
	if ( isDefined( self.animname ) && self.animname == "zombie" && !is_true( self.has_legs ) )
	{
		bonus_damage_percent += 0.10;
	}
	iDamage = iDamage + bonus_damage_flat + int( self.maxhealth * bonus_damage_percent );

	return iDamage;
}

ray_gun_upgraded_bonus_damage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, iModelIndex, iTimeOffset )
{
	bonus_damage_flat = 50 * level.round_number;
	bonus_damage_percent = 0.15;
	if ( isDefined( self.animname ) && self.animname == "zombie" && !is_true( self.has_legs ) )
	{
		bonus_damage_percent += 0.15;
	}
	iDamage = iDamage + bonus_damage_flat + int( self.maxhealth * bonus_damage_percent );

	return iDamage;	
}

monkey_in_fire_zombie_health_bonus()
{
	if ( !isDefined( level.ee_world_difficulty ) || level.ee_world_difficulty <= 0 )
	{
		return 0;
	}
	health = 0;
	for ( i = 0; i < level.ee_world_difficulty; i++ )
	{
		health += int( level.zombie_health + level.zombie_vars["zombie_health_increase"] );
		health += int( level.zombie_health * ( level.zombie_vars["zombie_health_increase_percent"] / 100 ) );
	}
	return health;
}

monkey_in_fire_dog_health_bonus()
{
	if ( !isDefined( level.ee_world_difficulty ) || level.ee_world_difficulty <= 0 )
	{
		return;
	}
	for ( i = 0; i < level.ee_world_difficulty; i++ )
	{
		level.dog_health += 50;
	}
}

monkey_in_fire_zombie_bonus_speed()
{
	if ( !isDefined( level.ee_world_difficulty ) || level.ee_world_difficulty <= 0 )
	{
		return;
	}
	level.zombie_move_speed += level.ee_world_difficulty * 8;
}

monkey_in_fire_zombie_bonus_spawnrate()
{
	if ( !isDefined( level.ee_world_difficulty ) || level.ee_world_difficulty <= 0 )
	{
		return;
	}
	timer = level.zombie_vars[ "zombie_spawn_delay" ];
	for ( i = 1; i <= level.ee_world_difficulty; i++ )
	{
		if ( timer > 0.08 )
		{
			timer = timer * 0.95;
			continue;
		}

		if ( timer < 0.08 )
		{
			timer = 0.08;
			break;
		}
	}
	level.zombie_vars[ "zombie_spawn_delay" ] = timer;
}