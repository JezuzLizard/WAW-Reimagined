
main()
{
	replaceFunc( maps\_zombiemode_tesla::tesla_arc_damage, scripts\sp\nazi_zombie_factory\factory_main::tesla_arc_damage_override );
	replaceFunc( maps\_zombiemode_tesla::tesla_end_arc_damage, scripts\sp\nazi_zombie_factory\factory_main::tesla_end_arc_damage_override );
	// replaceFunc( maps\_zombiemode::round_think, scripts\sp\nazi_zombie_factory\factory_main::round_think_override );
	replaceFunc( maps\_zombiemode::round_wait, scripts\sp\nazi_zombie_factory\factory_main::round_wait_override );
	replaceFunc( maps\_zombiemode::round_spawning, scripts\sp\nazi_zombie_factory\factory_main::round_spawning_override );
	replaceFunc( maps\nazi_zombie_factory::electric_trap_think, scripts\sp\factory_main::electric_trap_think_override );
	replaceFunc( maps\nazi_zombie_factory::include_powerups, scripts\sp\factory_main::include_powerups_override );
	replaceFunc( maps\nazi_zombie_factory::include_weapons, scripts\sp\factory_main::include_weapons_override );
}