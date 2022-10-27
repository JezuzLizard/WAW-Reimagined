#include maps\_utility;
#include common_scripts\utility;

main()
{
	replaceFunc( maps\_zombiemode_prototype::round_wait, scripts\sp\wawr_common_functions::round_wait_override );
	replaceFunc( maps\_zombiemode_prototype::round_spawning, scripts\sp\wawr_common_functions::round_spawning_override );
	replaceFunc( maps\_zombiemode_prototype::spectators_respawn, scripts\sp\wawr_common_functions::spectators_respawn_override );
}