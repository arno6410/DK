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
	y_overlapping 	dd 0		; 1 if mario is overlapping with a block in y coordinate, 0 otherwise
ENDS character

STRUC rect
	x	dd 0
	y	dd 0
	w	dd 0
	h	dd 0
ENDS rect

STRUC platform
	x 				dd 0		; x position
	y				dd 0		; y position
	w				dd 0		; width
	h				dd 0		; height
	color			dd 0		; color
ENDS platform

STRUC newPlatform
	x0		dd 0
	y0		dd 0
	x1		dd 0
	y1		dd 0
	d_x		dd 0 ; d_x & d_y should both be positive
	d_y		dd 0
	h		dd 0
	color	dd 0
ENDS newPlatform

PROC checkCollision_new
	ARG @@x0: dword, @@y0: dword, @@x1: dword, @@y1: dword, @@h: dword RETURNS eax
	USES ebx
	
; x collision is hetz als vroeger
@@checkX:
	mov ebx, [mario.x]
	cmp ebx, 0					; checks for the left 
	jl @@outOfBounds				; edge of the screen
	
	add ebx, [mario.w]
	cmp ebx, 320				; checks for the right 
	jg @@outOfBounds				; edge of the screen
	
	mov eax, [@@x0]
	cmp eax, ebx			; checks for overlap 
	jge @@noXOverlap			; with blocks
	
	mov eax, [mario.x]
	mov ebx, [@@x1]
	cmp eax, ebx
	jge @@noXOverlap
@@xOverlap:
	mov [mario.x_overlapping], 1
	jmp @@checkY
@@noXOverlap:
	mov eax, 0
	ret
	
@@checkY:
	; check dat y+h niet > SCRWIDTH
	mov eax, [mario.y]
	add eax, [mario.h]
	cmp eax, SCRWIDTH
	jg ded

	call collision_down, [mario.x], [mario.y], [mario.w], [mario.h], \
		[@@x0], [@@y0], [@@x1], [@@y1]
	cmp eax, 0
	je @@noYOverlap

; nog te implementeren -> collision_up	
;	mov eax, [mario.y]
;	mov ebx, [@@y0]
;	add ebx, [@@h]
;	cmp eax, ebx
;	jge noYOverlap
@@yOverlap:	
	mov [mario.y_overlapping], 1
	ret
@@noYOverlap:
	mov [mario.y_overlapping], 0
	mov [mario.x_overlapping], 0
	mov eax, 0
	ret
@@outOfBounds:
	mov [mario.x_overlapping], 1
	
	ret	
ENDP checkCollision_new

PROC checkMarioCollision
	ARG @@ground: newPlatform
	USES eax, ebx
	
	; check for collision	
@@check:
;	call checkCollision, [ground1.x], [ground1.y], [ground1.w], [ground1.h]
	call checkCollision_new, [@@ground.x0], [@@ground.y0], [@@ground.x1], [@@ground.y1], [@@ground.h]
	cmp [mario.y_overlapping], 1
	jne @@nocol
	mov ebx, 0
	cmp [mario.speed_y], ebx
	jge @@bottom
@@top:
	mov [mario.speed_y], 0
	mov [mario.in_the_air], 0
	mov [mario.y_overlapping], 0
	mov ebx, [ground1.y0]
	sub ebx, [mario.h]
;	mov [mario.y], ebx
	jmp @@nocol
@@bottom:
; TODO: in de proc collision_down al meteen implementeren dat als eax != 0, eax de y-waarde bevat die de linker/rechterbenedenhoek zou moeten hebben om mooi overeen te komen -> die waarde gebruiken om de juiste pos van mario terug te vinden
	mov [mario.y_overlapping], 0
	mov [mario.y], eax 
	mov [mario.speed_y], 0
	mov [mario.in_the_air], 0
@@nocol:


	ret
ENDP checkMarioCollision

PROC checkCollision
	ARG @@x0: dword, @@y0: dword, @@w: dword, @@h: dword
	USES eax, ebx

checkX:
	mov eax, [@@x0]
	mov ebx, [mario.x]
	cmp ebx, 0					; checks for the left 
	jl outOfBounds				; edge of the screen
	
	add ebx, [mario.w]
	cmp ebx, 320				; checks for the right 
	jg outOfBounds				; edge of the screen
	
	cmp eax, ebx			; checks for overlap 
	jge noXOverlap			; with blocks
	
	mov eax, [mario.x]
	mov ebx, [@@x0]
	add ebx, [@@w]
	cmp eax, ebx
	jge noXOverlap
xOverlap:
	mov [mario.x_overlapping], 1
	jmp checkY
noXOverlap:
	jmp endProcedure
checkY:
	mov eax, [@@y0]
	mov ebx, [mario.y]
	add ebx, [mario.h]
	cmp eax, ebx
	jge noYOverlap
	
	mov eax, [mario.y]
	mov ebx, [@@y0]
	add ebx, [@@h]
	cmp eax, ebx
	jge noYOverlap
yOverlap:	
	mov [mario.y_overlapping], 1
	jmp endProcedure
noYOverlap:
	mov [mario.y_overlapping], 0
	mov [mario.x_overlapping], 0
	jmp endProcedure
outOfBounds:
	mov [mario.x_overlapping], 1
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

	call platformDown, [ground1.x0], [ground1.y0], [ground1.d_x], [ground1.d_y], [ground1.h], [ground1.color]
	call fillRect, [ground2.x], [ground2.y], [ground2.w], [ground2.h], [ground2.color]
	call fillRect, [ground3.x], [ground3.y], [ground3.w], [ground3.h], [ground3.color]
	call fillRect, [ground4.x], [ground4.y], [ground4.w], [ground4.h], [ground4.color]
	call fillRect, [mario.x], [mario.y], [mario.w], [mario.h], [mario.color]
	
