; Tallent Edition for the Waldorf Microwave II/XT/XTk, built against OS v2.33.

	cpu	68332
	supmode	on
	page	0

	include	"stock_abi.inc"
	include	"features/constants.inc"
	include	"edition.inc"

UI_PARAMETER_RECORD macro cap,rsv,minv,maxv,stepv,modev,fmtv
        dc.l    cap
        dc.b    rsv,minv,maxv,stepv,modev,fmtv
        endm
UI_PAGE_DESCRIPTOR macro cap,tit,s0,s1,s2,s3,cb,byte16,byte17
        dc.l    cap,tit
        dc.b    s0,s1,s2,s3
        dc.l    cb
        dc.b    byte16,byte17
        endm

; ---- ui_global_parameter_record_control_y ----
	org	ui_global_parameter_record_control_y
	; Control Y shows the parameter alias of its CC, the Member Y input.
	UI_PARAMETER_RECORD	ui_parameter_alias_control_y,ui_metadata_domain_global_parameter,0,120,0,1,MPE_Y_CC_FORMAT

; ---- ui_global_parameter_record_30 ----
	org	ui_global_parameter_record_30
	; Global 30 is MPE Mode: off, on, or on with every Sound at the Global Bend
	; Range (Zone bend).
	UI_PARAMETER_RECORD	mpe_parameter_name,ui_metadata_domain_global_parameter,0,MPE_MODE_LAST,1,1,MPE_MODE_FORMAT

; ---- mpe_global_page_descriptor ----
	org	mpe_global_page_descriptor
	UI_PAGE_DESCRIPTOR	mpe_page_labels,mpe_page_title,30,0,10,0,ui_install_global_parameter_callbacks,0,$00

; ---- ui_global_page_descriptor_04_controls ----
	org	ui_global_page_descriptor_04_controls
	UI_PAGE_DESCRIPTOR	ui_page_caption_control_w_control_x_control_y_control_z,ui_page_title_controls,8,9,10,11,ui_install_global_parameter_callbacks,0,$01

; ---- ui_global_page_descriptor_05_volume ----
	org	ui_global_page_descriptor_05_volume
	UI_PAGE_DESCRIPTOR	ui_global_caption_main_volume,ui_page_title_volume,12,0,0,0,ui_render_main_volume_caption,0,$01

; ---- ui_global_page_descriptor_06_tune ----
	org	ui_global_page_descriptor_06_tune
	UI_PAGE_DESCRIPTOR	ui_global_caption_master_tuning_transpose,ui_page_title_tune,16,0,15,0,ui_install_global_parameter_callbacks,0,$01

; ---- ui_global_page_descriptor_07_keyboard ----
	org	ui_global_page_descriptor_07_keyboard
	UI_PAGE_DESCRIPTOR	ui_global_caption_kb_send_vel_curve_r_vel_c_prs_curve,ui_global_title_keyboard,29,19,20,21,ui_install_global_parameter_callbacks,0,$09

; ---- ui_global_page_descriptor_08_local_control ----
	org	ui_global_page_descriptor_08_local_control
	UI_PAGE_DESCRIPTOR	ui_global_caption_local_control,ui_global_title_local_control,22,0,0,0,ui_install_global_parameter_callbacks,0,$09

; ---- ui_global_page_descriptor_09_sustain_pedal ----
	org	ui_global_page_descriptor_09_sustain_pedal
	UI_PAGE_DESCRIPTOR	ui_global_caption_pedal_type,ui_global_title_sustain_pedal,31,0,0,0,ui_install_global_parameter_callbacks,0,$08

; ---- ui_global_page_descriptor_10_system ----
	org	ui_global_page_descriptor_10_system
	UI_PAGE_DESCRIPTOR	ui_global_caption_display_timeout_contrast,ui_global_title_system,17,0,18,0,ui_install_global_parameter_callbacks,0,$00

; ---- ui_global_page_descriptor_11_version ----
	org	ui_global_page_descriptor_11_version
	UI_PAGE_DESCRIPTOR	FIRMWARE_VERSION_STRING,ui_parameter_alias_empty,0,0,0,0,ui_render_board_caption,0,$01

; ---- ui_menu_page_counts ----
	org	ui_menu_page_counts
	; Five word counts clamp each menu bank.
	dc.w	EDITION_OSC_PAGE_COUNT,13,36,15,12

; ---- ui_edit_parameter_read_selector ----
	org	ui_edit_parameter_read_selector
	jsr	edition_dial_select.l

