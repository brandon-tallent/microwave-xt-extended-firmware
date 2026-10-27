; MIDI Polyphonic Expression (MPE) constants and RAM for features/mpe/mpe.asm.

; ---- Global ----
MPE_MODE  equ  GLOBAL_PARAMETERS+30
MPE_MODE_ON         equ  1
MPE_MODE_ZONE_BEND  equ  2
MPE_MODE_LAST       equ  MPE_MODE_ZONE_BEND
MPE_MODE_NAME_CHARS equ  9

; ---- Channel state ----
; MPE_RAM starts at zero, so the state starts with no Zone and no RPN.
MPE_CHANNELS               equ  MIDI_CHANNEL_MASK+1
MPE_RPN_MSB_TABLE          equ  MPE_RAM
MPE_RPN_LSB_TABLE          equ  MPE_RPN_MSB_TABLE+MPE_CHANNELS
MPE_RPN_FLAGS_TABLE        equ  MPE_RPN_LSB_TABLE+MPE_CHANNELS
MPE_MEMBER_COUNT           equ  MPE_RPN_FLAGS_TABLE+MPE_CHANNELS
MPE_MANAGER_BEND_RANGE     equ  MPE_MEMBER_COUNT+1
MPE_MEMBER_BEND_RANGE      equ  MPE_MEMBER_COUNT+2
MPE_BEND_RANGES_VALID      equ  MPE_MEMBER_COUNT+3
	if	MPE_BEND_RANGES_VALID+1>MPE_RAM+MPE_RAM_BYTES
	error	"MPE state overflows its RAM slice"
	endif

; Y is the stock Control Y channel table (controller table 12, one word a
; channel, value<<8): the Manager's Y is what the stock Control Y path stores
; for channel 1, and Members store theirs beside it.
MPE_Y_TABLE                equ  VOICE_CHANNEL_CONTROLLER_TABLES+32*12

; ---- RPN selection ----
MPE_RPN_MSB_SELECTED       equ  1
MPE_RPN_LSB_SELECTED       equ  2
MPE_RPN_SELECTED           equ  MPE_RPN_MSB_SELECTED|MPE_RPN_LSB_SELECTED
MIDI_RPN_PITCH_BEND_SENSITIVITY  equ  $00
MIDI_RPN_MPE_CONFIGURATION       equ  $06

; ---- Zone ----
MPE_MEMBER_CHANNELS_MAX    equ  15
MPE_BEND_RANGE_MAX         equ  96
MPE_BEND_RANGE_GLOBAL      equ  HARMONIC_BEND_MODE+1
MPE_MANAGER_BEND_DEFAULT   equ  2
MPE_MEMBER_BEND_DEFAULT    equ  48

; ---- Voices ----
; A held note's voice has AmpEnv stage Decay (2) or Attack (3), or the
; allocator's reservation (VOICE_RESERVED_VOICE_STATE, 4) while it starts;
; Release (1) and free (0) voices are not held.
MPE_HELD_STAGE_MIN         equ  ENV_STAGE_DECAY

; ---- Dimensions ----
MPE_VALUE_SHIFT            equ  8
MPE_DIMENSION_MAX          equ  MIDI_7BIT_MAX<<MPE_VALUE_SHIFT
MPE_BEND_MIN               equ  -$8000

; ---- Display: the named incoming Y-CC formatter ----
MPE_FORMAT_FIELD_LONGS     equ  5
MPE_FORMAT_SPACES          equ  '    '
MPE_Y_CC_NAME_CHARS        equ  9
MPE_PARAMETER_RECORD_BYTES equ  10
