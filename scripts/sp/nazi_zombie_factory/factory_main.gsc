#include maps\_zombiemode_tesla;
#include maps\_zombiemode_utility;
#include maps\_utility;
#include common_scripts\utility;

main()
{
	replaceFunc( maps\_zombiemode_tesla::tesla_arc_damage, ::tesla_arc_damage_override );
	replaceFunc( maps\_zombiemode_tesla::tesla_end_arc_damage, ::tesla_end_arc_damage_override );
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