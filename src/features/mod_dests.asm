; ---- Matrix pass (synthesis/frames/modulation.asm) ----

mod_dest_set:
	cmpi.b	#MOD_DEST_W1_WARP,d0
	bhs.b	mod_dest_edition
	move.l	d1,VOICE_MODULATION_ACCUMULATOR_BASE(a3,d0.w*4)
	rts
mod_dest_add:
	cmpi.b	#MOD_DEST_W1_WARP,d0
	bhs.b	mod_dest_edition
	add.l	d1,VOICE_MODULATION_ACCUMULATOR_BASE(a3,d0.w*4)
	rts
mod_dest_edition:
	; Each edition destination adds to a sum that its reader clears, so a first
	; slot adds too.
	move.l	a1,-(sp)
	move.w	d0,d2
	lea	FXPARA_SUMS-4*MOD_DEST_FX_PARA_1.w,a1
	cmpi.b	#MOD_DEST_FX_PARA_1,d0
	bhs.b	mod_dest_fx_para
	; W1/W2 Warp: the voice's sum.
	moveq	#0,d2
	move.b	VOICE_PHYSICAL_VOICE_INDEX(a3),d2
	add.w	d2,d2
	add.w	d0,d2
	lea	WARP_MOD_RAM-4*MOD_DEST_W1_WARP.w,a1
mod_dest_fx_para:
	add.l	d1,(a1,d2.w*4)
	movea.l	(sp)+,a1
	rts

; ---- Destination menu ----

mod_dest_names:
	lea	UI_MODULATION_DESTINATION_NAMES(pc),a1
	cmpi.w	#MOD_DEST_W1_WARP,d0
	blo.b	mod_dest_names_stock
	lea	mod_dest_name_records-MOD_DEST_W1_WARP*MOD_DEST_NAME_CHARS(pc),a1
mod_dest_names_stock:
	rts

mod_dest_order_a2:
	lea	mod_dest_order(pc),a2
	clr.l	d0
	rts

mod_dest_name_records:
	; One name a destination from MOD_DEST_W1_WARP, as the [Effect] page names
	; the FX Para settings.
	dc.b	"W1 Warp  "
	dc.b	"W2 Warp  "
	dc.b	"FX Para 1"
	dc.b	"FX Para 2"
	dc.b	"FX Para 3"
	if	*-mod_dest_name_records<>(MOD_DEST_LAST+1-MOD_DEST_W1_WARP)*MOD_DEST_NAME_CHARS
	error	"mod_dest_name_records needs one name an edition destination"
	endif

mod_dest_order:
	; Menu position -> destination: v2.33's ui_mod_dest_order_table with W1 and
	; W2 Warp after FM Amount and FX Para 1-3 after Volume (12).
	dc.b	0,1,34
mod_dest_order_warps:
	dc.b	MOD_DEST_W1_WARP,MOD_DEST_W2_WARP,2,3,4,5,6,7,8,9,10,35,11
	dc.b	12,MOD_DEST_FX_PARA_1,MOD_DEST_FX_PARA_2,MOD_DEST_FX_PARA_3,13,14,15,16,17,18,19,20,21,22,23,24
	dc.b	25,26,27,28,29,30,31,32,33
	if	*-mod_dest_order<>MOD_DEST_ORDER_COUNT
	error	"mod_dest_order needs one entry a destination"
	endif
MOD_DEST_ORDER_W1    equ  mod_dest_order_warps-mod_dest_order
MOD_DEST_ORDER_W2    equ  MOD_DEST_ORDER_W1+1