; ---- ui_edit_parameter_read_selector ----
	org	$104a0c
	jsr	morph_dial_step.l

; ---- diag_led_cursor_scan_codes ----
	org	diag_led_cursor_scan_codes
	include	"features/region_panel.asm"
	if	*>EDITION_REGION_PANEL_END
	error	"The panel-test region overflows"
	endif
	if	*<EDITION_REGION_PANEL_END
	dc.b	[EDITION_REGION_PANEL_END-*]$ff
	endif

; ---- ui_install_expanded_voice_map ----
	org	ui_install_expanded_voice_map
	; v2.33: move.w #VOICE_EXPANDED_COUNT,VOICE_COUNT.l (and the 30-entry fill
	; below)
	jmp	voices_install_map.l
	nop

; ---- ui_init_active_page_descriptor ----
	org	ui_init_active_page_descriptor
	; Boot opens the Osc bank's first page.
	move.l	#edition_osc_pages, UI_ACTIVE_PAGE_DESCRIPTOR.l

; ---- ui_invalidate_slot_loaded_wavetables ----
	org	$105bb4
	jsr	warp_dest_order_a2.l
	lea.l	ui_mod_dest_order_inverse_map.l, a1

; ---- ui_build_mod_dest_order_inverse_map ----
	org	$105bcc
	cmpi.w	#UI_MOD_DEST_ORDER_LAST, d3

; ---- ui_test_startup_front_panel_diagnostics ----
	org	$105dd6
	nop
	nop

; ---- ui_arp_clock_service_demo ----
	org	ui_arp_clock_service_demo
	; v2.33: jsr UI_DEMO_ADVANCE.l (the demo player; its space is edition code)
	jsr	edition_demo_gone.l

; ---- ui_service_publish_tick_snapshot ----
	org	ui_service_publish_tick_snapshot
	; Runs once per new timer tick.
	jsr	osc2_table_service.l
	nop

; ---- ui_service_refresh_voice_groups ----
	org	ui_service_refresh_voice_groups
	; v2.33: cmpi.w #VOICE_EXPANDED_COUNT,VOICE_COUNT.l
	jmp	voices_refresh.l
	nop

; ---- ui_service_demo_check_exit ----
	org	$1066fe
	jsr	edition_demo_gone.l

; ---- ui_update_playback_menu_start_demo ----
	org	ui_update_playback_menu_start_demo
	; v2.33: jsr UI_DEMO_START.l (the demo song; its space is now edition code)
	nop
	nop
	nop

; ---- ui_dispatch_display_parameter_select ----
	org	ui_dispatch_display_parameter_select
	jmp	edition_display_dispatch.l
	nop

; ---- ui_mod_dest_add_order_delta ----
	org	$1087aa
	lea.l	ui_mod_dest_order_inverse_map.l, a0

; ---- ui_mod_dest_clamp_upper ----
	org	ui_mod_dest_clamp_upper

	cmpi.w	#UI_MOD_DEST_ORDER_LAST, d3

; ---- ui_mod_dest_clamp_upper ----
	org	$1087c4
	moveq	#UI_MOD_DEST_ORDER_LAST, d3

; ---- ui_mod_dest_store_index_render ----
	org	$1087c8
	jsr	warp_dest_order_a0.l

; ---- dispatch_parameter_page ----
	org	$10a118
	jsr	morph_dispatch_selector.l

; ---- midi_dispatch_status_switch ----
	org	midi_dispatch_status_switch
	; D4 is a $f0-masked status class.
	jsr	mpe_dispatch_gate.l

; ---- midi_pitch_bend_full_scale ----
	org	midi_pitch_bend_full_scale
	jsr	mpe_bend_decode.l
	nop
	nop
	nop

; ---- midi_pitch_bend_voice_scan_start ----
	org	midi_pitch_bend_voice_scan_start
	jsr	mpe_bend_apply.l
	nop

; ---- midi_channel_pressure ----
	org	midi_channel_pressure
	; Channel Pressure uses packet byte 1 as the 7-bit pressure value.
	jsr	mpe_pressure_apply.l

; ---- midi_control_change ----
	org	midi_control_change
	; Control W..Z: when the controller number matches one of the four assigned
	; controller numbers, store value<<8 in that control's channel table and in
	; the matching modulation-source slot of every voice on this channel.
	jsr	mpe_control_change.l

