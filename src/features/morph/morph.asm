; Morph: Interp (Sound byte $38) reads the wavetable the way the E352 and the
; Piston Honda MkII do, blending each sample between two adjacent waves.

morph_wave1_index:
	bsr.w	morph_interp
	bne.b	morph_wave1_position
	moveq	#0,d0
	move.b	SOUND_WAVE1_START_WAVE(a4),d0
	addq.w	#WAVE1_INDEX_ROUND_BIAS,d1
	asr.w	#1,d1
	add.w	d1,d0
	rts
morph_wave1_position:
	moveq	#0,d2
	move.w	VOICE_WAVE1_START_MOD+2(a3),d2
	swap	d1
	moveq	#0,d3
	move.w	d1,d3
	add.l	d3,d2
	swap	d1
	swap	d0
	move.w	d0,d3
	add.l	d3,d2
	move.w	d1,d3
	swap	d3
	clr.w	d3
	add.l	d3,d2
	move.l	d2,VOICE_WAVE1_START_MOD(a3)
	asr.l	#MORPH_HALF_WAVE_SHIFT,d2
	bsr.b	morph_wave1_start
	add.l	d2,d0
	swap	d0
	tst.w	d0
	rts

morph_wave1_start:
	move.b	SOUND_WAVE1_FINE(a4),d0
	bsr.b	morph_fine
	mulu.w	#MORPH_FINE_SCALE,d0
	moveq	#0,d1
	move.b	SOUND_WAVE1_START_WAVE(a4),d1
	swap	d1
	add.l	d1,d0
	rts

morph_fine:
	andi.l	#BYTE_MASK,d0
	cmpi.b	#MORPH_FINE_LAST,d0
	bls.b	morph_fine_done
	moveq	#MORPH_FINE_LAST,d0
morph_fine_done:
	rts

morph_interp:
	; Z set for XT (and values past the last).
	cmpi.b	#INTERP_LAST,SOUND_INTERP(a4)
	bhi.b	morph_interp_xt
	tst.b	SOUND_INTERP(a4)
	rts
morph_interp_xt:
	cmp.b	d0,d0
	rts

morph_wave2_index:
	bsr.w	morph_interp
	bne.b	morph_wave2_position
	add.w	d1,d0
	bmi.b	morph_wave2_negative
morph_wave2_limit:
	addq.l	#4,sp
	jmp	frame_osc2_wave_index_limit_select.l
morph_wave2_negative:
	rts
morph_wave2_position:
	add.w	d1,d0
	moveq	#0,d2
	tst.b	SOUND_WAVE2_LINK(a4)
	beq.b	morph_wave2_own
	move.w	VOICE_WAVE1_START_MOD+2(a3),d2
	bra.b	morph_wave2_sum
morph_wave2_own:
	move.w	VOICE_WAVE2_START_MOD+2(a3),d2
	swap	d1
	moveq	#0,d4
	move.w	d1,d4
	add.l	d4,d2
	swap	d3
	move.w	d3,d4
	add.l	d4,d2
morph_wave2_sum:
	move.w	d0,d4
	swap	d4
	clr.w	d4
	add.l	d4,d2
	move.b	SOUND_WAVE2_FINE(a4),d0
	bsr.b	morph_fine
	mulu.w	#MORPH_FINE_SCALE,d0
	add.l	d0,d0
	add.l	d0,d2
	move.l	d2,VOICE_WAVE2_START_MOD(a3)
	swap	d2
	move.w	d2,d0
	andi.w	#MORPH_EVEN_MASK,d0
	bmi.b	morph_wave2_negative
	bra.b	morph_wave2_limit

morph_edge_wave1:
	bsr.w	morph_interp
	bne.b	morph_edge_wave1_on
	move.l	d7,(a6)
	move.b	SOUND_MIX_NOISE(a4),d0
	rts
morph_edge_wave1_on:
	movem.l	d1-d2,-(sp)
	bsr.w	morph_wave1_start
	move.l	VOICE_WAVE1_START_MOD(a3),d1
	asr.l	#MORPH_HALF_WAVE_SHIFT,d1
	add.l	d1,d0
	moveq	#WAVE1_INDEX_LIMIT,d1
	tst.b	SOUND_WAVE1_LIMIT(a4)
	beq.b	morph_edge_wave1_word
	moveq	#WAVE1_INDEX_LIMIT_ALT,d1
