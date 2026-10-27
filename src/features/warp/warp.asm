; Warp: each oscillator's read position through its wave, reshaped per Sound
; (Osc1 bytes $15/$14, Osc2 $20/$17: mode and amount).

warp_frame_emit:
	; Emit p30..p37 for A4's Sound and A3's voice.
	moveq	#0,d0
	move.b	VOICE_PHYSICAL_VOICE_INDEX(a3),d0
	lsl.w	#WARP_MOD_VOICE_SHIFT,d0
	lea	WARP_MOD_RAM.w,a0
	adda.w	d0,a0
	moveq	#0,d1
	move.b	SOUND_WARP1_MODE(a4),d0
	move.b	SOUND_WARP1_AMOUNT(a4),d1
	bsr.b	warp_osc_emit
	moveq	#0,d1
	move.b	SOUND_WARP2_MODE(a4),d0
	move.b	SOUND_WARP2_AMOUNT(a4),d1
	; falls through for Osc2

warp_osc_emit:
	andi.l	#BYTE_MASK,d0
	swap	d1
	add.l	(a0),d1
	clr.l	(a0)+
	tst.l	d1
	bpl.b	warp_osc_amount_whole
	moveq	#0,d1
warp_osc_amount_whole:
	swap	d1
	ext.l	d1
	cmpi.w	#WARP_AMOUNT_MAX,d1
	bls.b	warp_osc_amount_known
	moveq	#WARP_AMOUNT_MAX,d1
warp_osc_amount_known:
	moveq	#0,d2
	moveq	#0,d3
	cmpi.w	#WARP_MODE_LAST,d0
	bls.b	warp_osc_mode
warp_osc_off:
	move.l	#WARP_DSP_OFF,(a6)
	bra.w	warp_osc_params
warp_osc_mode:
	move.w	warp_osc_modes(pc,d0.w*2),d0
	jmp	warp_osc_modes(pc,d0.w)
warp_osc_modes:
	dc.w	warp_osc_off-warp_osc_modes
	dc.w	warp_osc_bend_plus-warp_osc_modes
	dc.w	warp_osc_bend_minus-warp_osc_modes
	dc.w	warp_osc_bend_plus_minus-warp_osc_modes
	dc.w	warp_osc_pwm-warp_osc_modes
	dc.w	warp_osc_asym_plus-warp_osc_modes
	dc.w	warp_osc_asym_minus-warp_osc_modes
	dc.w	warp_osc_asym_plus_minus-warp_osc_modes
	dc.w	warp_osc_mirror-warp_osc_modes
	dc.w	warp_osc_quantize-warp_osc_modes
	if	*-warp_osc_modes<>2*(WARP_MODE_LAST+1)
	error	"warp_osc_modes needs one entry a mode"
	endif
warp_osc_bend_minus:
	neg.l	d1
warp_osc_bend_plus:
	move.l	#WARP_BEND_K_BASE_SIDED,d2
	bra.b	warp_osc_bend
warp_osc_bend_plus_minus:
	subi.l	#WARP_AMOUNT_CENTER,d1
	move.l	#WARP_BEND_K_BASE,d2
warp_osc_bend:
	move.l	#WARP_DSP_BEND,(a6)
	lsl.l	#2,d1
	move.l	d2,d0
	sub.l	d1,d0
	add.l	d1,d2
	moveq	#WARP_BEND_K_SHIFT,d1
	lsl.l	d1,d2
	divu.l	d0,d2
	bra.w	warp_osc_params
warp_osc_pwm:
	move.l	#WARP_DSP_PWM,(a6)
	moveq	#WARP_PWM_AMOUNT_MAX,d0
	cmp.l	d0,d1
	bls.b	warp_osc_pwm_width
	move.l	d0,d1
warp_osc_pwm_width:
	move.l	#WARP_PWM_WIDTH_ONE,d0
	sub.l	d1,d0
	move.l	#WARP_PWM_NUMERATOR,d2
	divu.l	d0,d2
	bra.w	warp_osc_params
warp_osc_asym_minus:
	neg.l	d1
warp_osc_asym_plus:
	muls.w	#WARP_ASYM_KNEE_STEP_SIDED,d1
	bra.b	warp_osc_asym
warp_osc_asym_plus_minus:
	subi.l	#WARP_AMOUNT_CENTER,d1
	muls.w	#WARP_ASYM_KNEE_STEP>>2,d1
	lsl.l	#2,d1
warp_osc_asym:
	move.l	#WARP_DSP_ASYM,(a6)
	neg.l	d1
	addi.l	#WARP_HALF_TURN,d1
	move.l	#WARP_TURN,d0
	bra.b	warp_osc_knee
