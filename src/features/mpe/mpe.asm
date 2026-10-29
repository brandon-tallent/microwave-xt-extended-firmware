; MIDI Polyphonic Expression for the Microwave XT: one Lower Zone in Mode 3.

mpe_channel_in_zone:
	tst.b	MPE_MODE
	beq.b	mpe_channel_outside_zone
	tst.b	MPE_MEMBER_COUNT
	beq.b	mpe_channel_inside_zone
	cmp.b	MPE_MEMBER_COUNT,d0
	bhi.b	mpe_channel_outside_zone
mpe_channel_inside_zone:
	moveq	#1,d0
	rts
mpe_channel_outside_zone:
	moveq	#0,d0
	rts

mpe_event_in_zone:
	; As mpe_channel_in_zone for the event channel A6.
	move.w	a6,d0
	bra.b	mpe_channel_in_zone

mpe_dispatch_gate:
	; Mode 3 ignores Program Change and Polyphonic Key Pressure on Member
	; Channels.
	move.w	a6,d0
	beq.b	mpe_dispatch_stock
	bsr.b	mpe_channel_in_zone
	beq.b	mpe_dispatch_stock
	cmpi.w	#MIDI_STATUS_PROGRAM_CHANGE,d4
	beq.w	mpe_consume_event
	cmpi.w	#MIDI_STATUS_POLY_PRESSURE,d4
	beq.w	mpe_consume_event
mpe_dispatch_stock:
	move.w	#MIDI_STATUS_CONTROL_CHANGE,d0
	cmp.w	d4,d0
	rts

mpe_consume_event:
	; Finish the MIDI event: return from the hook into the dispatcher's common
	; epilogue instead of the stock path.
	move.l	#midi_dispatch_epilogue,(sp)
	rts

mpe_control_change:
	; Hook at the head of midi_control_change.
	move.b	MIDI_DISPATCH_PACKET_DATA_2_OFFSET(a5),d4
	asl.w	#MPE_VALUE_SHIFT,d4
	bsr.w	mpe_rpn
	bne.b	mpe_consume_event
	bsr.b	mpe_event_in_zone
	beq.b	mpe_control_change_stock
	move.b	MIDI_CC_PACKET_CONTROLLER_NUMBER_OFFSET(a5),d0
	cmpi.b	#MIDI_CC_RESET_CONTROLLERS,d0
	beq.w	mpe_reset_controllers
	cmpi.b	#MIDI_CC_ALL_SOUND_OFF,d0
	beq.w	mpe_member_notes_off
	cmpi.b	#MIDI_CC_ALL_NOTES_OFF,d0
	beq.w	mpe_member_notes_off
	cmpi.b	#MIDI_CC_SOUND_CONTROLLER_5,d0
	beq.b	mpe_control_change_y
	tst.w	a6
	beq.b	mpe_control_change_stock
	; Mode 3 ignores Bank Select on Member Channels.
	cmpi.b	#MIDI_CC_BANK_SELECT_MSB,d0
	beq.w	mpe_consume_event
	cmpi.b	#MIDI_CC_BANK_SELECT_LSB,d0
	beq.w	mpe_consume_event
mpe_control_change_stock:
	rts

mpe_control_change_y:
	lea	MPE_Y_TABLE,a0
	moveq	#VOICE_CONTROL_Y,d6
	bsr.w	mpe_apply_dimension
	bra.w	mpe_consume_event

mpe_reset_controllers:
	; Reset All Controllers on a Zone channel clears its bend, Y and pressure and
	; recomputes the affected voices; the stock reset of the other controllers
	; follows.
	move.w	a6,d0
	add.w	d0,d0
	lea	VOICE_CHANNEL_PITCH_BEND_TABLE,a0
	clr.w	0(a0,d0.w)
	lea	MPE_Y_TABLE,a1
	clr.w	0(a1,d0.w)
	lea	VOICE_CHANNEL_PRESSURE_TABLE,a1
	clr.w	0(a1,d0.w)
	clr.w	d5
	lea	VOICE_TABLE_BASE,a2
