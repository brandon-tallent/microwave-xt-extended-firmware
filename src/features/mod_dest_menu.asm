mod_dest_order_a0:
	jsr	board1.l
	bne.b	mod_dest_order_a0_table
	move.w	a1,d3
	subq.w	#MOD_DEST_ORDER_W1,d3
	lsr.w	#1,d3
	bne.b	mod_dest_order_a0_table
	tst.w	d4
	beq.b	mod_dest_order_a0_table
	movea.w	#MOD_DEST_ORDER_W2+1,a1
	bpl.b	mod_dest_order_a0_table
	subq.w	#MOD_DEST_ORDER_W2+1-(MOD_DEST_ORDER_W1-1),a1
mod_dest_order_a0_table:
	lea	mod_dest_order(pc),a0
	clr.w	d3
	rts
