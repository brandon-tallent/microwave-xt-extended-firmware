edition_dial_shift_bytes:
	; Pairs: the Sound byte a dial edits, the byte it edits with Shift.
	dc.b	SOUND_OSC1_FM_AMOUNT,SOUND_XMOD_MODE
	dc.b	SOUND_WAVE1_ENV_AMOUNT,SOUND_WARP1_AMOUNT
	dc.b	SOUND_WAVE2_ENV_AMOUNT,SOUND_WARP2_AMOUNT
edition_dial_shift_bytes_boards:
	dc.b	SOUND_WAVETABLE,SOUND_WAVE2_TABLE
	dc.b	0
	if	(*-edition_dial_shift_bytes)&1
	dc.b	0
	endif
EDITION_DIAL_SHIFT_XT_BYTES equ edition_dial_shift_bytes_boards-edition_dial_shift_bytes