mpe_reset_controllers_voice:
	cmp.w	VOICE_COUNT,d5
	bge.b	mpe_control_change_stock
	clr.w	d0
	move.b	VOICE_MIDI_CHANNEL(a2),d0
	tst.w	a6
	beq.b	mpe_reset_controllers_manager
	cmp.w	a6,d0
	bne.b	mpe_reset_controllers_next
	cmpi.b	#MPE_HELD_STAGE_MIN,VOICE_AMP_ENV_STAGE(a2)
	blo.b	mpe_reset_controllers_next
	; A Member's voices keep only the Manager's values.
	move.w	(a0),VOICE_PITCH_BEND(a2)
	move.w	MPE_Y_TABLE,VOICE_CONTROL_Y(a2)
	move.w	VOICE_CHANNEL_PRESSURE_TABLE,VOICE_AFTERTOUCH(a2)
	bra.b	mpe_reset_controllers_next
mpe_reset_controllers_manager:
	; Manager reset: Manager voices clear; Member voices keep their own.
	tst.w	d0
	bne.b	mpe_reset_controllers_member_voice
	clr.w	VOICE_PITCH_BEND(a2)
	clr.w	VOICE_CONTROL_Y(a2)
	clr.w	VOICE_AFTERTOUCH(a2)
	bra.b	mpe_reset_controllers_next
mpe_reset_controllers_member_voice:
	add.w	d0,d0
	move.w	0(a0,d0.w),VOICE_PITCH_BEND(a2)
	lea	MPE_Y_TABLE,a1
	move.w	0(a1,d0.w),VOICE_CONTROL_Y(a2)
	lea	VOICE_CHANNEL_PRESSURE_TABLE,a1
	move.w	0(a1,d0.w),VOICE_AFTERTOUCH(a2)
mpe_reset_controllers_next:
	addq.w	#1,d5
	adda.w	#VOICE_RECORD_STRIDE,a2
	bra.b	mpe_reset_controllers_voice

mpe_member_notes_off:
	; All Sound Off and All Notes Off on a Member stop only that Member's voices;
	; on the Manager they keep their instrument-wide stock effect.
	tst.w	a6
	beq.w	mpe_control_change_stock
	clr.w	d5
	lea	VOICE_TABLE_BASE,a2
mpe_member_notes_off_voice:
	cmp.w	VOICE_COUNT,d5
	bge.w	mpe_consume_event
	clr.w	d0
	move.b	VOICE_MIDI_CHANNEL(a2),d0
	cmp.w	a6,d0
	bne.b	mpe_member_notes_off_next
	bsr.w	mpe_stop_voice
mpe_member_notes_off_next:
	addq.w	#1,d5
	adda.w	#VOICE_RECORD_STRIDE,a2
	bra.b	mpe_member_notes_off_voice

; ---- Registered Parameters ----

mpe_rpn:
	move.b	MIDI_CC_PACKET_CONTROLLER_NUMBER_OFFSET(a5),d0
	cmpi.b	#MIDI_CC_RPN_MSB,d0
	beq.b	mpe_rpn_select_msb
	cmpi.b	#MIDI_CC_RPN_LSB,d0
	beq.b	mpe_rpn_select_lsb
	cmpi.b	#MIDI_CC_DATA_ENTRY_MSB,d0
	beq.b	mpe_rpn_data
	cmpi.b	#MIDI_CC_DATA_ENTRY_LSB,d0
	beq.b	mpe_rpn_data
	bra.w	mpe_rpn_pass
mpe_rpn_select_msb:
	move.w	a6,d0
	lea	MPE_RPN_MSB_TABLE,a0
	move.b	MIDI_DISPATCH_PACKET_DATA_2_OFFSET(a5),0(a0,d0.w)
	lea	MPE_RPN_FLAGS_TABLE,a0
	ori.b	#MPE_RPN_MSB_SELECTED,0(a0,d0.w)
	bra.w	mpe_rpn_handled
