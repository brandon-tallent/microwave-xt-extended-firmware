; Board #1: a Microwave II's main board.

BOARD1_VOICES           equ  8
BOARD1_DSP_VARIANT_XT   equ  1
CCR_Z_MASK              equ  $04

board1:
	; Z set on Board #1: a DSP variant other than BOARD1_DSP_VARIANT_XT and no
	; expansion (the Version page's "Board #1", ui_render_board_caption).
	cmpi.w	#BOARD1_DSP_VARIANT_XT,PLATFORM_DSP_VARIANT.l
	beq.b	board1_not
	tst.w	PLATFORM_DSP_BOARD_CONFIG.l
	rts
board1_not:
	andi.b	#~CCR_Z_MASK,ccr
	rts

board1_voice_count:
	cmpi.w	#PLATFORM_DSP_BOARD_CONFIG_THREE_DSPS,PLATFORM_DSP_BOARD_CONFIG.l
	bne.b	board1_voice_count_single
	jmp	voices_install_map.l
board1_voice_count_single:
	bsr.b	board1
	bne.b	board1_voice_count_done
	move.w	#BOARD1_VOICES,VOICE_COUNT.l
board1_voice_count_done:
	jmp	ui_begin_global_init_dial_prime.l
