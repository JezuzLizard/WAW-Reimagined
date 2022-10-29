struct_class_init_override()
{
	assertEx( !isdefined( level.struct_class_names ), "level.struct_class_names is being initialized in the wrong place! It shouldn't be initialized yet." );
	
	level.struct_class_names = [];
	level.struct_class_names[ "target" ] = [];
	level.struct_class_names[ "targetname" ] = [];
	level.struct_class_names[ "script_noteworthy" ] = [];
	level.struct_class_names[ "script_linkname" ] = [];
	
	for ( i=0; i < level.struct.size; i++ )
	{
		add_struct( level.struct[ i ] );
	}
	if ( !isDefined( level._custom_structs ) || level._custom_structs.size < 1 )
	{
		return;
	}
	for ( i = 0; i < level._custom_structs; i++ )
	{
		add_struct( level._custom_structs[ i ] );
	}
}

add_struct( s_struct )
{
	if ( isDefined( s_struct.targetname ) )
	{
		if ( !isDefined( level.struct_class_names[ "targetname" ][ s_struct.targetname ] ) )
		{
			level.struct_class_names[ "targetname" ][ s_struct.targetname ] = [];
		}
		size = level.struct_class_names[ "targetname" ][ s_struct.targetname ].size;
		level.struct_class_names[ "targetname" ][ s_struct.targetname ][ size ] = s_struct;
	}
	if ( isDefined( s_struct.script_noteworthy ) )
	{
		if ( !isDefined( level.struct_class_names[ "script_noteworthy" ][ s_struct.script_noteworthy ] ) )
		{
			level.struct_class_names[ "script_noteworthy" ][ s_struct.script_noteworthy ] = [];
		}
		size = level.struct_class_names[ "script_noteworthy" ][ s_struct.script_noteworthy ].size;
		level.struct_class_names[ "script_noteworthy" ][ s_struct.script_noteworthy ][ size ] = s_struct;
	}
	if ( isDefined( s_struct.target ) )
	{
		if ( !isDefined( level.struct_class_names[ "target" ][ s_struct.target ] ) )
		{
			level.struct_class_names[ "target" ][ s_struct.target ] = [];
		}
		size = level.struct_class_names[ "target" ][ s_struct.target ].size;
		level.struct_class_names[ "target" ][ s_struct.target ][ size ] = s_struct;
	}
	if ( isDefined( s_struct.script_linkname ) )
	{
		level.struct_class_names[ "script_linkname" ][ s_struct.script_linkname ][ 0 ] = s_struct;
	}
}

register_perk_struct( name, model, origin, angles )
{
	perk_struct = spawnStruct();
	perk_struct.script_noteworthy = name;
	perk_struct.model = model;
	perk_struct.angles = angles;
	perk_struct.origin = origin;
	perk_struct.targetname = "zm_perk_machine";

	if ( name == "specialty_weapupgrade" )
	{
		flag_struct = spawnStruct();
		flag_struct.targetname = "weapupgrade_flag_targ";
		flag_struct.model = "zombie_sign_please_wait";
		flag_struct.angles = angles + ( 0, 180, 180 );
		flag_struct.origin = origin + ( anglesToForward( angles ) * 29 ) + ( anglesToRight( angles ) * -13.5 ) + ( anglesToUp( angles ) * 49.5 );
		perk_struct.target = flag_struct.targetname;
		add_struct( flag_struct );
	}

	add_struct( perk_struct );
}