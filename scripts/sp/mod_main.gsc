main()
{
	replaceFunc( maps/_zombiemode_utility::spawn_zombie, ::spawn_zombie_override );
}

init()
{
	SetDvar( "player_lastStandBleedoutTime", 45 );
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
	enemy_counter_hud.label = &"Enemies Remaining: ";

	flag_wait( "all_players_connected" );
	wait 10;

	enemy_counter_hud.alpha = 1;
	while (1)
	{
		enemies = get_enemy_count() + level.zombie_total;

		if (enemies == 0)
		{
			enemy_counter_hud setText("");
		}
		else
		{
			enemy_counter_hud setValue(enemies);
		}

		wait 0.05;
	}
}