mainloop:
	
	
	mov ebx, [offset __keyb_keyboardState + 01h] ;esc
	cmp ebx, 1
	je exit
	
	mov ebx, [offset __keyb_keyboardState + 1Eh] ;Q
	cmp ebx, 1
	jne noLeft
	; move left
;	call checkCollision, [ground1.x], [ground1.y], [ground1.w], [ground1.h]
	call checkCollision_new, [ground1.x0], [ground1.y0], [ground1.x1], [ground1.y1], [ground1.h]
	call checkCollision, [ground2.x], [ground2.y], [ground2.w], [ground2.h]
	call checkCollision, [ground3.x], [ground3.y], [ground3.w], [ground3.h]
	call checkCollision, [ground4.x], [ground4.y], [ground4.w], [ground4.h]
	mov [mario.y_overlapping], 0
	cmp [mario.x_overlapping], 1
	je noLeft
	mov [mario.x_overlapping], 0
	sub [mario.x], 4
	
noLeft:	
	mov [mario.x_overlapping], 0
	mov ebx, [offset __keyb_keyboardState + 20h] ;D
	cmp ebx, 1
	jne noRight
	add [mario.x], 4
;	call checkCollision, [ground1.x], [ground1.y], [ground1.w], [ground1.h]
	call checkCollision_new, [ground1.x0], [ground1.y0], [ground1.x1], [ground1.y1], [ground1.h]
	call checkCollision, [ground2.x], [ground2.y], [ground2.w], [ground2.h]
	call checkCollision, [ground3.x], [ground3.y], [ground3.w], [ground3.h]
	call checkCollision, [ground4.x], [ground4.y], [ground4.w], [ground4.h]
	mov [mario.y_overlapping], 0       
	sub [mario.x], 4
	cmp [mario.x_overlapping], 1
	je noRight
	mov [mario.x_overlapping], 0
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
	
	; eig zouden deze calls niet nodig moeten zijn, want met de collision enz kan mario niet meer "door" de platformen gaan
;	call fillRect, [ground1.x], [ground1.y], [ground1.w], [ground1.h], [ground1.color]
	call fillRect, [ground2.x], [ground2.y], [ground2.w], [ground2.h], [ground2.color]
	call fillRect, [ground3.x], [ground3.y], [ground3.w], [ground3.h], [ground3.color]
	call fillRect, [ground4.x], [ground4.y], [ground4.w], [ground4.h], [ground4.color]
	
	pop ecx
noJump:
	; gravity
	inc [mario.speed_y]
	
; check for collision	
call checkMarioCollision, [ground1.x0], [ground1.y0], [ground1.x1], [ground1.y1], [ground1.d_x], [ground1.d_y], [ground1.h], [groun1.color]
	
	
check2:
	call checkCollision, [ground2.x], [ground2.y], [ground2.w], [ground2.h]
	cmp [mario.y_overlapping], 1
	jne check3
	mov ebx, 0
	cmp [mario.speed_y], ebx
	jle bottom2
top2:  ; if collision is with top of platform 2
	mov [mario.speed_y], 0
	mov [mario.in_the_air], 0
	mov [mario.y_overlapping], 0
	mov ebx, [ground2.y]
	sub ebx, [mario.h]
	mov [mario.y], ebx
	jmp check3
bottom2:
	mov [mario.y_overlapping], 0
	mov ebx, [ground2.y]
	add ebx, [ground2.h]
	mov [mario.y], ebx
	mov [mario.speed_y], 1
	
check3:
	call checkCollision, [ground3.x], [ground3.y], [ground3.w], [ground3.h]
	cmp [mario.y_overlapping], 1
	jne check4
	mov ebx, 0
	cmp [mario.speed_y], ebx
	jle bottom3
top3:
	mov [mario.speed_y], 0
	mov [mario.in_the_air], 0
	mov [mario.y_overlapping], 0
	mov ebx, [ground3.y]
	sub ebx, [mario.h]
	mov [mario.y], ebx
	jmp check4
bottom3:
	mov [mario.y_overlapping], 0
	mov ebx, [ground3.y]
	add ebx, [ground3.h]
	mov [mario.y], ebx
	mov [mario.speed_y], 1
	
check4:
	call checkCollision, [ground4.x], [ground4.y], [ground4.w], [ground4.h]
	cmp [mario.y_overlapping], 1
	jne noCollision
	mov ebx, 0
	cmp [mario.speed_y], ebx
	jle bottom4
top4:
	mov [mario.speed_y], 0
	mov [mario.in_the_air], 0
	mov [mario.y_overlapping], 0
	mov ebx, [ground4.y]
	sub ebx, [mario.h]
	mov [mario.y], ebx
	jmp noCollision
bottom4:
	mov [mario.y_overlapping], 0
	mov ebx, [ground4.y]
	add ebx, [ground4	.h]
	mov [mario.y], ebx
	mov [mario.speed_y], 1
	
noCollision:
	mov [mario.y_overlapping], 0
	inc ecx
	jmp mainloop
	
exit:
ded:
	; exit on esc
	call __keyb_uninstallKeyboardHandler
	call terminateProcess
	ret
ENDP main	

DATASEG
	mario character <40,60,0,0,16,20,33h,0,0,0>
;	ground1 platform <0,190,320,10,25h>
	ground1 newPlatform <25, 180, 295, 185, 270, 5, 10, 25h>
	ground2 platform <240,160,40,5,25h>
	ground3 platform <180,140,40,5,25h>
	ground4 platform <120,115,40,5,25h>
	
	;terrain	dd ground1, ground2					; array that 
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