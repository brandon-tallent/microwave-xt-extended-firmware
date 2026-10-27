; ---- The voice map ----
; FRAME_VOICE_DSP_MAP_TABLE holds a word per physical voice: the DSP row in
; the high byte, the PLATFORM_DSP_CHANNEL_PORT_TABLE index in the low byte.
VOICES_MAIN_SLOTS       equ  9
VOICES_EXPANSION_SLOTS  equ  8
VOICES_EXPANDED         equ  VOICES_MAIN_SLOTS+2*VOICES_EXPANSION_SLOTS
VOICES_PORT_MAIN        equ  2
VOICES_PORT_EXPANSION_2 equ  1
VOICES_PORT_EXPANSION_1 equ  0
VOICES_ROW_SHIFT        equ  8
VOICES_FIRST_EXPANSION_2 equ VOICES_MAIN_SLOTS
VOICES_FIRST_EXPANSION_1 equ VOICES_MAIN_SLOTS+VOICES_EXPANSION_SLOTS

voices_install_map:
	move.w	#VOICES_EXPANDED,VOICE_COUNT.l
	lea	voices_map(pc),a0
	lea	FRAME_VOICE_DSP_MAP_TABLE.l,a1
	moveq	#VOICES_EXPANDED-1,d0
voices_install_map_entry:
	move.w	(a0)+,(a1)+
	dbf	d0,voices_install_map_entry
	jmp	ui_begin_global_init_dial_prime.l

voices_refresh:
	cmpi.w	#VOICES_EXPANDED,VOICE_COUNT.l
	beq.b	voices_refresh_rows
	jmp	ui_service_refresh_configured_voices.l
voices_refresh_rows:
	lea	FRAME_VOICE_DSP_REFRESH_PHYSICAL_VOICE_INDEX.l,a4
	lea	ui_service_stack_event_buffer_offset(sp),a3
voices_refresh_row:
	move.w	d3,d1
	bsr.b	voices_refresh_voice
	cmpi.w	#VOICES_EXPANSION_SLOTS,d3
	bhs.b	voices_refresh_drain
	move.w	d3,d1
	addi.w	#VOICES_FIRST_EXPANSION_2,d1
	bsr.b	voices_refresh_voice
	move.w	d3,d1
	addi.w	#VOICES_FIRST_EXPANSION_1,d1
	bsr.b	voices_refresh_voice
voices_refresh_drain:
	tst.b	UI_DEMO_ACTIVE.l
	bne.b	voices_refresh_next_row
voices_refresh_drain_notes:
	move.l	a3,d0
	jsr	midi_read_transposed_note_event.l
	tst.l	d0
	beq.b	voices_refresh_drain_controls
	moveq	#MIDI_DISPATCH_SOURCE_LOCAL,d1
	move.l	a3,d0
	jsr	midi_dispatch.l
	bra.b	voices_refresh_drain_notes
voices_refresh_drain_controls:
	move.l	a3,d0
	jsr	midi_event_queue_pop.l
	tst.l	d0
	beq.b	voices_refresh_next_row
	moveq	#MIDI_DISPATCH_SOURCE_SERIAL,d1
	move.l	a3,d0
	jsr	midi_dispatch.l
	bra.b	voices_refresh_drain_controls
voices_refresh_next_row:
	addq.w	#1,d3
	cmpi.w	#VOICES_MAIN_SLOTS,d3
	blo.b	voices_refresh_row
	jmp	ui_service_read_volume_dial.l

voices_refresh_voice:
	move.w	d1,d0
	mulu.w	#VOICE_RECORD_STRIDE,d0
	addi.l	#VOICE_TABLE_BASE,d0
	jmp	(a4)

voices_map:
	; Main DSP rows 0..8, then each expansion DSP's rows 0..7.
	dc.w	0<<VOICES_ROW_SHIFT|VOICES_PORT_MAIN
	dc.w	1<<VOICES_ROW_SHIFT|VOICES_PORT_MAIN
	dc.w	2<<VOICES_ROW_SHIFT|VOICES_PORT_MAIN
	dc.w	3<<VOICES_ROW_SHIFT|VOICES_PORT_MAIN
	dc.w	4<<VOICES_ROW_SHIFT|VOICES_PORT_MAIN
	dc.w	5<<VOICES_ROW_SHIFT|VOICES_PORT_MAIN
	dc.w	6<<VOICES_ROW_SHIFT|VOICES_PORT_MAIN
	dc.w	7<<VOICES_ROW_SHIFT|VOICES_PORT_MAIN
	dc.w	8<<VOICES_ROW_SHIFT|VOICES_PORT_MAIN
	dc.w	0<<VOICES_ROW_SHIFT|VOICES_PORT_EXPANSION_2
	dc.w	1<<VOICES_ROW_SHIFT|VOICES_PORT_EXPANSION_2
	dc.w	2<<VOICES_ROW_SHIFT|VOICES_PORT_EXPANSION_2
	dc.w	3<<VOICES_ROW_SHIFT|VOICES_PORT_EXPANSION_2
	dc.w	4<<VOICES_ROW_SHIFT|VOICES_PORT_EXPANSION_2
	dc.w	5<<VOICES_ROW_SHIFT|VOICES_PORT_EXPANSION_2
	dc.w	6<<VOICES_ROW_SHIFT|VOICES_PORT_EXPANSION_2
	dc.w	7<<VOICES_ROW_SHIFT|VOICES_PORT_EXPANSION_2
	dc.w	0<<VOICES_ROW_SHIFT|VOICES_PORT_EXPANSION_1
	dc.w	1<<VOICES_ROW_SHIFT|VOICES_PORT_EXPANSION_1
	dc.w	2<<VOICES_ROW_SHIFT|VOICES_PORT_EXPANSION_1
	dc.w	3<<VOICES_ROW_SHIFT|VOICES_PORT_EXPANSION_1
	dc.w	4<<VOICES_ROW_SHIFT|VOICES_PORT_EXPANSION_1
	dc.w	5<<VOICES_ROW_SHIFT|VOICES_PORT_EXPANSION_1
	dc.w	6<<VOICES_ROW_SHIFT|VOICES_PORT_EXPANSION_1
	dc.w	7<<VOICES_ROW_SHIFT|VOICES_PORT_EXPANSION_1
