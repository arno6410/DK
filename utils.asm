IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT, ds:FLAT, es:FLAT, fs:FLAT, gs:FLAT

VMEMADR EQU 0A0000h	; video memory address
SCRWIDTH EQU 320	; screen witdth
SCRHEIGHT EQU 200	; screen height

CODESEG

INCLUDE "utils.inc"


; Set the video mode
PROC setVideoMode
	ARG @@mode: byte
	USES eax

	movzx ax,[@@mode]
	int 10h

	ret
ENDP setVideoMode

PROC waitForSpecificKeystroke
	ARG @@key: byte
	USES eax
	
@@wait:
	mov ah, 00h
	int 16h
	cmp al, [@@key]
	jne @@wait
	
	ret
ENDP waitForSpecificKeystroke

PROC terminateProcess
	USES eax
	
	call setVideoMode, 03h
	mov	ax, 04C00h
	int 21h
	
	ret
ENDP terminateProcess	

DATASEG
	
STACK 100h

END 