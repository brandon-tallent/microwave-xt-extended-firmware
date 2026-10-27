; Honda: Aliasing 6 and 7 read the wave the way the Piston Honda MkII does.

honda_octave_seed:
	; Hooks in frame_wave_index_pack and frame_osc2_wave_index_pack.
	move.w	d6,d2
	moveq	#WAVE_MAX_OCTAVE_REDUCTIONS,d4
	sub.b	SOUND_ALIASING(a4),d4
	bmi.b	honda_octave_seed_low
	bsr.w	morph_interp
	beq.b	honda_octave_seed_done
honda_octave_seed_low:
	move.w	#HONDA_LOWEST_PITCH,d2
honda_octave_seed_done:
	rts

honda_osc2_mask:
	move.l	d3,(a6)
	bra.b	honda_mask_select
honda_wave1_mask:
	; Hook in frame_wave_base_and_coeff_emit.
	moveq	#TIME_QUANT_SEED_MASK,d0
honda_mask_select:
	cmpi.b	#INTERP_HONDA,SOUND_INTERP(a4)
	beq.b	honda_mask_raw
	cmpi.b	#ALIASING_HONDA_RAW,SOUND_ALIASING(a4)
	bne.b	honda_mask_time_quant
honda_mask_raw:
	move.w	#HONDA_RAW_MASK,d0
	cmp.w	d0,d0
	rts
honda_mask_time_quant:
	tst.b	SOUND_TIME_QUANT(a4)
	rts

honda_display:
	cmpi.b	#ALIASING_FORMAT,d1
	beq.b	honda_display_aliasing
	bra.w	morph_display
honda_display_aliasing:
	cmpi.w	#ALIASING_STOCK_LAST,d3
	bhi.b	honda_display_name
	jmp	ui_display_case_mode_suffix.l
honda_display_name:
	movea.l	d2,a0
	lea	honda_names(pc),a1
	cmpi.w	#ALIASING_HONDA,d3
	beq.b	honda_display_copy
	lea	HONDA_NAME_CHARS(a1),a1
honda_display_copy:
	moveq	#HONDA_NAME_CHARS-1,d0
honda_display_char:
	move.b	(a1)+,(a0)+
	dbf	d0,honda_display_char
	jmp	ui_dispatch_display_parameter_return.l

honda_names:
	dc.b	" Honda   "
	dc.b	"Honda Raw"
	if	(*-honda_names)&1
	dc.b	0
	endif