mpe_rpn_select_lsb:
	move.w	a6,d0
	lea	MPE_RPN_LSB_TABLE,a0
	move.b	MIDI_DISPATCH_PACKET_DATA_2_OFFSET(a5),0(a0,d0.w)
	lea	MPE_RPN_FLAGS_TABLE,a0
	ori.b	#MPE_RPN_LSB_SELECTED,0(a0,d0.w)
	bra.w	mpe_rpn_handled
mpe_rpn_data:
	; Data Entry for a fully selected RPN with MSB 0.
	move.w	a6,d1
	lea	MPE_RPN_FLAGS_TABLE,a0
	cmpi.b	#MPE_RPN_SELECTED,0(a0,d1.w)
	bne.w	mpe_rpn_pass
	lea	MPE_RPN_MSB_TABLE,a0
	tst.b	0(a0,d1.w)
	bne.w	mpe_rpn_pass
	lea	MPE_RPN_LSB_TABLE,a0
	move.b	0(a0,d1.w),d2
	cmpi.b	#MIDI_RPN_PITCH_BEND_SENSITIVITY,d2
	beq.b	mpe_rpn_bend_range
	cmpi.b	#MIDI_RPN_MPE_CONFIGURATION,d2
	bne.w	mpe_rpn_pass
	; The MCM configures the Lower Zone only on its Manager, channel 1; its Data
	; Entry LSB carries nothing.
	tst.w	a6
	bne.w	mpe_rpn_handled
	cmpi.b	#MIDI_CC_DATA_ENTRY_MSB,MIDI_CC_PACKET_CONTROLLER_NUMBER_OFFSET(a5)
	bne.w	mpe_rpn_handled
	bsr.w	mpe_configure_lower_zone
	bra.w	mpe_rpn_handled
mpe_rpn_bend_range:
	; RPN 0 in the Zone sets the Manager's (channel 1) or the shared Member
	; sensitivity in whole semitones, at most MPE_BEND_RANGE_MAX.
	bsr.w	mpe_event_in_zone
	beq.w	mpe_rpn_handled
	cmpi.b	#MIDI_CC_DATA_ENTRY_MSB,MIDI_CC_PACKET_CONTROLLER_NUMBER_OFFSET(a5)
	bne.w	mpe_rpn_handled
	tst.b	MPE_BEND_RANGES_VALID
	bne.b	mpe_rpn_bend_range_set
	move.b	#MPE_MANAGER_BEND_DEFAULT,MPE_MANAGER_BEND_RANGE
	move.b	#MPE_MEMBER_BEND_DEFAULT,MPE_MEMBER_BEND_RANGE
	move.b	#1,MPE_BEND_RANGES_VALID
mpe_rpn_bend_range_set:
	move.b	#MPE_BEND_RANGE_MAX,GLOBAL_BEND_RANGE
	move.b	MIDI_DISPATCH_PACKET_DATA_2_OFFSET(a5),d0
	cmpi.b	#MPE_BEND_RANGE_MAX,d0
	bls.b	mpe_rpn_bend_range_store
	moveq	#MPE_BEND_RANGE_MAX,d0
mpe_rpn_bend_range_store:
	tst.w	a6
	bne.b	mpe_rpn_bend_range_member
	move.b	d0,MPE_MANAGER_BEND_RANGE
	bra.b	mpe_rpn_handled
mpe_rpn_bend_range_member:
	move.b	d0,MPE_MEMBER_BEND_RANGE
mpe_rpn_handled:
	moveq	#1,d0
	rts
mpe_rpn_pass:
	moveq	#0,d0
	rts

mpe_configure_lower_zone:
	clr.w	d3
	move.b	MIDI_DISPATCH_PACKET_DATA_2_OFFSET(a5),d3
	cmpi.w	#MPE_MEMBER_CHANNELS_MAX,d3
	bhi.w	mpe_configure_done
	clr.w	d2
	tst.b	MPE_MODE
	beq.b	mpe_configure_compare
	move.b	MPE_MEMBER_COUNT,d2
	bne.b	mpe_configure_compare
	moveq	#MPE_MEMBER_CHANNELS_MAX,d2
