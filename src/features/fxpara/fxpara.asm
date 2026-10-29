fxpara_group:
	move.w	SOUND_OUTPUT_BUS_SELECTOR(a4),d5
	subi.w	#MIDI_DSP_GROUP_RECORD_BASE_0,d5
	lsr.w	#MIDI_DSP_GROUP_STRIDE_SHIFT,d5
	cmpi.w	#UI_EFFECT_GROUP_COUNT-1,d5
	rts

fxpara_note_done:
	; FRAME_VOICE_DSP_STATE_UPDATE, after a note's first frame (v2.33: jsr
	; platform_dsp_channel_issue_command.l, the stop command, with D0/D1 its
	; arguments): A3's voice becomes its effect group's, then the frame ends as
	; any other does.
	bsr.b	fxpara_group
	bhi.b	fxpara_frame_done
	lea	FXPARA_VOICES.w,a0
	move.b	VOICE_PHYSICAL_VOICE_INDEX(a3),(a0,d5.w)

fxpara_frame_done:
	; Both frame paths' stop command (v2.33: jsr
	; platform_dsp_channel_issue_command.l), then this frame's settings.
	jsr	platform_dsp_channel_issue_command.l
	lea	FXPARA_SUMS+4*FXPARA_SETTINGS.w,a2
	moveq	#FXPARA_SETTINGS,d3
	bsr.b	fxpara_group
	shi	d4
	bhi.b	fxpara_setting
	lea	FXPARA_VOICES.w,a0
	move.b	(a0,d5.w),d0
	cmp.b	VOICE_PHYSICAL_VOICE_INDEX(a3),d0
	sne	d4
fxpara_setting:
	move.l	-(a2),d1
	clr.l	(a2)
	tst.b	d4
	bne.b	fxpara_next
	lea	MIDI_RAM_EFFECT_TYPES.w,a0
	cmpi.w	#EFFECT_TYPE_OVERDRIVE,(a0,d5.w*2)
	bne.b	fxpara_value
	cmpi.w	#EFFECT_PARAM_3,d3
	beq.b	fxpara_next
fxpara_value:
	moveq	#0,d0
	move.b	fxpara_sound_bytes-EFFECT_PARAM_1(pc,d3.w),d0
	move.b	(a4,d0.w),d0
	swap	d0
	add.l	d1,d0
	bpl.b	fxpara_value_whole
	moveq	#0,d0
fxpara_value_whole:
	swap	d0
	ext.l	d0
	moveq	#CONTROL_7BIT_MAX,d1
	cmp.l	d1,d0
	bls.b	fxpara_value_known
	move.l	d1,d0
fxpara_value_known:
	move.w	d5,d1
	add.w	d1,d1
	add.w	d5,d1
	add.w	d3,d1
	lea	FXPARA_SENT.w,a0
	cmp.l	(a0,d1.w*4),d0
	beq.b	fxpara_next
	move.l	d0,d2
	move.w	d3,d1
	move.w	d5,d0
	jsr	MIDI_EFFECT_UPDATE_DISPATCH.l
fxpara_next:
	subq.w	#1,d3
	bne.b	fxpara_setting
	rts

fxpara_sound_bytes:
	; Para 1-3's Sound bytes.
	dc.b	SOUND_FX_PARAMETER_1,SOUND_FX_PARAMETER_2,SOUND_FX_PARAMETER_3
	dc.b	ROM_ALIGNMENT_FILL_BYTE
