; The [X-Mod] and [Warp] pages' captions and titles (features/osc_bank.asm),
; in the extension.
edition_page_caption_xmod:
	dc.b	"  Mode   | Amount  ",0
edition_page_title_xmod:
	dc.b	"[X-Mod]",0
edition_page_caption_warp:
	dc.b	" W1 Warp | Amount  | W2 Warp | Amount",0
edition_page_title_warp:
	dc.b	"[Warp]",0
	; Pad to an even address with an owned byte.
	if	(*-edition_page_caption_xmod)&1
	dc.b	0
	endif
