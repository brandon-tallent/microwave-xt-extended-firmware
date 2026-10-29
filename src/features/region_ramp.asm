; The fourth extension region, in the space of v2.33's
; platform_render_wave_table_ramp (144 bytes from $114a2c), which nothing in
; the ROM calls: the X-Mod name tables and display, the destination editor's
; reader of the destination menu and the Shift + dial pairs, reached by
; absolute address or from the demo region.
	include	"features/xmod/xmod_names.asm"
	include	"features/xmod/xmod_display.asm"
	include	"features/mod_dest_menu.asm"
	include	"features/osc_bank_shift.asm"
