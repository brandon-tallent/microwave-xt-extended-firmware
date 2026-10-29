; ---- Modulation ----
MOD_DEST_FX_PARA_1   equ  38
MOD_DEST_FX_PARA_2   equ  39
MOD_DEST_FX_PARA_3   equ  40
FXPARA_DEST_BIAS     equ  MOD_DEST_FX_PARA_1-EFFECT_PARAM_1
FXPARA_SETTINGS      equ  EFFECT_PARAM_3

; ---- Effect types ----
EFFECT_TYPE_OVERDRIVE equ  6

; ---- Effect state ----
; MIDI_EFFECT_UPDATE_DISPATCH caches each value it sends, a long a setting in
; a group's row (MIDI_EFFECT_PARAMETER_CACHE_STRIDE bytes): the values the
; group plays.
FXPARA_SENT          equ  MIDI_RAM_EFFECT_PARAMETER_CACHE-4*EFFECT_PARAM_1

; ---- RAM ----
FXPARA_RAM           equ  WARP_MOD_RAM+WARP_MOD_RAM_BYTES
FXPARA_SUMS          equ  FXPARA_RAM
FXPARA_VOICES        equ  FXPARA_SUMS+4*FXPARA_SETTINGS
FXPARA_RAM_BYTES     equ  4*FXPARA_SETTINGS+4
