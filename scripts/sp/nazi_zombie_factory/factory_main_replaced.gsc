
main()
{
	replaceFunc( maps\_zombiemode_tesla::tesla_arc_damage, scripts\sp\nazi_zombie_factory\factory_main::tesla_arc_damage_override );
	replaceFunc( maps\_zombiemode_tesla::tesla_end_arc_damage, scripts\sp\nazi_zombie_factory\factory_main::tesla_end_arc_damage_override );
	// replaceFunc( maps\_zombiemode::round_think, scripts\sp\nazi_zombie_factory\factory_main::round_think_override );
	replaceFunc( maps\_zombiemode::round_wait, scripts\sp\nazi_zombie_factory\factory_main::round_wait_override );
	replaceFunc( maps\_zombiemode::round_spawning, scripts\sp\nazi_zombie_factory\factory_main::round_spawning_override );
}