IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT, ds:FLAT, es:FLAT, fs:FLAT, gs:FLAT

VMEMADR EQU 0A0000h	; video memory address
SCRWIDTH EQU 320	; screen witdth
SCRHEIGHT EQU 200	; screen height
FRAMESIZE EQU 256	; mario size (16x16)
KEYCNT EQU 89		; number of keys to track

CODESEG

INCLUDE "utils.inc"
INCLUDE "rect.inc"
INCLUDE "keyb.inc"

STRUC character
	x				dd 0		; x position
	y				dd 0		; y position
	speed_x			dd 0		; x speedcomponent
	speed_y			dd 0		; y speedcomponent
	w				dd 0		; width
	h 				dd 0		; height
	color 			dd 0		; color
	in_the_air		dd 0		; is mario currently in the air
	x_overlapping 	dd 0 		; 1 if mario is overlapping with a block in x coordinate, 0 otherwise
ENDS character

STRUC platform
	x 				dd 0		; x position
	y				dd 0		; y position
	w				dd 0		; width
	h				dd 0		; height
	color			dd 0		; color
ENDS platform


PROC checkCollision
	mov eax, [ground2.x]
	mov ebx, [mario.x]
	cmp ebx, 0				; checks for the left 
	jl xOverlap				; edge of the screen
	add ebx, [mario.w]
	cmp ebx, 320				; checks for the right 
	jg xOverlap					; edge of the screen
	cmp eax, ebx			; checks for overlap 
	jge noOverlap			; with blocks
	
	mov eax, [mario.x]
	mov ebx, [ground2.x]
	add ebx, [ground2.w]
	cmp eax, ebx
	jge noOverlap
	
xOverlap:
	mov [mario.x_overlapping], 1
	jmp endProcedure
yOverlap:
	
noOverlap:
endProcedure:
	ret
ENDP checkCollision


PROC main
	sti
	cld
	
	push ds
	pop es
	
	call setVideoMode, 13h
	call __keyb_installKeyboardHandler
	
	call fillRect, [ground.x], [ground.y], [ground.w], [ground.h], [ground.color]
	call fillRect, [ground2.x], [ground2.y], [ground2.w], [ground2.h], [ground2.color]
	call fillRect, [mario.x], [mario.y], [mario.w], [mario.h], [mario.color]
	
	; ecx acts as the loop counter
	mov ecx, 0
mainloop:
	push ecx
	
	push ebx
	push eax
	call checkCollision
	pop eax
	pop ebx
	
	mov ebx, [offset __keyb_keyboardState + 01h] ;esc
	cmp ebx, 1
	je exit
	
	mov ebx, [offset __keyb_keyboardState + 1Eh] ;Q
	cmp ebx, 1
	jne noLeft
	
	sub [mario.x], 4
	call checkCollision
	add [mario.x], 4
	cmp [mario.x_overlapping], 1
	mov [mario.x_overlapping], 0
	je noLeft
	sub [mario.x], 4
	
noLeft:	
	mov ebx, [offset __keyb_keyboardState + 20h] ;D
	cmp ebx, 1
	jne noRight
	
	add [mario.x], 4
	call checkCollision
	sub [mario.x], 4
	cmp [mario.x_overlapping], 1
	mov [mario.x_overlapping], 0
	je noRight
	add [mario.x], 4	
	
noRight:
	mov ebx, [mario.speed_y]
	or ebx, [mario.in_the_air] ; prevents from jumping again at the top of the arc
	cmp ebx, 0
	jne noUp
	
	mov ebx, [offset __keyb_keyboardState + 11h] ;Z
	cmp ebx, 1
	jne noUp
	mov [mario.speed_y], -8
	mov [mario.in_the_air], 1
	
noUp:
	; draw and update mario
	mov eax, [mario.x]
	mov ebx, [mario.y]
	call fillRect, eax, ebx, [mario.w], [mario.h], [mario.color]
	mov ecx, [mario.speed_x]
	add [mario.x], ecx
	mov edx, [mario.speed_y]
	add [mario.y], edx
	
	call wait_VBLANK, 3
	
	; undraw mario
	call fillRect, eax, ebx, [mario.w], [mario.h], 0h
	call fillRect, [ground.x], [ground.y], [ground.w], [ground.h], [ground.color]
	call fillRect, [ground2.x], [ground2.y], [ground2.w], [ground2.h], [ground2.color]
	
	pop ecx
noJump:
	; gravity
	inc [mario.speed_y]
	
	; test for collision
	cmp [mario.y], 160
	jle noCollision
	mov [mario.speed_y], 0
	mov [mario.in_the_air], 0
	mov [mario.y], 160
	
noCollision:
	inc ecx
	jmp mainloop
	
exit:
	; exit on esc
	call __keyb_uninstallKeyboardHandler
	call terminateProcess
ENDP main	

DATASEG
	mario character <180,160,0,0,16,20,33h,0,0>
	ground platform <0,180,320,20,25h>
	ground2 platform <40,100,40,80,25h>
	;terrain	dd ground, ground2					; array that 
	openErrorMsg db "could not open file", 13, 10, '$'
	readErrorMsg db "could not read data", 13, 10, '$'
	closeErrorMsg db "error during file closing", 13, 10, '$'
	
	keybscancodes 	db 29h, 02h, 03h, 04h, 05h, 06h, 07h, 08h, 09h, 0Ah, 0Bh, 0Ch, 0Dh, 0Eh, 	52h, 47h, 49h, 	45h, 35h, 00h, 4Ah
					db 0Fh, 10h, 11h, 12h, 13h, 14h, 15h, 16h, 17h, 18h, 19h, 1Ah, 1Bh, 		53h, 4Fh, 51h, 	47h, 48h, 49h, 		1Ch, 4Eh
					db 3Ah, 1Eh, 1Fh, 20h, 21h, 22h, 23h, 24h, 25h, 26h, 27h, 28h, 2Bh,    						4Bh, 4Ch, 4Dh
					db 2Ah, 00h, 2Ch, 2Dh, 2Eh, 2Fh, 30h, 31h, 32h, 33h, 34h, 35h, 36h,  			 48h, 		4Fh, 50h, 51h,  1Ch
					db 1Dh, 0h, 38h,  				39h,  				0h, 0h, 0h, 1Dh,  		4Bh, 50h, 4Dh,  52h, 53h

UDATASEG;
	;filehandle dw ?
	;packedframe db FRAMESIZE dup (?)

	
STACK 100h

END main