; ---- sound_parameter_page_map ----
	org	sound_parameter_page_map
	; Osc bank pages from 4 on are one later than v2.33's ([X-Mod] at 4), from 8
	; on three later ([Wave2 3] at 9, [Warp] at 10) and from [Mix] on four later
	; ([Interp] at 12); see EDITION_OSC_PAGE_COUNT.
	dc.w	11,0,0,0,$ffff,1,0,1
	; v2.33: dc.w $ffff,$ffff,$ffff,$ffff,2,2,2,$ffff $08 (X-Mod) is on [X-Mod],
	; page 4
	dc.w	4,$ffff,$ffff,$ffff,2,2,2,$ffff
	; v2.33: dc.w 3,3,2,3,$ffff,$ffff,$ffff,$ffff $14/$15/$17 (warps) are on
	; [Warp], page 10
	dc.w	3,3,2,3,10,10,$ffff,10
	; v2.33: dc.w $ffff,4,4,4,5,5,5,5
	dc.w	$ffff,5,5,5,6,6,6,6
	; v2.33: dc.w $ffff,$ffff,$ffff,$ffff,6,6,7,7 $20 (W2 warp mode) is on
	; [Warp]; $23 (Wave2 table) on [Wave2 3], page 9
	dc.w	10,$ffff,$ffff,9,7,7,8,8
	; v2.33: dc.w 7,7,6,$ffff,$ffff,$ffff,$ffff,9 [Mix] is page 13, after
	; [Interp] (12)
	dc.w	8,8,7,$ffff,$ffff,$ffff,$ffff,13
	; v2.33: dc.w 9,9,9,$ffff,$ffff,8,8,8
	dc.w	13,13,13,$ffff,$ffff,11,11,11
	; v2.33: dc.w $ffff,$ffff,10,10,10,10,256,256 v2.33 maps the Play Access
	; bytes $3a..$3d to [Mix 2], one page before [Play Access]; kept $38 (Interp)
	; is on [Interp], page 12
	dc.w	12,$ffff,14,14,14,14,256,256

; ---- single_parameter_metadata_xmod_mode ----
	org	single_parameter_metadata_xmod_mode
	; $08, the X-Mod mode.
	dc.l	xmod_parameter_name
	dc.b	0,0,XMOD_MODE_LAST,1,1,XMOD_FORMAT

; ---- single_parameter_metadata_warp1_amount ----
	org	single_parameter_metadata_warp1_amount
	; $14, the W1 warp amount.
	dc.l	warp_amount_parameter_name
	dc.b	0,0,127,1,0,WARP1_AMOUNT_FORMAT

; ---- single_parameter_metadata_warp1_mode ----
	org	single_parameter_metadata_warp1_mode
	; $15, the W1 warp mode.
	dc.l	warp1_parameter_name
	dc.b	0,0,WARP_MODE_LAST,1,1,WARP_FORMAT

; ---- single_parameter_metadata_warp2_amount ----
	org	single_parameter_metadata_warp2_amount
	; $17, the W2 warp amount.
	dc.l	warp_amount_parameter_name
	dc.b	0,0,127,1,0,WARP2_AMOUNT_FORMAT

; ---- single_parameter_metadata_warp2_amount ----
	org	$10bb1c
	dc.b	0,0,63,1,0,WAVE1_POSITION_FORMAT

; ---- single_parameter_metadata_warp2_mode ----
	org	single_parameter_metadata_warp2_mode
	; $20, the W2 warp mode.
	dc.l	warp2_parameter_name
	dc.b	0,0,WARP_MODE_LAST,1,1,WARP_FORMAT

; ---- single_parameter_metadata_wave2_table ----
	org	single_parameter_metadata_wave2_table
	dc.l	osc2_table_parameter_name
	dc.b	0,0,OSC2_TABLE_CODE_MAX,1,0,OSC2_TABLE_FORMAT

; ---- single_parameter_metadata_wave2_table ----
	org	$10bb80
	dc.b	0,0,63,1,0,WAVE2_POSITION_FORMAT

; ---- single_parameter_metadata_wave2_table ----
	org	$10bc2a
	dc.b	0,0,ALIASING_LAST,1,1,ALIASING_FORMAT

; ---- single_parameter_metadata_wave2_table ----
	org	$10bc44
	dc.l	morph_parameter_name
	dc.b	0,0,INTERP_LAST,1,1,INTERP_FORMAT

