; ---- Matrix destinations past v2.33's 36 (mod_dests.asm) ----
MOD_DEST_LAST        equ  MOD_DEST_FX_PARA_3
MOD_DEST_ORDER_COUNT equ  MOD_DEST_LAST+1
MOD_DEST_NAME_CHARS  equ  9

; ---- RAM ----
; The destination menu's inverse map (ui_mod_dest_order_inverse_map), a byte a
; destination, is the last EDITION_RAM slice.
MOD_DEST_ORDER_INVERSE_RAM equ  FXPARA_RAM+FXPARA_RAM_BYTES
EDITION_RAM_USED_END equ  MOD_DEST_ORDER_INVERSE_RAM+MOD_DEST_ORDER_COUNT
