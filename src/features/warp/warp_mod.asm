; ---- Matrix pass (synthesis/frames/modulation.asm) ----

warp_mod_set:
	cmpi.b	#MOD_DEST_W1_WARP,d0
	bhs.b	warp_mod_sum
	move.l	d1,VOICE_MODULATION_ACCUMULATOR_BASE(a3,d0.w*4)
	rts
warp_mod_add:
	cmpi.b	#MOD_DEST_W1_WARP,d0
	bhs.b	warp_mod_sum
	add.l	d1,VOICE_MODULATION_ACCUMULATOR_BASE(a3,d0.w*4)
	rts
warp_mod_sum:
	; W1/W2 Warp: add to the voice's sum, which warp_frame_emit clears, so a
	; first slot adds too.
	moveq	#0,d2
	move.b	VOICE_PHYSICAL_VOICE_INDEX(a3),d2
	add.w	d2,d2
	add.w	d0,d2
	move.l	a1,-(sp)
	lea	WARP_MOD_RAM-4*MOD_DEST_W1_WARP.w,a1
	add.l	d1,(a1,d2.w*4)
	movea.l	(sp)+,a1
	rts

; ---- Destination menu ----

warp_dest_names:
	lea	UI_MODULATION_DESTINATION_NAMES(pc),a1
	cmpi.w	#MOD_DEST_W1_WARP,d0
	blo.b	warp_dest_names_stock
	lea	warp_dest_name_records-MOD_DEST_W1_WARP*MOD_DEST_NAME_CHARS(pc),a1
warp_dest_names_stock:
	rts

warp_dest_order_a2:
	lea	warp_dest_order(pc),a2
	clr.l	d0
	rts

warp_dest_order_a0:
	lea	warp_dest_order(pc),a0
	clr.w	d3
	rts

warp_dest_name_records:
	dc.b	"W1 Warp  "
	dc.b	"W2 Warp  "

warp_dest_order:
	; Menu position -> destination: v2.33's ui_mod_dest_order_table with W1 and
	; W2 Warp after FM Amount.
	dc.b	0,1,34,MOD_DEST_W1_WARP,MOD_DEST_W2_WARP,2,3,4,5,6,7,8,9,10,35,11
	dc.b	12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27
	dc.b	28,29,30,31,32,33
	if	*-warp_dest_order<>MOD_DEST_ORDER_COUNT
	error	"warp_dest_order needs one entry a destination"
	endif
