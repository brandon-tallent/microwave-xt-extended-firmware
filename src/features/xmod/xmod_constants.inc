; ---- Sound byte ----
; $08 has no reader in v2.33 (a leftover "Osc1 mod source" alias, 0..31) and
; the flash pack gives it 6 bits.
SOUND_XMOD_MODE   equ  $08
XMOD_MODE_FM      equ  0
XMOD_MODE_PM      equ  1
XMOD_MODE_AM      equ  2
XMOD_MODE_FM12    equ  3
XMOD_MODE_PM12    equ  4
XMOD_MODE_LAST    equ  XMOD_MODE_PM12
XMOD_DIR_OSC1_TO_OSC2  equ  1
XMOD_AM_SCALE_SHIFT  equ  7
XMOD_CC           equ  3
XMOD_MODE_NAME_CHARS equ  9

; ---- Frame ----
; p29 follows p28 in every voice frame: d, the coefficient on the modulator's
; last sample (0 for FM), with bit 0 set for Osc1 -> Osc2.
