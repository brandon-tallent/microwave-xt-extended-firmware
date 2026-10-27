; The [Wave2 3] page's caption (features/osc_bank.asm), in the seeded-wave
; region (features/region_seeded.asm).
edition_page_caption_wave2_table:
	; Slot 0's value spans two columns, as Wavetable does on [Wave1 1].
	dc.b	" Wavetable                          W2",0
	if	(*-edition_page_caption_wave2_table)&1
	dc.b	0
	endif
