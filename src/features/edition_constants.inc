; Tallent Edition constants shared by every feature in features/: the image
; limit, the free RAM each feature owns, and the display formatter selectors
; added past the stock ones.

; ---- Image ----
; The 128 KiB OS bank holds the stock image and the extension after it.
EDITION_IMAGE_END  equ  $11ffb7

; ---- RAM ----
; EDITION_RAM is the controller SRAM between the DSP channel-port table and
; the SysEx receive buffer.
DSP_CHANNEL_PORT_TABLE_BYTES equ (FRAME_DSP_PORT_INDEX_MASK+1)*4
EDITION_RAM        equ  PLATFORM_DSP_CHANNEL_PORT_TABLE+DSP_CHANNEL_PORT_TABLE_BYTES
EDITION_RAM_END    equ  PLATFORM_RAM_SYSEX_BUFFER
MPE_RAM            equ  EDITION_RAM
MPE_RAM_BYTES      equ  64
OSC2_TABLE_RAM     equ  MPE_RAM+MPE_RAM_BYTES
OSC2_TABLE_RAM_BYTES equ  2
MORPH_RAM          equ  OSC2_TABLE_RAM+OSC2_TABLE_RAM_BYTES
MORPH_VOICE_BYTES  equ  4
MORPH_RAM_BYTES    equ  VOICE_EXPANDED_COUNT*MORPH_VOICE_BYTES

; ---- Display formatter selectors ----
; ui_dispatch_display_parameter's stock table ends at
; ui_display_parameter_selector_max; edition_display_dispatch serves these.
MPE_MODE_FORMAT    equ  ui_display_parameter_selector_max+1
OSC2_TABLE_FORMAT  equ  ui_display_parameter_selector_max+2
XMOD_FORMAT        equ  ui_display_parameter_selector_max+3
WARP_FORMAT        equ  ui_display_parameter_selector_max+4
ALIASING_FORMAT    equ  ui_display_parameter_selector_max+5
INTERP_FORMAT      equ  ui_display_parameter_selector_max+6
WAVE1_POSITION_FORMAT equ  ui_display_parameter_selector_max+7
WAVE2_POSITION_FORMAT equ  ui_display_parameter_selector_max+8
WARP1_AMOUNT_FORMAT equ  ui_display_parameter_selector_max+9
WARP2_AMOUNT_FORMAT equ  ui_display_parameter_selector_max+10

; ---- Osc menu bank (osc_bank.asm) ----
; Pages: 0 Osc1 1, 1 Osc1 2, 2 Osc2 1, 3 Osc2 2, 4 X-Mod, 5 Wave1 1, 6 Wave1
; 2, 7 Wave2 1, 8 Wave2 2, 9 Wave2 3, 10 Warp, 11 Quality, 12 Interp, 13 Mix,
; 14 Mix 2, 15 Play Access.
EDITION_OSC_PAGE_COUNT  equ  16
EDITION_PAGE_XMOD       equ  4
EDITION_PAGE_WAVE2_3    equ  9
EDITION_PAGE_WARP       equ  10

; ---- Page descriptors ----
UI_PAGE_FLAG_XT_ONLY    equ  $04
EDITION_PAGE_DESCRIPTOR macro caption,title,slot0,slot1,slot2,slot3,callback,flags0,flags1
	dc.l	caption,title
	dc.b	slot0,slot1,slot2,slot3
	dc.l	callback
	dc.b	flags0,flags1
	endm

; ---- Extension regions ----
EDITION_REGION_DEMO_END  equ  $1193fc
EDITION_REGION_SEEDED_END equ  $10f6a6
EDITION_REGION_RAMP_END  equ  $114abc
EDITION_REGION_PANEL_END equ  $105a4c
EDITION_REGION_WAIT_END  equ  $11a324
EDITION_REGION_OUTPUT_END equ $1199dc