mpe_configure_compare:
	cmp.w	d3,d2
	beq.b	mpe_configure_state
	move.w	d2,d1
	cmp.w	d3,d1
	bge.b	mpe_configure_reset
	move.w	d3,d1
mpe_configure_reset:
	bsr.w	mpe_reset_zone_channels
	bsr.w	mpe_stop_all_voices
mpe_configure_state:
	move.b	d3,MPE_MEMBER_COUNT
	tst.b	d3
	bne.b	mpe_configure_on
	clr.b	MPE_MODE
	bra.b	mpe_configure_ranges
mpe_configure_on:
	; A Zone turns MPE on, keeping Zone bend if it was chosen.
	tst.b	MPE_MODE
	bne.b	mpe_configure_omni
	move.b	#MPE_MODE_ON,MPE_MODE
mpe_configure_omni:
	move.b	#MIDI_CHANNEL_CODE_OMNI,GLOBAL_MIDI_CHANNEL
mpe_configure_ranges:
	move.b	#MPE_MANAGER_BEND_DEFAULT,MPE_MANAGER_BEND_RANGE
	move.b	#MPE_MEMBER_BEND_DEFAULT,MPE_MEMBER_BEND_RANGE
	clr.b	MPE_BEND_RANGES_VALID
	tst.b	d3
	beq.b	mpe_configure_bend_range
	move.b	#1,MPE_BEND_RANGES_VALID
mpe_configure_bend_range:
	move.b	#MPE_BEND_RANGE_MAX,GLOBAL_BEND_RANGE
mpe_configure_done:
	rts

mpe_reset_zone_channels:
	; Reset the controller tables of channels 1 through D1+1 to their power-on
	; values.
	clr.w	d0
	lea	VOICE_CHANNEL_PITCH_BEND_TABLE,a0
	lea	MPE_Y_TABLE,a1
mpe_reset_zone_channel:
	clr.w	0(a0,d0.w)
	clr.w	0(a1,d0.w)
	lea	VOICE_CHANNEL_PRESSURE_TABLE,a2
	clr.w	0(a2,d0.w)
	lea	VOICE_CHANNEL_MODWHEEL_TABLE,a2
	clr.w	0(a2,d0.w)
	lea	VOICE_CHANNEL_SUSTAIN_TABLE,a2
	clr.w	0(a2,d0.w)
	lea	VOICE_CHANNEL_FOOT_CONTROLLER_TABLE,a2
	clr.w	0(a2,d0.w)
	lea	VOICE_CHANNEL_PAN_TABLE,a2
	clr.w	0(a2,d0.w)
	lea	VOICE_CHANNEL_POLY_PRESSURE_TABLE,a2
	clr.w	0(a2,d0.w)
	lea	VOICE_CHANNEL_VOLUME_TABLE,a2
	move.w	#VOICE_CHANNEL_VOLUME_RESET_Q8,0(a2,d0.w)
	addq.w	#2,d0
	dbf	d1,mpe_reset_zone_channel
	rts

mpe_stop_all_voices:
	; Changes D5, A2.
	clr.w	d5
	lea	VOICE_TABLE_BASE,a2
mpe_stop_all_voice:
	cmp.w	VOICE_COUNT,d5
	bge.b	mpe_stop_all_done
	bsr.b	mpe_stop_voice
	addq.w	#1,d5
	adda.w	#VOICE_RECORD_STRIDE,a2
	bra.b	mpe_stop_all_voice
mpe_stop_all_done:
	rts

mpe_stop_voice:
	; Put voice A2 into release with a silent amp envelope.
	move.b	#ENV_STAGE_RELEASE,VOICE_FREE_ENV_STAGE(a2)
	move.b	#ENV_STAGE_RELEASE,VOICE_WAVE_ENV_STAGE(a2)
	move.b	#ENV_STAGE_RELEASE,VOICE_FILTER_ENV_STAGE(a2)
	move.b	#ENV_STAGE_RELEASE,VOICE_AMP_ENV_STAGE(a2)
	clr.w	VOICE_AMP_ENVELOPE(a2)
	rts

