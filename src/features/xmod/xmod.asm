; X-Mod: how Osc2 modulates Osc1, chosen per Sound (byte $08).

xmod_dsp_stream_next:
	tst.b	d5
	bne.b	xmod_dsp_stream_second
	lea	xmod_dsp_stream.l,a2
	lea	xmod_dsp_stream_end.l,a3
	addq.w	#1,d5
	jmp	DSP_HOST_STREAM_WAIT_READY.l
xmod_dsp_stream_second:
	cmpi.b	#1,d5
	bne.b	xmod_dsp_stream_private
	lea	xmod_dsp_stream_morph(pc),a2
	lea	xmod_dsp_stream_morph_end(pc),a3
	addq.w	#1,d5
	jmp	DSP_HOST_STREAM_WAIT_READY.l
xmod_dsp_stream_private:
	cmpi.b	#2,d5
	bne.b	xmod_dsp_stream_done
	movea.l	(a1)+,a3
	addq.w	#1,d5
	movea.l	a1,a2
	jmp	DSP_HOST_STREAM_WAIT_READY.l
xmod_dsp_stream_done:
	rts

xmod_frame_emit:
	jsr	board1.l
	bne.b	xmod_frame_mode
	move.l	d0,(a6)
	bra.w	xmod_frame_external
xmod_frame_mode:
	moveq	#0,d1
	move.b	SOUND_XMOD_MODE(a4),d1
	cmpi.b	#XMOD_MODE_LAST,d1
	bls.b	xmod_frame_known
	moveq	#XMOD_MODE_FM,d1
xmod_frame_known:
	moveq	#0,d2
	cmpi.b	#XMOD_MODE_PM,d1
	beq.b	xmod_frame_pm
	cmpi.b	#XMOD_MODE_PM12,d1
	beq.b	xmod_frame_pm
	cmpi.b	#XMOD_MODE_AM,d1
	bne.b	xmod_frame_send
	moveq	#0,d0
	bra.b	xmod_frame_send
xmod_frame_pm:
	bsr.b	xmod_depth
	move.l	d0,d2
	neg.l	d2
xmod_frame_send:
	andi.w	#~XMOD_DIR_OSC1_TO_OSC2,d2
	cmpi.b	#XMOD_MODE_FM12,d1
	blo.b	xmod_frame_emit_words
	ori.w	#XMOD_DIR_OSC1_TO_OSC2,d2
xmod_frame_emit_words:
	move.l	d0,(a6)
	bsr.b	xmod_frame_external
	move.l	d2,(a6)
	bra.w	warp_frame_emit

xmod_depth:
	moveq	#0,d0
	move.b	SOUND_OSC1_FM_AMOUNT(a4),d0
	swap	d0
	add.l	VOICE_FM_AMOUNT_ACCUMULATOR(a3),d0
	bpl.b	xmod_depth_check_upper
	moveq	#0,d0
	rts
xmod_depth_check_upper:
	cmpi.l	#FRAME_Q16_LEVEL_MAX,d0
	blt.b	xmod_depth_done
	move.l	#FRAME_Q16_LEVEL_MAX,d0
xmod_depth_done:
	rts

xmod_ring_emit:
	cmpi.b	#XMOD_MODE_AM,SOUND_XMOD_MODE(a4)
	bne.b	xmod_ring_emit_level
	jsr	board1.l
	beq.b	xmod_ring_emit_level
	bsr.b	xmod_depth
	lsr.l	#8,d0
	move.l	d0,d2
	moveq	#0,d0
	move.b	SOUND_MIX_WAVE1(a4),d0
	swap	d0
	add.l	VOICE_MIX_WAVE1_ACCUMULATOR(a3),d0
	bpl.b	xmod_ring_emit_wave1_upper
	moveq	#0,d0
xmod_ring_emit_wave1_upper:
	cmpi.l	#FRAME_Q16_LEVEL_MAX,d0
	blt.b	xmod_ring_emit_scale
	move.l	#FRAME_Q16_LEVEL_MAX,d0
xmod_ring_emit_scale:
	lsr.l	#8,d0
	mulu.w	d2,d0
	lsr.l	#XMOD_AM_SCALE_SHIFT,d0
xmod_ring_emit_level:
	move.l	d0,(a6)
	jmp	morph_edge_wave2.l

xmod_frame_external:
	; p28, as v2.33: MixExternal << 16.
	moveq	#0,d0
	move.b	SOUND_MIX_EXTERNAL(a4),d0
	swap	d0
	move.l	d0,(a6)
	rts

xmod_dsp_stream_morph:
	include	"features/xmod/dsp_stream_morph.inc"
xmod_dsp_stream_morph_end:
	if	(xmod_dsp_stream_morph_end-xmod_dsp_stream_morph)&1
	dc.b	0
	endif
