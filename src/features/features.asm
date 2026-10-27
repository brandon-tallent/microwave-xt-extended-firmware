	include	"features/edition.asm"
	include	"features/mpe/mpe.asm"
	include	"features/osc2_table/osc2_table.asm"
	include	"features/voices/voices.asm"
	include	"features/warp/warp_captions.asm"
	if	EDITION_RAM_USED_END>EDITION_RAM_END
	error	"the features' RAM slices overflow EDITION_RAM"
	endif
