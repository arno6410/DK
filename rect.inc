GLOBAL 	fillRect:PROC, \
	drawRectangle:PROC, \
	drawRects:PROC, \
	platform_both:PROC, \
	platformDown:PROC, \
	platformUp:PROC, \
	collision_down:PROC

STRUC rect
	x	dd 0
	y	dd 0
	w	dd 0
	h	dd 0
ENDS rect

STRUC platform
	x	dd 0		; x position
	y	dd 0		; y position
	w	dd 0		; width
	h	dd 0		; height
	color	dd 0		; color
ENDS platform

STRUC newPlatform
	x0	dd 0
	y0	dd 0
	x1	dd 0
	y1	dd 0
	h	dd 0
	color	dd 0
ENDS newPlatform