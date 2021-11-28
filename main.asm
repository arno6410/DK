IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT, ds:FLAT, es:FLAT, fs:FLAT, gs:FLAT

VMEMADR EQU 0A0000h	; video memory address
SCRWIDTH EQU 320	; screen width
SCRHEIGHT EQU 200	; screen height
FRAMESIZE EQU 256	; mario size (16x16)
KEYCNT EQU 89		; number of keys to track

CODESEG

INCLUDE "utils.inc"
INCLUDE "rect.inc"
INCLUDE "keyb.inc"

STRUC character
	x			dd 0		; x position
	y			dd 0		; y position
	speed_x		dd 0		; x speedcomponent
	speed_y		dd 0		; y speedcomponent
	w			dd 0		; width
	h 			dd 0		; height
	in_the_air	dd 0		; is mario currently in the air
ENDS character

STRUC rect
	x	dd 0
	y	dd 0
	w	dd 0
	h	dd 0
ENDS rect

PROC main
	sti
	cld
	
	push ds
	pop es
	
	call setVideoMode, 13h
	call __keyb_installKeyboardHandler
	
	;call fillRect, 30, 160, SCRWIDTH-60, 20, 25h
;	call drawRects ; zie rect.asm
	call fillRect, [mario.x], [mario.y], [mario.w], [mario.h], 33h
	
mainloop:
	
	call drawRects ; zie rect.asm
	
	mov ebx, [offset __keyb_keyboardState + 01h] ;esc
	cmp ebx, 1
	je exit
	
	mov ebx, [offset __keyb_keyboardState + 1Eh] ;Q
	cmp ebx, 1
	jne noLeft
	sub [mario.speed_x], 2
	
noLeft:	
	mov ebx, [offset __keyb_keyboardState + 20h] ;D
	cmp ebx, 1
	jne noRight
	add [mario.speed_x], 2
	
noRight:
	mov ebx, [mario.speed_y]
	or ebx, [mario.in_the_air] ; prevents from jumping again at the top of the arc
	cmp ebx, 0
	jne noUp
	
	mov ebx, [offset __keyb_keyboardState + 11h] ;Z
	cmp ebx, 1
	jne noUp
	mov [mario.speed_y], -6
	mov [mario.in_the_air], 1
	
noUp:
	; draw and update mario
	mov eax, [mario.x]
	mov ebx, [mario.y]
	call fillRect, eax, ebx, [mario.w], [mario.h], 33h
	mov ecx, [mario.speed_x]
	add [mario.x], ecx
	mov edx, [mario.speed_y]
	add [mario.y], edx
	
	call wait_VBLANK, 3
	
	; undraw mario
	call fillRect, eax, ebx, [mario.w], [mario.h], 0h
	push eax
noJump:
	; gravity
	inc [mario.speed_y]
	
	; test for collision

	call testYCollision, [mario.x], [mario.y], [mario.w], [mario.h]
	test eax, eax
	jz noYCollision
	mov [mario.y], ebx ; ebx contains the old value of [mario.y]
	mov [mario.speed_y], 0
	mov [mario.in_the_air], 0
	
noYCollision:
	mov ebx, eax
	call testXCollision,[mario.x], [mario.y], [mario.w], [mario.h]
	and eax, ebx
	test eax, eax
	jz noXCollision
	pop eax ; restore the old value of [mario.x]
	mov [mario.x], eax 
	mov [mario.speed_x], 0
	mov [mario.in_the_air], 0

noXCollision:
	mov [mario.speed_x], 0
	jmp mainloop
	
exit:
	; exit on esc
	call __keyb_uninstallKeyboardHandler
	call terminateProcess
ENDP main	

DATASEG
	mario character <35,140,0,0,10,15>
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