; Morph: Sound byte $38 (Interp), E352 and Honda interpolation
; (features/morph/morph.asm).
SOUND_INTERP          equ  $38
INTERP_XT             equ  0
INTERP_E352           equ  1
INTERP_HONDA          equ  2
INTERP_LAST           equ  INTERP_HONDA
INTERP_NAME_CHARS     equ  9
MORPH_EDGE_BIAS       equ  $800000
MORPH_FRACTION_SHIFT  equ  7
MORPH_HALF_WAVE_SHIFT equ  1
MORPH_EVEN_MASK       equ  $fffe
MORPH_STATE_WAVE1     equ  0
MORPH_STATE_WAVE2     equ  2
MORPH_VOICE_SHIFT     equ  2
MORPH_TRACE_SHIFT     equ  8
MORPH_TRACE_MASK      equ  $fffe
MORPH_STILL           equ  1
MORPH_EASE            equ  1
; Fine: hundredths of a wave past Startwave, which Shift with a Startwave dial
; steps on an E352 or Honda Sound (morph_dial_step).
SOUND_WAVE1_FINE      equ  $0b
SOUND_WAVE2_FINE      equ  $2e
WAVE1_FINE_CC         equ  8
WAVE2_FINE_CC         equ  9
MORPH_FINE_STEPS      equ  100
MORPH_FINE_LAST       equ  99
MORPH_FINE_SCALE      equ  655
MORPH_POSITION_COLUMN equ  3
MORPH_POSITION_DIGITS equ  2
