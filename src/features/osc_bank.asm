; The Osc menu bank with the edition's pages, and the Shift + dial remap that
; reaches them.

edition_osc_pages:
	; Flag byte 1 is 1 on each section's first page and 0 on its later pages in
	; the stock bank.
	EDITION_PAGE_DESCRIPTOR	ui_page_caption_octave_1_semitone_detune_keytrack,ui_page_title_osc1_1,1,2,3,6,ui_noop_callback,0,1
	EDITION_PAGE_DESCRIPTOR	ui_page_caption_pitchbend_range_1_fm_amount,ui_page_title_osc1_2,5,0,7,0,ui_noop_callback,0,0
	EDITION_PAGE_DESCRIPTOR	ui_page_caption_octave_2_semitone_detune_keytrack,ui_page_title_osc2_1,12,13,14,18,ui_noop_callback,0,1
	EDITION_PAGE_DESCRIPTOR	ui_page_caption_pitchbend_range_2_sync_link,ui_page_title_osc2_2,17,0,16,19,ui_noop_callback,0,0
	EDITION_PAGE_DESCRIPTOR	edition_page_caption_xmod,edition_page_title_xmod,SOUND_XMOD_MODE,SOUND_OSC1_FM_AMOUNT,0,0,ui_noop_callback,0,UI_PAGE_FLAG_XT_ONLY
	EDITION_PAGE_DESCRIPTOR	ui_page_caption_startwave_phase_wavetable_w1,ui_page_title_wave1_1,26,27,25,0,ui_install_wavetable_page,0,1
	EDITION_PAGE_DESCRIPTOR	ui_page_caption_envamount_envvelamt_keytrack_limit_w1,ui_page_title_wave1_2,28,29,30,31,ui_noop_callback,0,0
	EDITION_PAGE_DESCRIPTOR	ui_page_caption_startwave_phase_link_w2,ui_page_title_wave2_1,36,37,42,0,ui_noop_callback,0,1
	EDITION_PAGE_DESCRIPTOR	ui_page_caption_envamount_envvelamt_keytrack_limit_w2,ui_page_title_wave2_2,38,39,40,41,ui_noop_callback,0,0
	EDITION_PAGE_DESCRIPTOR	edition_page_caption_wave2_table,edition_page_title_wave2_table,SOUND_WAVE2_TABLE,0,0,0,ui_noop_callback,0,0
	EDITION_PAGE_DESCRIPTOR	edition_page_caption_warp,edition_page_title_warp,SOUND_WARP1_MODE,SOUND_WARP1_AMOUNT,SOUND_WARP2_MODE,SOUND_WARP2_AMOUNT,warp_page_install,0,UI_PAGE_FLAG_XT_ONLY
	EDITION_PAGE_DESCRIPTOR	ui_page_caption_aliasing_timequant_accuracy_clipping,ui_page_title_quality,53,54,57,55,ui_noop_callback,0,1
	EDITION_PAGE_DESCRIPTOR	morph_page_caption,morph_page_title,SOUND_INTERP,0,0,0,ui_noop_callback,0,0
	EDITION_PAGE_DESCRIPTOR	ui_page_caption_wave1_wave2_ringmod_noise,ui_page_title_mix,47,48,49,50,ui_noop_callback,0,1
	EDITION_PAGE_DESCRIPTOR	ui_page_caption_external,ui_page_title_mix_2,51,0,0,0,ui_noop_callback,0,UI_PAGE_FLAG_XT_ONLY
	EDITION_PAGE_DESCRIPTOR	ui_page_caption_par_1_par_2_par_3_par_4,ui_page_title_play_access,58,59,60,61,ui_install_play_access_page,0,1
edition_osc_pages_end:
	if	edition_osc_pages_end-edition_osc_pages<>EDITION_OSC_PAGE_COUNT*UI_PAGE_DESCRIPTOR_STRIDE
	error	"edition_osc_pages must hold EDITION_OSC_PAGE_COUNT pages"
	endif

edition_page_title_wave2_table:
	dc.b	"[Wave2 3]",0
	if	(*-edition_page_title_wave2_table)&1
	dc.b	0
	endif

edition_dial_select:
	move.b	(a1,a0.l*2),d5
	lea	edition_dial_shift_bytes(pc),a0
	jsr	board1.l
	bne.b	edition_dial_select_scan
	addq.w	#EDITION_DIAL_SHIFT_XT_BYTES,a0
edition_dial_select_scan:
	move.b	(a0)+,d1
	beq.b	edition_dial_select_done
	cmp.b	d1,d5
	beq.b	edition_dial_select_match
	addq.w	#1,a0
	bra.b	edition_dial_select_scan
edition_dial_select_match:
	move.b	(a0),d1
	jsr	is_panel_shift_held.l
	tst.w	d0
	beq.b	edition_dial_select_done
	move.b	d1,d5
edition_dial_select_done:
	movea.w	d5,a0
	rts
