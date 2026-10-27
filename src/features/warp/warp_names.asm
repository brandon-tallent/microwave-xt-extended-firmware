; Warp: the mode and parameter names (features/region_demo.asm).

warp_mode_names:
	dc.b	"   Off   "
	dc.b	" Bend +  "
	dc.b	" Bend -  "
	dc.b	"Bend +/- "
	dc.b	"   PWM   "
	dc.b	" Asym +  "
	dc.b	" Asym -  "
	dc.b	"Asym +/- "
	dc.b	" Mirror  "
	dc.b	"Quantize "
	if	*-warp_mode_names<>WARP_MODE_NAME_CHARS*(WARP_MODE_LAST+1)
	error	"warp_mode_names needs one name a mode"
	endif
warp1_parameter_name:
	dc.b	"W1 Warp",0
warp2_parameter_name:
	dc.b	"W2 Warp",0
warp_amount_parameter_name:
	dc.b	"Warp Amt",0
	if	(*-warp_mode_names)&1
	dc.b	0
	endif