; ---- single_parameter_metadata_wave2_table ----
	org	$10c1a8
	UI_PARAMETER_RECORD	ui_parameter_descriptor_caption_m1_destination,0,0,MOD_DEST_LAST,1,1,11

; ---- single_parameter_metadata_wave2_table ----
	org	$10c1c6
	UI_PARAMETER_RECORD	ui_parameter_descriptor_caption_m2_destination,0,0,MOD_DEST_LAST,1,1,11

; ---- single_parameter_metadata_wave2_table ----
	org	$10c1e4
	UI_PARAMETER_RECORD	ui_parameter_descriptor_caption_m3_destination,0,0,MOD_DEST_LAST,1,1,11

; ---- single_parameter_metadata_wave2_table ----
	org	$10c202
	UI_PARAMETER_RECORD	ui_parameter_descriptor_caption_m4_destination,0,0,MOD_DEST_LAST,1,1,11

; ---- single_parameter_metadata_wave2_table ----
	org	$10c220
	UI_PARAMETER_RECORD	ui_parameter_descriptor_caption_m5_destination,0,0,MOD_DEST_LAST,1,1,11

; ---- single_parameter_metadata_wave2_table ----
	org	$10c23e
	UI_PARAMETER_RECORD	ui_parameter_descriptor_caption_m6_destination,0,0,MOD_DEST_LAST,1,1,11

; ---- single_parameter_metadata_wave2_table ----
	org	$10c25c
	UI_PARAMETER_RECORD	ui_parameter_descriptor_caption_m7_destination,0,0,MOD_DEST_LAST,1,1,11

; ---- single_parameter_metadata_wave2_table ----
	org	$10c27a
	UI_PARAMETER_RECORD	ui_parameter_descriptor_caption_m8_destination,0,0,MOD_DEST_LAST,1,1,11

; ---- single_parameter_metadata_wave2_table ----
	org	$10c298
	UI_PARAMETER_RECORD	ui_parameter_descriptor_caption_m9_destination,0,0,MOD_DEST_LAST,1,1,11

; ---- single_parameter_metadata_wave2_table ----
	org	$10c2b6
	UI_PARAMETER_RECORD	ui_parameter_descriptor_caption_m10_destination,0,0,MOD_DEST_LAST,1,1,11

; ---- single_parameter_metadata_wave2_table ----
	org	$10c2d4
	UI_PARAMETER_RECORD	ui_parameter_descriptor_caption_m11_destination,0,0,MOD_DEST_LAST,1,1,11

; ---- single_parameter_metadata_wave2_table ----
	org	$10c2f2
	UI_PARAMETER_RECORD	ui_parameter_descriptor_caption_m12_destination,0,0,MOD_DEST_LAST,1,1,11

; ---- single_parameter_metadata_wave2_table ----
	org	$10c310
	UI_PARAMETER_RECORD	ui_parameter_descriptor_caption_m13_destination,0,0,MOD_DEST_LAST,1,1,11

; ---- single_parameter_metadata_wave2_table ----
	org	$10c32e
	UI_PARAMETER_RECORD	ui_parameter_descriptor_caption_m14_destination,0,0,MOD_DEST_LAST,1,1,11

; ---- single_parameter_metadata_wave2_table ----
	org	$10c34c
	UI_PARAMETER_RECORD	ui_parameter_descriptor_caption_m15_destination,0,0,MOD_DEST_LAST,1,1,11

; ---- single_parameter_metadata_wave2_table ----
	org	$10c36a
	UI_PARAMETER_RECORD	ui_parameter_descriptor_caption_m16_destination,0,0,MOD_DEST_LAST,1,1,11

; ---- ui_page_group_descriptor_tables ----
	org	ui_page_group_descriptor_tables
	; Every page lookup goes through this table and ui_menu_page_counts.
	dc.l	edition_osc_pages

; ---- voice_lifecycle_allocate ----
	org	voice_lifecycle_allocate
	jmp	mpe_note_on.l
	nop

; ---- voice_lifecycle_release_matching_compare ----
	org	voice_lifecycle_release_matching_compare
	jmp	mpe_note_off_compare.l
	nop
	nop

; ---- UI_FORMAT_MOD_DESTINATION_NAME ----
	org	UI_FORMAT_MOD_DESTINATION_NAME
	; v2.33: lea.l UI_MODULATION_DESTINATION_NAMES.l,a1
	jsr	warp_dest_names.l

