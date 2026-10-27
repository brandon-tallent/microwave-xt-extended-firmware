xmod_dsp_stream:
	include	"features/xmod/dsp_stream.inc"
xmod_dsp_stream_end:
	if	(xmod_dsp_stream_end-xmod_dsp_stream)&1
	dc.b	0
	endif