morph_edge_wave1_word:
	moveq	#MORPH_STATE_WAVE1,d2
	bsr.b	morph_word
	movem.l	(sp)+,d1-d2
	moveq	#0,d0
	move.b	SOUND_MIX_NOISE(a4),d0
	rts

morph_edge_wave2:
	bsr.w	morph_interp
	bne.b	morph_edge_wave2_on
	move.l	d7,(a6)
	rts
morph_edge_wave2_on:
	movem.l	d1-d2,-(sp)
	move.l	VOICE_WAVE2_START_MOD(a3),d0
	asr.l	#MORPH_HALF_WAVE_SHIFT,d0
	moveq	#CONTROL_7BIT_MAX>>MORPH_HALF_WAVE_SHIFT,d1
	tst.b	SOUND_WAVE2_LIMIT(a4)
	beq.b	morph_edge_wave2_word
	moveq	#WAVE2_INDEX_LIMIT_ALT>>MORPH_HALF_WAVE_SHIFT,d1
morph_edge_wave2_word:
	moveq	#MORPH_STATE_WAVE2,d2
	bsr.b	morph_word
	movem.l	(sp)+,d1-d2
	rts

morph_word:
	movem.l	d3/a0,-(sp)
	moveq	#0,d3
	move.b	VOICE_PHYSICAL_VOICE_INDEX(a3),d3
	lsl.w	#MORPH_VOICE_SHIFT,d3
	add.w	d3,d2
	lea	MORPH_RAM.w,a0
	adda.w	d2,a0
	move.l	d0,d2
	asr.l	#MORPH_TRACE_SHIFT,d2
	andi.w	#MORPH_TRACE_MASK,d2
	move.w	(a0),d3
	eor.w	d2,d3
	cmpi.w	#MORPH_STILL,d3
	bhi.b	morph_word_moved
	addq.w	#MORPH_STILL,d2
	moveq	#MORPH_EASE,d3
morph_word_moved:
	andi.w	#MORPH_EASE,d3
	move.w	d2,(a0)
	bsr.b	morph_word_blend
	or.w	d3,d0
	move.l	d0,(a6)
	movem.l	(sp)+,d3/a0
	rts

morph_word_blend:
	tst.l	d0
	bmi.b	morph_word_none
	move.l	d0,d2
	swap	d2
	cmp.w	d1,d2
	bhs.b	morph_word_none
	andi.l	#WORD_MASK,d0
	lsl.l	#MORPH_FRACTION_SHIFT,d0
	bra.b	morph_word_send
morph_word_none:
	moveq	#0,d0
morph_word_send:
	ori.l	#MORPH_EDGE_BIAS,d0
	rts

morph_sound_xt:
	move.b	SOUND_INTERP(a0),d0
	subq.b	#INTERP_E352,d0
	cmpi.b	#INTERP_LAST-INTERP_E352,d0
	rts

morph_dial_step:
	movem.l	d1-d2/a0-a1,-(sp)
	moveq	#SOUND_WAVE1_FINE,d1
	cmpi.w	#SOUND_WAVE1_START_WAVE,d5
	beq.b	morph_dial_step_interp
	moveq	#SOUND_WAVE2_FINE,d1
	cmpi.w	#SOUND_WAVE2_START_WAVE,d5
	bne.b	morph_dial_step_stock
morph_dial_step_interp:
	movea.l	a2,a0
	bsr.b	morph_sound_xt
	bhi.b	morph_dial_step_stock
	jsr	is_panel_shift_held.l
	tst.w	d0
	beq.b	morph_dial_step_stock
	adda.w	d1,a0
	move.b	(a0),d0
	bsr.w	morph_fine
	move.w	d0,d1
	move.w	d4,d0
	mulu.w	#MORPH_FINE_STEPS,d0
	add.w	d1,d0
	add.w	d3,d0
	bpl.b	morph_dial_step_top
	moveq	#0,d0
morph_dial_step_top:
	moveq	#0,d1
	move.b	UI_PARAMETER_METADATA_MAX_OFFSET(a3),d1
	mulu.w	#MORPH_FINE_STEPS,d1
	cmp.w	d1,d0
	ble.b	morph_dial_step_split
	move.w	d1,d0