; ---- SYNTH_UPLOAD_SEEDED_WAVES ----
	org	SYNTH_UPLOAD_SEEDED_WAVES
	include	"features/region_seeded.asm"
	if	*>EDITION_REGION_SEEDED_END
	error	"The seeded-wave region overflows"
	endif
	if	*<EDITION_REGION_SEEDED_END
	dc.b	[EDITION_REGION_SEEDED_END-*]$ff
	endif

; ---- frame_clear_modulation_sums ----
	org	$111288
	bsr.w	warp_mod_set

; ---- frame_clear_modulation_sums ----
	org	$111296
	bsr.w	warp_mod_add

; ---- frame_clear_modulation_sums ----
	org	$1112a4
	bsr.w	warp_mod_add

; ---- frame_clear_modulation_sums ----
	org	$1112b2
	bsr.w	warp_mod_add

; ---- FRAME_SECONDARY_RECORD_LOOP ----
	org	$1112e2
	bsr.w	warp_mod_add

; ---- frame_wave_bend_range ----
	org	frame_wave_bend_range
	jsr	mpe_osc1_bend_range.l

; ---- frame_wave_pitch_interpolate ----
	org	$111c06
	jsr	morph_wave1_index.l
	nop
	nop
	nop

; ---- frame_wave_index_pack ----
	org	$111c38
	jsr	honda_octave_seed.l
	nop

; ---- frame_wave_base_and_coeff_emit ----
	org	$111cb8
	jsr	honda_wave1_mask.l

; ---- frame_osc2_bend_range_dispatch ----
	org	frame_osc2_bend_range_dispatch
	jsr	mpe_osc2_bend_range.l

; ---- frame_osc2_ratio_emit ----
	org	$111de0
	jsr	morph_edge_wave1.l

; ---- frame_osc2_wave_index_add ----
	org	frame_osc2_wave_index_add
	jsr	morph_wave2_index.l

; ---- frame_osc2_wave_index_pack ----
	org	$111e84
	jsr	honda_octave_seed.l
	nop

; ---- frame_osc2_block_select ----
	org	frame_osc2_block_select
	jsr	osc2_table_block.l

; ---- frame_osc2_wave_words_emit ----
	org	$111efe
	jsr	honda_osc2_mask.l

; ---- frame_output_ringmod_level_emit ----
	org	frame_output_ringmod_level_emit
	jsr	xmod_ring_emit.l

; ---- filter1_frame_emit_cubic_control ----
	org	filter1_frame_emit_cubic_control
	jmp	xmod_frame_emit.l
	nop
	nop
	nop
	nop

; ---- platform_render_wave_table_ramp ----
	org	platform_render_wave_table_ramp
	include	"features/region_ramp.asm"
	if	*>EDITION_REGION_RAMP_END
	error	"The ramp-wavetable region overflows"
	endif
	if	*<EDITION_REGION_RAMP_END
	dc.b	[EDITION_REGION_RAMP_END-*]$ff
	endif

; ---- storage_packed_field_widths_20 ----
	org	storage_packed_field_widths_20
	; $22 (no reader) gives its 7 bits to $23, the Wave2 table, so stored Sounds
	; read their old $22 bits as $23: zero in every Sound but one.
	dc.b	6,7,0,7,6,7,7,7,7,1,1,6,7,7,0,7

; ---- preset_table_parameter_cc_numbers_4 ----
	org	preset_table_parameter_cc_numbers_4
	; v2.33: dc.b 0,36,37,13,0,0,0,0,38,39,40,0,41,42,43,44
	dc.b	0,36,37,13,XMOD_CC,0,0,WAVE1_FINE_CC,38,39,40,0,41,42,43,44

; ---- preset_table_parameter_cc_numbers_20 ----
	org	preset_table_parameter_cc_numbers_20
	dc.b	WARP1_AMOUNT_CC,WARP1_MODE_CC,0,WARP2_AMOUNT_CC,0,70,71,72,73,74,75,76,WARP2_MODE_CC,0,0,OSC2_TABLE_CC

; ---- preset_table_parameter_cc_numbers_36 ----
	org	preset_table_parameter_cc_numbers_36
	; v2.33: dc.b 77,78,79,80,81,82,83,0,0,0,0,45,46,47,48,0
	dc.b	77,78,79,80,81,82,83,0,0,0,WAVE2_FINE_CC,45,46,47,48,0

; ---- preset_sysex_info_front_panel_test ----
	org	$1170f2
	nop
	nop
	nop