mpe_bend_decode:
	; Stock v2.33 rounds bend MSB 127 to full scale.
	bsr.w	mpe_event_in_zone
	bne.b	mpe_bend_decode_done
	cmpi.b	#MIDI_7BIT_MAX,MIDI_DISPATCH_PACKET_DATA_2_OFFSET(a5)
	bne.b	mpe_bend_decode_done
	move.w	#MIDI_PITCH_BEND_FULL_SCALE_WORD,d4
mpe_bend_decode_done:
	rts

mpe_bend_apply:
	bsr.w	mpe_event_in_zone
	bne.b	mpe_bend_apply_zone
	clr.w	d5
	cmp.w	VOICE_COUNT,d5
	rts
mpe_bend_apply_zone:
	tst.b	MPE_BEND_RANGES_VALID
	beq.b	mpe_bend_apply_store
	move.b	#MPE_BEND_RANGE_MAX,GLOBAL_BEND_RANGE
mpe_bend_apply_store:
	lea	VOICE_CHANNEL_PITCH_BEND_TABLE,a0
	move.w	a6,d0
	add.w	d0,d0
	move.w	0(a0,d0.w),d3
	move.w	d4,0(a0,d0.w)
	tst.w	a6
	beq.b	mpe_bend_apply_manager
	; Member: its scaled bend plus the Manager's, into its held voices.
	move.w	d4,d0
	bsr.w	mpe_member_bend_offset
	move.l	d0,d3
	bsr.w	mpe_manager_bend_offset
	add.l	d3,d0
	bsr.w	mpe_clamp_bend
	move.w	d0,d3
	clr.w	d5
	lea	VOICE_TABLE_BASE,a2
mpe_bend_apply_member_voice:
	cmp.w	VOICE_COUNT,d5
	bge.w	mpe_consume_event
	cmpi.b	#MPE_HELD_STAGE_MIN,VOICE_AMP_ENV_STAGE(a2)
	blo.b	mpe_bend_apply_member_next
	clr.w	d1
	move.b	VOICE_MIDI_CHANNEL(a2),d1
	cmp.w	a6,d1
	bne.b	mpe_bend_apply_member_next
	move.w	d3,VOICE_PITCH_BEND(a2)
mpe_bend_apply_member_next:
	addq.w	#1,d5
	adda.w	#VOICE_RECORD_STRIDE,a2
	bra.b	mpe_bend_apply_member_voice
mpe_bend_apply_manager:
	; Manager: a held Zone voice takes its Member's scaled bend (none on the
	; Manager) plus the Manager's; a release tail moves by the change.
	move.w	d3,d0
	clr.w	d1
	move.b	MPE_MANAGER_BEND_RANGE,d1
	bsr.w	mpe_scale_bend
	move.l	d0,d3
	move.w	d4,d0
	bsr.w	mpe_scale_bend
	move.l	d0,d6
	sub.l	d3,d0
	move.l	d0,d3
	clr.w	d5
	lea	VOICE_TABLE_BASE,a2
mpe_bend_apply_manager_voice:
	cmp.w	VOICE_COUNT,d5
	bge.w	mpe_consume_event
	tst.b	VOICE_AMP_ENV_STAGE(a2)
	beq.b	mpe_bend_apply_manager_next
	move.b	VOICE_MIDI_CHANNEL(a2),d0
	bsr.w	mpe_channel_in_zone
	beq.b	mpe_bend_apply_manager_next
	cmpi.b	#MPE_HELD_STAGE_MIN,VOICE_AMP_ENV_STAGE(a2)
	blo.b	mpe_bend_apply_manager_tail
	moveq	#0,d0
	moveq	#0,d1
	move.b	VOICE_MIDI_CHANNEL(a2),d1
	beq.b	mpe_bend_apply_manager_sum
	add.w	d1,d1
	move.w	0(a0,d1.w),d0
	move.w	d5,-(sp)
	bsr.w	mpe_member_bend_offset
	move.w	(sp)+,d5
