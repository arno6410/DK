IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT, ds:FLAT, es:FLAT, fs:FLAT, gs:FLAT



VMEMADR EQU 0A0000h	; video memory address
SCRWIDTH EQU 320	; screen witdth
SCRHEIGHT EQU 200	; screen height
FRAMESIZE EQU 256	; mario size (16x16)

CODESEG

INCLUDE "utils.inc"
INCLUDE "rect.inc"

STRUC character
	x		dd 0		; x position
	y		dd 0		; y position
	speed_x	dd 0		; x speedcomponent
	speed_y	dd 0		; y speedcomponent
ENDS character

PROC main
	sti
	cld
	
	push ds
	pop es
	
	call setVideoMode, 13h
	
	call fillRect, 0, 180, 320, 200, 25h
	call fillRect, [mario.x], 150, 20, 30, 33h
	
	; exit on esc
	call waitForSpecificKeystroke, 1Bh
	call terminateProcess
ENDP main	

DATASEG
	mario character <30,150,0,0>
	openErrorMsg db "could not open file", 13, 10, '$'
	readErrorMsg db "could not read data", 13, 10, '$'
	closeErrorMsg db "error during file closing", 13, 10, '$'

UDATASEG;
	;filehandle dw ?
	;packedframe db FRAMESIZE dup (?)

	
STACK 100h

END main