morph_dial_step_split:
	ext.l	d0
	divu.w	#MORPH_FINE_STEPS,d0
	move.w	d0,d4
	swap	d0
	move.b	d0,(a0)
	tst.b	GLOBAL_PARAMETER_SEND.l
	beq.b	morph_dial_step_done
	move.l	a0,d0
	sub.l	a2,d0
	move.l	a2,d1
	jsr	platform_send_parameter_change.l
morph_dial_step_done:
	moveq	#0,d0
	movem.l	(sp)+,d1-d2/a0-a1
	rts
morph_dial_step_stock:
	move.b	UI_PARAMETER_METADATA_STEP_OFFSET(a3),d0
	ext.w	d0
	movem.l	(sp)+,d1-d2/a0-a1
	rts

morph_dispatch_selector:
	move.w	d0,d6
	cmpi.w	#SOUND_WAVE1_FINE,d6
	bne.b	morph_dispatch_selector_wave2
	moveq	#SOUND_WAVE1_START_WAVE,d6
morph_dispatch_selector_wave2:
	cmpi.w	#SOUND_WAVE2_FINE,d6
	bne.b	morph_dispatch_selector_done
	moveq	#SOUND_WAVE2_START_WAVE,d6
morph_dispatch_selector_done:
	movea.l	d1,a2
	clr.w	d5
	rts

morph_display:
	cmpi.b	#INTERP_FORMAT,d1
	beq.w	morph_display_interp
	cmpi.b	#WAVE1_POSITION_FORMAT,d1
	beq.b	morph_display_wave1
	cmpi.b	#WAVE2_POSITION_FORMAT,d1
	beq.b	morph_display_wave2
	bra.w	warp_amount_display
morph_display_wave1:
	moveq	#SOUND_WAVE1_FINE,d1
	bra.b	morph_display_position
morph_display_wave2:
	moveq	#SOUND_WAVE2_FINE,d1
morph_display_position:
	movem.l	d1-d2,-(sp)
	jsr	ui_get_edited_sound.l
	movea.l	d0,a0
	movem.l	(sp)+,d1-d2
	bsr.w	morph_sound_xt
	bhi.b	morph_display_whole
	move.b	(a0,d1.w),d0
	bsr.w	morph_fine
	tst.w	d0
	beq.b	morph_display_whole
	move.l	d2,-(sp)
	movea.l	d2,a0
	move.l	#'    ',(a0)
	move.l	#'    ',4(a0)
	addq.w	#MORPH_POSITION_COLUMN,a0
	move.l	d0,d2
	moveq	#0,d0
	move.b	d3,d0
	moveq	#MORPH_POSITION_DIGITS,d1
	jsr	UI_FORMAT_DECIMAL_COUNTED.l
	move.b	#'.',MORPH_POSITION_DIGITS(a0)
	addq.w	#MORPH_POSITION_DIGITS+1,a0
	move.l	d2,d0
	moveq	#MORPH_POSITION_DIGITS,d1
	jsr	UI_FORMAT_DECIMAL_COUNTED.l
	move.l	(sp)+,d2
	jmp	ui_dispatch_display_parameter_return.l
morph_display_whole:
	move.l	d2,d1
	move.w	d3,d0
	jsr	UI_FORMAT_WAVEFORM.l
	jmp	ui_dispatch_display_parameter_return.l
morph_display_interp:
	movea.l	d2,a0
	lea	morph_names(pc),a1
	move.w	d3,d0
	cmpi.w	#INTERP_LAST,d0
	bls.b	morph_display_known
	moveq	#INTERP_XT,d0
morph_display_known:
	mulu.w	#INTERP_NAME_CHARS,d0
	adda.w	d0,a1
	moveq	#INTERP_NAME_CHARS-1,d0
morph_display_char:
	move.b	(a1)+,(a0)+
	dbf	d0,morph_display_char
	jmp	ui_dispatch_display_parameter_return.l

morph_names:
	dc.b	"   XT    "
	dc.b	"  E352   "
	dc.b	"  Honda  "
morph_parameter_name:
	dc.b	"Interp",0
morph_page_caption:
	dc.b	" Interpolation",0
morph_page_title:
	dc.b	"[Interpolation]",0
	if	(*-morph_names)&1
	dc.b	0
	endif