mpe_bend_apply_manager_sum:
	add.l	d6,d0
	bra.b	mpe_bend_apply_manager_store
mpe_bend_apply_manager_tail:
	move.w	VOICE_PITCH_BEND(a2),d0
	ext.l	d0
	add.l	d3,d0
mpe_bend_apply_manager_store:
	bsr.w	mpe_clamp_bend
	move.w	d0,VOICE_PITCH_BEND(a2)
mpe_bend_apply_manager_next:
	addq.w	#1,d5
	adda.w	#VOICE_RECORD_STRIDE,a2
	bra.b	mpe_bend_apply_manager_voice

mpe_member_bend_offset:
	clr.w	d1
	move.b	MPE_MEMBER_BEND_RANGE,d1
	bra.b	mpe_scale_bend

mpe_manager_bend_offset:
	move.w	VOICE_CHANNEL_PITCH_BEND_TABLE,d0
	clr.w	d1
	move.b	MPE_MANAGER_BEND_RANGE,d1
	; falls through

mpe_scale_bend:
	ext.l	d0
	tst.b	MPE_BEND_RANGES_VALID
	beq.b	mpe_scale_bend_done
	muls.w	d1,d0
	moveq	#MPE_BEND_RANGE_MAX,d5
	divs.w	d5,d0
	ext.l	d0
mpe_scale_bend_done:
	rts

mpe_osc1_bend_range:
	moveq	#0,d1
	move.b	SOUND_OSC1_BEND_RANGE(a4),d1
	bra.b	mpe_osc_bend_range

mpe_osc2_bend_range:
	moveq	#0,d1
	move.b	SOUND_OSC2_BEND_RANGE(a4),d1
mpe_osc_bend_range:
	cmpi.b	#MPE_MODE_ZONE_BEND,MPE_MODE
	bne.b	mpe_osc_bend_range_done
	moveq	#MPE_BEND_RANGE_GLOBAL,d1
mpe_osc_bend_range_done:
	rts

mpe_clamp_bend:
	; Saturate D0.l to a signed bend word.
	cmpi.l	#MIDI_PITCH_BEND_FULL_SCALE_WORD,d0
	ble.b	mpe_clamp_bend_low
	move.l	#MIDI_PITCH_BEND_FULL_SCALE_WORD,d0
	rts
mpe_clamp_bend_low:
	cmpi.l	#MPE_BEND_MIN,d0
	bge.b	mpe_clamp_bend_done
	move.l	#MPE_BEND_MIN,d0
mpe_clamp_bend_done:
	rts

mpe_pressure_apply:
	move.b	MIDI_DISPATCH_PACKET_DATA_1_OFFSET(a5),d4
	asl.w	#MPE_VALUE_SHIFT,d4
	bsr.w	mpe_event_in_zone
	beq.b	mpe_pressure_stock
	lea	VOICE_CHANNEL_PRESSURE_TABLE,a0
	moveq	#VOICE_AFTERTOUCH,d6
	bsr.b	mpe_apply_dimension
	bra.w	mpe_consume_event
mpe_pressure_stock:
	rts

mpe_apply_dimension:
	; Store D4 (a 0..MPE_DIMENSION_MAX word) for channel A6 in the channel table
	; at A0 and update voice-record word D6.
	move.w	a6,d0
	add.w	d0,d0
	move.w	0(a0,d0.w),d3
	move.w	d4,0(a0,d0.w)
	tst.w	a6
	beq.b	mpe_apply_dimension_manager
	move.w	d4,d3
	add.w	(a0),d3
	cmpi.w	#MPE_DIMENSION_MAX,d3
	bls.b	mpe_apply_dimension_member
	move.w	#MPE_DIMENSION_MAX,d3
mpe_apply_dimension_member:
	clr.w	d5
	lea	VOICE_TABLE_BASE,a2
