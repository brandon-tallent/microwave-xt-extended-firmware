; X-Mod: the mode and parameter names (features/region_ramp.asm).

xmod_mode_names:
	dc.b	" FM 2>1  "
	dc.b	" PM 2>1  "
	dc.b	" AM 2>1  "
	dc.b	" FM 1>2  "
	dc.b	" PM 1>2  "
xmod_parameter_name:
	dc.b	"X-Mod",0
	if	(*-xmod_mode_names)&1
	dc.b	0
	endif
