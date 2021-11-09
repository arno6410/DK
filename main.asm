IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT, ds:FLAT, es:FLAT, fs:FLAT, gs:FLAT



VMEMADR EQU 0A0000h	; video memory address
SCRWIDTH EQU 320	; screen witdth
SCRHEIGHT EQU 200	; screen height

CODESEG

INCLUDE "utils.inc"
INCLUDE "rect.inc"

PROC main
	sti
	cld
	
	push ds
	pop es
	
	call setVideoMode, 13h
	
	call fillRect, 60, 60, 60, 60, 25h
	
	; exit on esc
	call waitForSpecificKeystroke, 1Bh
	call terminateProcess
ENDP main	

DATASEG
	
STACK 100h

END main