mpe_apply_dimension_member_voice:
	cmp.w	VOICE_COUNT,d5
	bge.b	mpe_apply_dimension_done
	cmpi.b	#MPE_HELD_STAGE_MIN,VOICE_AMP_ENV_STAGE(a2)
	blo.b	mpe_apply_dimension_member_next
	clr.w	d0
	move.b	VOICE_MIDI_CHANNEL(a2),d0
	cmp.w	a6,d0
	bne.b	mpe_apply_dimension_member_next
	move.w	d3,0(a2,d6.w)
mpe_apply_dimension_member_next:
	addq.w	#1,d5
	adda.w	#VOICE_RECORD_STRIDE,a2
	bra.b	mpe_apply_dimension_member_voice
mpe_apply_dimension_manager:
	move.w	d4,d2
	sub.w	d3,d2
	ext.l	d2
	clr.w	d5
	lea	VOICE_TABLE_BASE,a2
mpe_apply_dimension_manager_voice:
	cmp.w	VOICE_COUNT,d5
	bge.b	mpe_apply_dimension_done
	tst.b	VOICE_AMP_ENV_STAGE(a2)
	beq.b	mpe_apply_dimension_manager_next
	move.b	VOICE_MIDI_CHANNEL(a2),d0
	bsr.w	mpe_channel_in_zone
	beq.b	mpe_apply_dimension_manager_next
	cmpi.b	#MPE_HELD_STAGE_MIN,VOICE_AMP_ENV_STAGE(a2)
	blo.b	mpe_apply_dimension_manager_tail
	moveq	#0,d0
	moveq	#0,d3
	move.b	VOICE_MIDI_CHANNEL(a2),d3
	beq.b	mpe_apply_dimension_manager_sum
	add.w	d3,d3
	move.w	0(a0,d3.w),d0
mpe_apply_dimension_manager_sum:
	add.w	d4,d0
	bra.b	mpe_apply_dimension_manager_high
mpe_apply_dimension_manager_tail:
	move.w	0(a2,d6.w),d0
	ext.l	d0
	add.l	d2,d0
	bpl.b	mpe_apply_dimension_manager_high
	clr.l	d0
mpe_apply_dimension_manager_high:
	cmpi.l	#MPE_DIMENSION_MAX,d0
	bls.b	mpe_apply_dimension_manager_store
	move.l	#MPE_DIMENSION_MAX,d0
mpe_apply_dimension_manager_store:
	move.w	d0,0(a2,d6.w)
mpe_apply_dimension_manager_next:
	addq.w	#1,d5
	adda.w	#VOICE_RECORD_STRIDE,a2
	bra.b	mpe_apply_dimension_manager_voice
mpe_apply_dimension_done:
	rts

mpe_note_on:
	; Hook in voice_lifecycle_retrigger_note: run the stock allocator, then
	; preload the new voices with their channel's bend, Y and pressure, and leave
	; through the lifecycle's exit.
	jsr	VOICE_ALLOCATOR.l
	clr.w	d0
	move.b	(a3),d0
	andi.w	#MIDI_CHANNEL_MASK,d0
	move.w	d0,d1
	bsr.w	mpe_channel_in_zone
	beq.w	mpe_note_on_done
	tst.b	MPE_BEND_RANGES_VALID
	beq.b	mpe_note_on_bend
	move.b	#MPE_BEND_RANGE_MAX,GLOBAL_BEND_RANGE
mpe_note_on_bend:
	moveq	#0,d2
	tst.w	d1
	beq.b	mpe_note_on_manager_bend
	move.w	d1,d0
	add.w	d0,d0
	lea	VOICE_CHANNEL_PITCH_BEND_TABLE,a0
	move.w	0(a0,d0.w),d0
	bsr.w	mpe_member_bend_offset
	move.l	d0,d2
mpe_note_on_manager_bend:
	bsr.w	mpe_manager_bend_offset
	add.l	d2,d0
	bsr.w	mpe_clamp_bend
	move.l	d0,d2
	clr.w	d1
	move.b	(a3),d1
	andi.w	#MIDI_CHANNEL_MASK,d1
	move.w	d1,d0
	add.w	d0,d0
	lea	MPE_Y_TABLE,a0
	move.w	0(a0,d0.w),d4
	tst.w	d1
	beq.b	mpe_note_on_pressure
	add.w	(a0),d4
	cmpi.w	#MPE_DIMENSION_MAX,d4
	bls.b	mpe_note_on_pressure
	move.w	#MPE_DIMENSION_MAX,d4