; ---- MIDI_CC_SOUND_PARAMETER_MAP ----
	org	MIDI_CC_SOUND_PARAMETER_MAP
	; v2.33: dc.b 0,0,0,0,0,90,0,0,0,0,84,0,82,7,113,114
	dc.b	0,0,0,SOUND_XMOD_MODE,0,90,0,0,SOUND_WAVE1_FINE,SOUND_WAVE2_FINE,84,0,82,7,113,114

; ---- midi_cc_sound_parameter_map_48 ----
	org	midi_cc_sound_parameter_map_48
	; v2.33: dc.b 50,0,62,65,66,67,64,80,63,77,79,0,73,74,75,0
	dc.b	50,SOUND_WARP1_MODE,62,65,66,67,64,80,63,77,79,SOUND_WARP1_AMOUNT,73,74,75,SOUND_WARP2_MODE

; ---- midi_cc_sound_parameter_map_80 ----
	org	midi_cc_sound_parameter_map_80
	; v2.33: dc.b 39,40,41,42,0,149,150,151,152,153,154,155,156,157,193,196
	dc.b	39,40,41,42,SOUND_WAVE2_TABLE,149,150,151,152,153,154,155,156,157,193,196

; ---- midi_cc_sound_parameter_map_112 ----
	org	midi_cc_sound_parameter_map_112
	; v2.33: dc.b 162,163,164,169,170,171,172,0,0,0,0,0,0,0,0,0
	dc.b	162,163,164,169,170,171,172,SOUND_WARP2_AMOUNT,0,0,0,0,0,0,0,0

; ---- UI_DEMO_INITIAL_EVENTS ----
	org	UI_DEMO_INITIAL_EVENTS
	include	"features/region_demo.asm"
	if	*>EDITION_REGION_DEMO_END
	error	"The demo-song region overflows"
	endif
	if	*<EDITION_REGION_DEMO_END
	dc.b	[EDITION_REGION_DEMO_END-*]$ff
	endif

; ---- FIRMWARE_VERSION_STRING ----
	org	FIRMWARE_VERSION_STRING
	; Row 2 names the edition after column 13; the Version page writes its board
	; caption ("Board #3+VEX") over columns 1..12.
	dc.b	" Waldorf Microwave 2   Version 2.33     ","              ",EDITION_TEXT,0

; ---- effect_type_set ----
	org	$11a4de
	jsr	effect_group_buffer.l

; ---- effect_type_set_check_group_1 ----
	org	$11a50a
	jsr	effect_group_buffer.l

; ---- effect_type_set_check_group_2 ----
	org	$11a538
	jsr	effect_group_buffer.l

; ---- effect_parameter_set ----
	org	effect_parameter_set
	; Nonzero D1 sets one effect parameter.
effect_parameter_ladder_start:
	tst.w	d6
	bmi.w	effect_update_return
	move.w	d6, d0
	lsl.w	#MIDI_DSP_GROUP_STRIDE_SHIFT, d0
	movea.w	d0, a4
	lea.l	MIDI_DSP_GROUP_RECORD_BASE_0(a4), a4
	bsr.b	effect_group_buffer
	bra.b	effect_parameter_store_and_dispatch

; ---- effect_group_buffer ----
	org	effect_group_buffer
	moveq	#0, d4
	move.w	d6, d4
	cmpi.w	#MIDI_DSP_VARIANT_XT, PLATFORM_DSP_VARIANT.w
	bne.b	effect_group_buffer_internal
	swap	d4
	lsr.l	#16-MIDI_DSP_GROUP_DELAY_BUFFER_SHIFT, d4
	addi.l	#MIDI_DSP_GROUP_DELAY_BUFFER_0, d4
	rts

; ---- effect_group_buffer_internal ----
	org	effect_group_buffer_internal
	lsl.l	#8, d4
	lsl.l	#MIDI_DSP_GROUP_BUFFER_SHIFT-8, d4
	addi.l	#MIDI_DSP_GROUP_BUFFER_0, d4
	rts

; ---- effect_parameter_ladder_end ----
	org	effect_parameter_ladder_end
	dc.w	ROM_FILL_WORD,ROM_FILL_WORD

; ---- dsp_host_stream_next ----
	org	dsp_host_stream_next
	jmp	xmod_dsp_stream_next.l
	nop
	nop
	nop
; ---- The extension ----

	org	ROM_IMAGE_END+1
	include	"features/features.asm"
	if	*>EDITION_IMAGE_END+1
	error	"The Tallent Edition extension overflows the OS bank's update packets"
	endif
