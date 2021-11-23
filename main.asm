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
INCLUDE "keyb.inc"

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
	
	; ecx acts as the loop counter
	mov ecx, 0
mainloop:
	push ecx
	
	; draw and update mario
	mov eax, [mario.x]
	mov ebx, [mario.y]
	call fillRect, eax, ebx, 20, 30, 33h
	mov ecx, [mario.speed_x]
	add [mario.x], ecx
	mov edx, [mario.speed_y]
	add [mario.y], edx
	
	call wait_VBLANK, 3
	; undraw mario
	call fillRect, eax, ebx, 20, 30, 0h
	
	pop ecx
	cmp ecx, 10
	jne noJump
	
	; jump by suddenly increasing the speed in the -y direction
	mov [mario.speed_y], -11
noJump:
	; gravity
	inc [mario.speed_y]
	
	; test for collision
	cmp [mario.y], 150
	jle noCollision
	mov [mario.speed_y], 0
	mov [mario.y], 150
noCollision:
	inc ecx
	jmp mainloop
	
	; exit on esc
	call waitForSpecificKeystroke, 1Bh
	call terminateProcess
ENDP main	

DATASEG
	mario character <30,150,1,0>
	openErrorMsg db "could not open file", 13, 10, '$'
	readErrorMsg db "could not read data", 13, 10, '$'
	closeErrorMsg db "error during file closing", 13, 10, '$'

UDATASEG;
	;filehandle dw ?
	;packedframe db FRAMESIZE dup (?)

	
STACK 100h

END main