mpe_note_on_pressure:
	lea	VOICE_CHANNEL_PRESSURE_TABLE,a0
	move.w	0(a0,d0.w),d6
	tst.w	d1
	beq.b	mpe_note_on_preload
	add.w	(a0),d6
	cmpi.w	#MPE_DIMENSION_MAX,d6
	bls.b	mpe_note_on_preload
	move.w	#MPE_DIMENSION_MAX,d6
mpe_note_on_preload:
	; Every held voice of this note and channel takes the values; the new voices
	; are in their Attack stage.
	clr.w	d3
	lea	VOICE_TABLE_BASE,a0
mpe_note_on_voice:
	cmp.w	VOICE_COUNT,d3
	bge.b	mpe_note_on_done
	cmpi.b	#MPE_HELD_STAGE_MIN,VOICE_AMP_ENV_STAGE(a0)
	blo.b	mpe_note_on_next
	move.b	VOICE_NOTE(a0),d0
	cmp.b	VOICE_EVENT_NOTE(a3),d0
	bne.b	mpe_note_on_next
	cmp.b	VOICE_MIDI_CHANNEL(a0),d1
	bne.b	mpe_note_on_next
	move.w	d2,VOICE_PITCH_BEND(a0)
	move.w	d4,VOICE_CONTROL_Y(a0)
	move.w	d6,VOICE_AFTERTOUCH(a0)
mpe_note_on_next:
	addq.w	#1,d3
	adda.w	#VOICE_RECORD_STRIDE,a0
	bra.b	mpe_note_on_voice
mpe_note_on_done:
	jmp	voice_lifecycle_return.l

mpe_note_off_compare:
	; Hook in the Note Off release scan, voice A4 against event A3: release when
	; the note matches and, for a Zone channel, the channel too.
	move.b	VOICE_NOTE(a4),d5
	cmp.b	VOICE_EVENT_NOTE(a3),d5
	bne.b	mpe_note_off_keep
	clr.w	d0
	move.b	(a3),d0
	andi.w	#MIDI_CHANNEL_MASK,d0
	move.w	d0,d5
	bsr.w	mpe_channel_in_zone
	beq.b	mpe_note_off_release
	cmp.b	VOICE_MIDI_CHANNEL(a4),d5
	beq.b	mpe_note_off_release
mpe_note_off_keep:
	jmp	voice_lifecycle_release_matching_next.l
mpe_note_off_release:
	jmp	voice_lifecycle_release_matching_voice.l

mpe_display_mode:
	; MPE Mode D3 as "off", "on" or "Zone bend".
	movea.l	d2,a0
	lea	mpe_mode_names(pc),a1
	move.w	d3,d0
	cmpi.w	#MPE_MODE_LAST,d0
	bls.b	mpe_display_mode_known
	moveq	#0,d0
mpe_display_mode_known:
	mulu.w	#MPE_MODE_NAME_CHARS,d0
	adda.w	d0,a1
	moveq	#MPE_MODE_NAME_CHARS-1,d1
mpe_display_mode_char:
	move.b	(a1)+,(a0)+
	dbf	d1,mpe_display_mode_char
	jmp	ui_dispatch_display_parameter_return.l
mpe_mode_names:
	; MPE Mode values, MPE_MODE_NAME_CHARS each.
	dc.b	"off      "
	dc.b	"on       "
	dc.b	"Zone bend"
mpe_page_labels:
	; The [MPE] Global page's captions: MPE Mode in the first position.
	dc.b	" MPE Mode|                              ",0
mpe_page_title:
	dc.b	"[MPE]",0
mpe_parameter_name:
	dc.b	"MPE Mode",0
	if	(*-mpe_mode_names)&1
	dc.b	0
	endif