warp_osc_mirror:
	move.l	#WARP_DSP_MIRROR,(a6)
	mulu.w	#WARP_MIRROR_KNEE_SPAN,d1
	addi.l	#WARP_AMOUNT_MAX/2,d1
	divu.w	#WARP_AMOUNT_MAX,d1
	addq.w	#WARP_MIRROR_KNEE_MIN,d1
	andi.l	#WORD_MASK,d1
	moveq	#WARP_MIRROR_KNEE_SHIFT,d0
	lsl.l	d0,d1
	move.l	#WARP_HALF_TURN,d0
warp_osc_knee:
	move.l	d1,(a6)
	sub.l	d1,d0
	moveq	#WARP_ASYM_KNEE_SHIFT,d3
	lsr.l	d3,d1
	move.l	#WARP_ASYM_NUMERATOR,d2
	divu.l	d1,d2
	move.l	d2,(a6)
	lsr.l	d3,d0
	move.l	#WARP_ASYM_NUMERATOR,d2
	divu.l	d0,d2
	move.l	d2,(a6)
	rts
warp_osc_quantize:
	move.l	#WARP_DSP_QUANTIZE,(a6)
	moveq	#WARP_AMOUNT_MAX,d0
	sub.l	d1,d0
	move.l	d0,d2
	mulu.w	d0,d2
	moveq	#WARP_QUANTIZE_POWER_STEPS-1,d3
warp_osc_quantize_power:
	mulu.w	d0,d2
	lsr.l	#7,d2
	dbf	d3,warp_osc_quantize_power
	mulu.w	#WARP_QUANTIZE_SCALE,d2
	addi.l	#WARP_QUANTIZE_FEWEST_FRACTION,d2
	move.l	d2,d3
	moveq	#WARP_QUANTIZE_DIVISOR_SHIFT,d0
	lsr.l	d0,d3
	move.l	#WARP_QUANTIZE_NUMERATOR,d0
	divu.l	d3,d0
	move.l	d0,d3
warp_osc_params:
	move.l	d2,(a6)
	move.l	d3,(a6)
	move.l	d3,(a6)
	rts

warp_display:
	movea.l	d2,a0
	lea	warp_mode_names.l,a1
	move.w	d3,d0
	cmpi.w	#WARP_MODE_LAST,d0
	bls.b	warp_display_known
	moveq	#WARP_MODE_OFF,d0
warp_display_known:
	mulu.w	#WARP_MODE_NAME_CHARS,d0
	adda.w	d0,a1
	moveq	#WARP_MODE_NAME_CHARS-1,d0
warp_display_char:
	move.b	(a1)+,(a0)+
	dbf	d0,warp_display_char
	jmp	ui_dispatch_display_parameter_return.l

warp_amount_display:
	moveq	#SOUND_WARP1_MODE,d0
	cmpi.b	#WARP1_AMOUNT_FORMAT,d1
	beq.b	warp_amount_display_mode
	moveq	#SOUND_WARP2_MODE,d0
	cmpi.b	#WARP2_AMOUNT_FORMAT,d1
	bne.b	warp_amount_display_plain
warp_amount_display_mode:
	movem.l	d0/d2,-(sp)
	jsr	ui_get_edited_sound.l
	movea.l	d0,a0
	movem.l	(sp)+,d0/d2
	move.b	(a0,d0.w),d0
	cmpi.b	#WARP_MODE_BEND_PLUS_MINUS,d0
	beq.b	warp_amount_display_signed
	cmpi.b	#WARP_MODE_ASYM_PLUS_MINUS,d0
	bne.b	warp_amount_display_plain
warp_amount_display_signed:
	jmp	ui_display_case_signed_centered.l
warp_amount_display_plain:
	jmp	ui_display_case_default.l

warp_page_install:
	; The [Warp] page's handler (edition_osc_pages), called after the stock slot
	; callbacks are installed: the mode fields, slots 0 and 2, adjust through
	; warp_mode_adjust.
	lea	warp_mode_adjust(pc),a0
	move.l	a0,UI_PARAMETER_CALLBACK_0.l
	move.l	a0,UI_PARAMETER_CALLBACK_2.l
	rts

warp_mode_adjust:
	movem.l	d1-d2,-(sp)
	jsr	ui_adjust_menu_parameter.l
	movem.l	(sp)+,d1-d2
	addq.w	#1,d1
	clr.w	d0
	jmp	ui_update_menu_parameter.l
