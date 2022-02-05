
main()
{
	replaceFunc( maps\_zombiemode_tesla::tesla_arc_damage, scripts\sp\nazi_zombie_factory\factory_main::tesla_arc_damage_override );
	replaceFunc( maps\_zombiemode_tesla::tesla_end_arc_damage, scripts\sp\nazi_zombie_factory\factory_main::tesla_end_arc_damage_override );
	// replaceFunc( maps\_zombiemode::round_think, scripts\sp\nazi_zombie_factory\factory_main::round_think_override );
	replaceFunc( maps\_zombiemode::round_wait, scripts\sp\nazi_zombie_factory\factory_main::round_wait_override );
	replaceFunc( maps\_zombiemode::round_spawning, scripts\sp\nazi_zombie_factory\factory_main::round_spawning_override );
	replaceFunc( maps\nazi_zombie_factory::electric_trap_think, scripts\sp\nazi_zombie_factory\factory_main::electric_trap_think_override );
	replaceFunc( maps\nazi_zombie_factory::include_powerups, scripts\sp\nazi_zombie_factory\factory_main::include_powerups_override );
	replaceFunc( maps\nazi_zombie_factory::include_weapons, scripts\sp\nazi_zombie_factory\factory_main::include_weapons_override );
	replaceFunc( maps\_zombiemode_powerups::nuke_powerup, scripts\sp\nazi_zombie_factory\factory_main::nuke_powerup_override );
	replaceFunc( maps\nazi_zombie_factory_teleporter::teleport_pad_active_think, scripts\sp\nazi_zombie_factory\factory_main::teleport_pad_active_think_override );
	replaceFunc( maps\_zombiemode_powerups::special_drop_setup, scripts\sp\nazi_zombie_factory\factory_main::special_drop_setup_override );
	level thread scripts\sp\nazi_zombie_factory\factory_main::reset_teleporter_cost();
}