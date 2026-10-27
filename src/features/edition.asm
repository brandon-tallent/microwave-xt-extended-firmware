; Tallent Edition code shared by the features: assembled first in the
; extension, before each feature's own file.

edition_display_dispatch:
	cmpi.w	#ui_display_parameter_selector_max,d0
	bhi.b	edition_display_extended
	jmp	ui_dispatch_display_parameter_in_range.l
edition_display_extended:
	cmpi.b	#MPE_Y_CC_FORMAT,d1
	beq.w	mpe_display_y_cc
	cmpi.b	#MPE_MODE_FORMAT,d1
	beq.w	mpe_display_mode
	cmpi.b	#OSC2_TABLE_FORMAT,d1
	beq.w	osc2_table_display
	cmpi.b	#XMOD_FORMAT,d1
	beq.w	xmod_display
	cmpi.b	#WARP_FORMAT,d1
	beq.w	warp_display
	jmp	honda_display.l
