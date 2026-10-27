; Osc2 wavetable: Sound byte $23 gives Osc2 its own wavetable.

osc2_table_block:
	move.b	VOICE_RECORD_SELECTOR_LOW(a3),d0
	btst	d0,OSC2_TABLE_OWN_MASK
	beq.b	osc2_table_block_own
	eori.b	#OSC2_TABLE_PARTNER_FLIP,d0
osc2_table_block_own:
	addq.b	#VOICE_SELECTOR_PACK_BIAS,d0
	rts

osc2_table_service:
	move.w	PLATFORM_TIMER_TICK_COUNT,ui_service_tick_snapshot.w
	move.w	ui_service_tick_snapshot.w,d0
	andi.w	#OSC2_TABLE_POLL_TICK_MASK,d0
	bne.b	osc2_table_service_return
	bsr.b	osc2_table_poll
osc2_table_service_return:
	rts

osc2_table_poll:
	; D7 collects the slots whose Osc2 reads its own table.
	movem.l	d0-d7/a0-a2,-(sp)
	moveq	#0,d7
	tst.w	MULTI_MODE_FLAG
	bne.b	osc2_table_poll_multi
	; Sound mode: one Sound plays; its partner block is free.
	jsr	ui_get_edited_sound.l
	movea.l	d0,a2
	bsr.b	osc2_table_load
	bra.b	osc2_table_poll_publish
osc2_table_poll_multi:
	; D6: the parts that are on.
	moveq	#0,d6
	moveq	#0,d5
osc2_table_poll_enabled:
	move.w	d5,d0
	jsr	ui_get_multi_part_record.l
	movea.l	d0,a0
	tst.b	ui_multipart_enabled_offset(a0)
	beq.b	osc2_table_poll_enabled_next
	bset	d5,d6
osc2_table_poll_enabled_next:
	addq.w	#1,d5
	cmpi.w	#OSC2_TABLE_SLOT_MASK,d5
	bls.b	osc2_table_poll_enabled
	moveq	#0,d5
osc2_table_poll_part:
	btst	d5,d6
	beq.b	osc2_table_poll_part_next
	move.w	d5,d0
	eori.w	#OSC2_TABLE_PARTNER_FLIP,d0
	btst	d0,d6
	bne.b	osc2_table_poll_part_next
	move.w	d5,d0
	mulu.w	#SOUND_RECORD_STRIDE,d0
	lea	SOUND_POOL_BASE,a2
	adda.l	d0,a2
	bsr.b	osc2_table_load
osc2_table_poll_part_next:
	addq.w	#1,d5
	cmpi.w	#OSC2_TABLE_SLOT_MASK,d5
	bls.b	osc2_table_poll_part
osc2_table_poll_publish:
	move.b	d7,OSC2_TABLE_OWN_MASK
	movem.l	(sp)+,d0-d7/a0-a2
	rts

osc2_table_load:
	moveq	#0,d0
	move.b	SOUND_WAVE2_TABLE(a2),d0
	beq.b	osc2_table_load_return
	cmpi.b	#OSC2_TABLE_ROM_CODE_LAST,d0
	bhi.b	osc2_table_load_number
	subq.b	#1,d0
osc2_table_load_number:
	move.w	SOUND_SELECTOR_WORD(a2),d2
	andi.w	#OSC2_TABLE_SLOT_MASK,d2
	move.w	d2,d1
	eori.w	#OSC2_TABLE_PARTNER_FLIP,d1
	lea	UI_SLOT_LOADED_WAVETABLES,a0
	cmp.w	0(a0,d1.w*2),d0
	beq.b	osc2_table_load_ready
	bclr	d2,OSC2_TABLE_OWN_MASK
	jsr	SYNTH_LOAD_SLOT_WAVETABLE.l
osc2_table_load_ready:
	bset	d2,d7
osc2_table_load_return:
	rts

osc2_table_display:
	tst.w	d3
	beq.b	osc2_table_display_follow
	cmpi.w	#OSC2_TABLE_ROM_CODE_LAST,d3
	bhi.b	osc2_table_display_table
	subq.w	#1,d3
osc2_table_display_table:
	jmp	ui_display_case_wavetable.l
osc2_table_display_follow:
	movea.l	d2,a0
	addq.w	#OSC2_TABLE_FOLLOW_TEXT_OFFSET,a0
	lea	osc2_table_follow_text(pc),a1
	moveq	#OSC2_TABLE_FOLLOW_TEXT_CHARS-1,d0
osc2_table_display_follow_char:
	move.b	(a1)+,(a0)+
	dbf	d0,osc2_table_display_follow_char
	jmp	ui_dispatch_display_parameter_return.l

osc2_table_follow_text:
	dc.b	"--- = Wave1  "
osc2_table_parameter_name:
	dc.b	"W2 Table",0
	if	(*-osc2_table_follow_text)&1
	dc.b	0
	endif
