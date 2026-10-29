; X-Mod's display (features/xmod/xmod.asm), in the ramp region beside its name
; table.

xmod_display:
	movea.l	d2,a0
	lea	xmod_mode_names.l,a1
	move.w	d3,d0
	cmpi.w	#XMOD_MODE_LAST,d0
	bls.b	xmod_display_known
	moveq	#XMOD_MODE_FM,d0
xmod_display_known:
	mulu.w	#XMOD_MODE_NAME_CHARS,d0
	adda.w	d0,a1
	moveq	#XMOD_MODE_NAME_CHARS-1,d0
xmod_display_char:
	move.b	(a1)+,(a0)+
	dbf	d0,xmod_display_char
	jmp	ui_dispatch_display_parameter_return.l
