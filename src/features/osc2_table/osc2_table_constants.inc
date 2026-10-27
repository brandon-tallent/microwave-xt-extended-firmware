; ---- Sound byte ----
; $23 sits where Wave2 mirrors Wave1's $19 (Wave1 $19..$1f, Wave2 +10).
SOUND_WAVE2_TABLE          equ  $23
OSC2_TABLE_FOLLOW          equ  0
OSC2_TABLE_ROM_CODE_LAST   equ  65
; Codes 66..127 are tables 66..127 (66..95 reserved, 96..127 user tables), so
; every real table and "follow" fit in seven bits.
OSC2_TABLE_CODE_MAX        equ  127
OSC2_TABLE_CC              equ  84

; ---- Blocks ----
OSC2_TABLE_PARTNER_FLIP    equ  4
OSC2_TABLE_SLOT_MASK       equ  7

; ---- RAM ----
; Bit s set: slot s's Osc2 reads the partner block, which holds its table.
OSC2_TABLE_OWN_MASK        equ  OSC2_TABLE_RAM
	if	OSC2_TABLE_OWN_MASK+1>OSC2_TABLE_RAM+OSC2_TABLE_RAM_BYTES
	error	"Osc2 table state overflows its RAM slice"
	endif

; ---- Service ----
OSC2_TABLE_POLL_TICK_MASK  equ  15

; ---- Display ----
; The stock Wavetable field: table number (index + 1) at +1..+3, the nine-
; character name at +5..+13.
OSC2_TABLE_FOLLOW_TEXT_OFFSET  equ  1
OSC2_TABLE_FOLLOW_TEXT_CHARS   equ  13
