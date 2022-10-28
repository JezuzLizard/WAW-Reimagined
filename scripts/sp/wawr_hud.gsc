#define OVERFLOW_MAX_STRINGS 20

init()
{
	level.wawr_text_hud_marker = newHudElem();
	level.wawr_text_hud_marker setText( "OverflowFix" );
	level.wawr_text_hud_marker.alpha = 0;
}

restore_hud_text()
{
	for ( i = 0; i < level.wawr_text_hud_elems.size; i++ )
	{
		level.wawr_text_hud_elems[ i ] setText( level.wawr_text_hud_elems[ i ].current_text );
	}
}

clear_hud_text()
{
	level.wawr_text_hud_marker clearAllTextAfterHudElem();
	for ( i = 0; i < level.wawr_text_hud_elems.size; i++ )
	{
		level.wawr_text_hud_elems[ i ] setText( "" );
	}
	level.overflow_fix_current_string_count = 0;
}

find_free_index_for_hud_elem()
{
	for ( i = 0; i < level.wawr_text_hud_elems; i++ )
	{
		if ( !isDefined( level.wawr_text_hud_elems[ i ] ) )
		{
			return i;
		}
	}
	return level.wawr_text_hud_elems.size;
}

register_hud_overflow_fix_for_hudelem( hudelem, current_text )
{
	if ( !isDefined( level.wawr_text_hud_elems ) )
	{
		level.wawr_text_hud_elems = [];
	}
	if ( !isDefined( hudelem.overflow_fix_index ) )
	{
		free_index = find_free_index_for_hud_elem();
		level.wawr_text_hud_elems[ free_index ] = hudelem;
		hudelem.overflow_fix_index = free_index;
	}
	hudelem.current_text = current_text;
}

unregister_hud_overflow_fix_for_hudelem( hudelem )
{
	index = hudelem.overflow_fix_index;
	level.wawr_text_hud_elems[ index ] destroy();
}

set_safe_text( text )
{
	if ( !isDefined( level.overflow_fix_current_string_count ) )
	{
		level.overflow_fix_current_string_count = 0;
	}
	if ( level.overflow_fix_current_string_count > OVERFLOW_MAX_STRINGS )
	{
		clear_hud_text();
		restore_hud_text();
	}
	self setText( text );
	register_hud_overflow_fix_for_hudelem( self, text );
	level.overflow_fix_current_string_count++;
}