GLOBAL 	fillRect:PROC, \
	drawRectangle:PROC, \
	platform_both:PROC, \
	collision_down:PROC

STRUC rect
	x	dd 0
	y	dd 0
	w	dd 0
	h	dd 0
ENDS rect

STRUC newPlatform
	x0	dd 0
	y0	dd 0
	x1	dd 0
	y1	dd 0
	h	dd 0
	color	dd 0
ENDS newPlatform