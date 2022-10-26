#include maps\_utility;
#include common_scripts\utility;	

main()
{
	replaceFunc( maps\_zombiemode_asylum::spectators_respawn, scripts\sp\wawr_common_functions::spectators_respawn_override );
}