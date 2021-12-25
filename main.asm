IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT, ds:FLAT, es:FLAT, fs:FLAT, gs:FLAT

VMEMADR EQU 0A0000h	; video memory address
SCRWIDTH EQU 320	; screen witdth
SCRHEIGHT EQU 200	; screen height
FRAMESIZE EQU 256	; mario size (16x16)
KEYCNT EQU 89		; number of keys to track
SPEED EQU 4			; mario's speed 

CODESEG

INCLUDE "utils.inc"
INCLUDE "rect.inc"
INCLUDE "keyb.inc"

STRUC character
	x				dd 0	; x position
	y				dd 0	; y position
	speed_x			dd 0	; x speedcomponent
	speed_y			dd 0	; y speedcomponent
	w				dd 0	; width
	h 				dd 0	; height
	color 			dd 0	; color
	in_the_air dd 0	; mario currently in the air? (-1 if yes, 0 if not)
	currentPlatform dd 0	; offset to current platform
ENDS character



STRUC barrel
	x				dd 0		; x position
	y				dd 0		; y position
	speed_x			dd 0		; x speedcomponent
	speed_y			dd 0		; y speedcomponent
	w				dd 0		; width
	h 				dd 0		; height
	color 			dd 0		; color
ENDS barrel
PROC drawPlatforms
	
ENDP drawPlatforms

PROC scrollUp
	ARG @@n: dword
	USES ebx
	mov ebx, [@@n]
	sub [mario.y], ebx
;	sub [ground2.y], ebx
;	sub [ground3.y], ebx
;	sub [ground4.y], ebx
ENDP scrollUp

PROC checkCharCollision
	ARG @@o_char: dword, @@o_pf: dword
	USES eax, ebx, ecx
	
	mov ebx, [@@o_char]
	mov ecx, [@@o_pf]
	
	mov eax, [ebx + character.x]
	cmp eax, [ecx + newPlatform.x1]
	jg @@yep
	add eax, [ebx + character.w]
	cmp eax, [ecx + newPlatform.x0]
	jl @@yep
	jmp @@check
@@yep:
	cmp [ebx + character.currentPlatform], ecx
	jne @@nocol
	mov [ebx + character.in_the_air], -1
	ret
	; check for collision	
@@check:
	call collision_down, [ebx + character.x], [ebx + character.y], [ebx + character.w], [ebx + character.h], \
	 [ecx + newPlatform.x0], [ecx + newPlatform.y0], [ecx + newPlatform.x1], [ecx + newPlatform.y1]
	cmp eax, -1
	je @@in_the_air
	; collision!
	mov [ebx + character.speed_y], 0
	mov [ebx + character.in_the_air], 0
	mov [ebx + character.y], eax
	mov [ebx + character.currentPlatform], ecx
	jmp @@nocol
@@in_the_air:
	; om te checken of mario echt in de lucht is, kijken we of er collision zou zijn als we mario enkele pixels naar beneden zouden verschuiven
	mov eax, [ebx + character.y]
	add eax, 2
	call collision_down, [ebx + character.x], eax, [ebx + character.w], [ebx + character.h], \
	 [ecx + newPlatform.x0], [ecx + newPlatform.y0], [ecx + newPlatform.x1], [ecx + newPlatform.y1]
	cmp eax, -1
;	mov [ebx + character.in_the_air], 0
	jne @@nocol
	mov [ebx + character.in_the_air], -1
@@nocol:
	ret
ENDP checkCharCollision

PROC checkCollision
	ARG @@n: dword
	LOCAL @@ground: dword, @@x0: dword, @@y0: dword, @@w: dword, @@h: dword
	USES eax, ebx
	
	cld
	
	; the platforms are in an array called platforms. the pointer to the nth platform is stored in [@@ground]
	mov eax, [@@n]
	dec eax
	mov ebx, [offset platformList + 4*eax]
	mov [@@ground], ebx
	
	mov ebx, [@@ground]
	mov eax, [ebx+platform.x]
	mov [@@x0], eax
	
	mov eax, [ebx+platform.y]
	mov [@@y0], eax
	
	mov eax, [ebx+platform.w]
	mov [@@w], eax
	
	mov eax, [ebx+platform.h]
	mov [@@h], eax

checkX:
	mov eax, [@@x0]
	mov ebx, [mario.x]
	add ebx, [mario.w]
	cmp eax, ebx			; checks for overlap 
	jge noXOverlap			; with blocks
	
	mov eax, [mario.x]
	mov ebx, [@@x0]
	add ebx, [@@w]
	cmp eax, ebx
	jge noXOverlap
xOverlap:
;	mov [mario.x_overlapping], 1
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
;	mov [mario.y_overlapping], 1
	jmp endProcedure
noYOverlap:
;	mov [mario.y_overlapping], 0
;	mov [mario.x_overlapping], 0
	jmp endProcedure
outOfBounds:
;	mov [mario.x_overlapping], 1
endProcedure:	
	ret
ENDP checkCollision

; if no x_col -> nothing happens
; if x_col -> char.x gets moved so that there's no more overlap
; which side (left or right) of the platform depends on speed_x being positive or negative
; only to be used if pf is not the char's currentPlatform
PROC x_collision
	ARG @@o_char: dword, @@o_pf: dword
;	LOCAL
	USES eax, ebx, ecx
	
	mov ebx, [@@o_char]
	mov ecx, [@@o_pf]
	
	cmp [ebx + character.currentPlatform], ecx
	je @@nocol
	
	mov eax, [ebx + character.x]
	cmp eax, [ecx + newPlatform.x1]
	jg @@nocol
	
	add eax, [ebx + character.w]
	cmp eax, [ecx + newPlatform.x0]
	jle @@nocol
	
	call collision_down, [ebx + character.x], [ebx + character.y], [ebx + character.w], [ebx + character.h], \
		[ecx + newPlatform.x0], [ecx + newPlatform.y0], [ecx + newPlatform.x1], [ecx + newPlatform.y1]
	cmp eax, -1
	je @@nocol
	; if we're here, there's a collision
	; now we need to calculate the right x-coordinate
	cmp [ebx + character.speed_x], 0
	je @@nocol
	jg @@rightwards
	
	; leftwards
	; this means that char came from the rightmost side of pf 
	; so move char back to the rightmost side of pf
	mov eax, [ecx + newPlatform.x1]
	inc eax
	mov [ebx + character.x], eax
	mov [ebx + character.color], 1h
	ret
	
@@rightwards:
	mov eax, [ecx + newPlatform.x0]
	sub eax, [ebx + character.w]
	mov [ebx + character.x], eax
	ret
	
@@nocol:
	ret
ENDP x_collision

PROC main
	sti
	cld
	
	push ds
	pop es
	
	call setVideoMode, 13h
	call __keyb_installKeyboardHandler
	
mainMenu:
	call fillRect,0,0,320,200,0h
	call drawRectangle,100,40,120,40,35h
	call displayString, 7, 16, offset msg1
	call displayString, 17, 18, offset msg2	
	call displayString, 19, 2, offset msgControlsLeft
	call displayString, 20, 2, offset msgControlsRight
	call displayString, 21, 2, offset msgControlsUp
	call displayString, 22, 2, offset msgControlsDown
	call displayString, 23, 2, offset msgControlsEnter
	
	push 1 ; using the stack, 1 is the top button and 2 the bottom one
	
menuloop:
	mov ebx, [offset __keyb_keyboardState + 11h] ;Z
	cmp ebx, 1
	je upmenu
	
	mov ebx, [offset __keyb_keyboardState + 1Fh] ;S
	cmp ebx, 1
	je downmenu
	jmp checkKeypresses
	
upmenu:
	pop ebx
	cmp ebx, 1
	je pushValue
	mov ebx, 1
	call drawRectangle,100,120,120,40,00h
	call drawRectangle,100,40,120,40,35h
	jmp pushValue
	
downmenu:
	pop ebx
	cmp ebx, 2
	je pushValue
	mov ebx, 2
	call drawRectangle,100,40,120,40,00h
	call drawRectangle,100,120,120,40,35h
	
pushValue:
	push ebx
	
checkKeypresses:
	mov ebx, [offset __keyb_keyboardState + 1Ch] ;Enter
	cmp ebx, 1
	jne checkEsc
	
	pop ebx
	cmp ebx, 2
	je exit
	
	jmp newgame ; jump to the main game loop
	
checkEsc:
;	mov ebx, [offset __keyb_keyboardState + 01h] ;esc
; TODO: dit opkuisen
	mov ebx, 0
	cmp ebx, 1
	jne menuloop
	
newgame:
	; (re-)initialise mario
	; mario character <40,60,0,0,16,20,33h,0,0,0>
	mov [mario.x], 40
	mov [mario.y], 60
	mov [mario.speed_x], 0
	mov [mario.speed_y], 0
	mov [mario.w], 16
	mov [mario.h], 20
	mov [mario.in_the_air], -1
	mov [mario.currentPlatform], offset ground1
	
	call fillRect, 0, 0, 320, 200, 0h
	
	; ecx = number of platforms
	mov ecx, 4
drawPlatformLoop:
	mov eax, [platformList + 4*ecx - 4]
	call platform_both, [eax + newPlatform.x0], [eax + newPlatform.y0], [eax + newPlatform.x1], [eax + newPlatform.y1], [eax + newPlatform.h], [eax + newPlatform.color]
	loop drawPlatformLoop
	
mainloop:
	
	mov ebx, [offset __keyb_keyboardState + 01h] ;esc
	cmp ebx, 1
	je mainMenu
	
	mov ebx, [offset __keyb_keyboardState + 1Eh] ;Q
	cmp ebx, 1
	jne noLeft
	; move left
	
	; left screen edge check
	mov ebx, [mario.x]
	cmp ebx, SPEED
	jge skipLeftBoundCheck
	neg ebx
	mov [mario.speed_x], ebx
	jmp noLeft

skipLeftBoundCheck:
	mov [mario.speed_x], -SPEED
	
noLeft:
	mov ebx, [offset __keyb_keyboardState + 20h] ;D
	cmp ebx, 1
	jne noRight
	; move right
	
	; right screen edge check
	mov ebx, [mario.x]
	add ebx, [mario.w]
	sub ebx, SCRWIDTH-SPEED
	jle skipRightBoundCheck
	sub ebx, SPEED
	neg ebx
	mov [mario.speed_x], ebx
	
	jmp noRight

skipRightBoundCheck:
	mov [mario.speed_x], SPEED	
	
noRight:
	cmp [mario.in_the_air], 0
	jne noUp
	
	mov ebx, [offset __keyb_keyboardState + 11h] ;Z
	cmp ebx, 1
	jne noUp	
	mov [mario.speed_y], -8
	mov [mario.in_the_air], -1
	
noUp:
	; check dat y niet > SCRHEIGHT -> anders dood
	mov eax, [mario.y]
	cmp eax, SCRHEIGHT
	jg dead
	; draw and update mario
	mov eax, [mario.x]
	mov ebx, [mario.y]
	
	mov ecx, [mario.speed_x]
	add [mario.x], ecx
	mov edx, [mario.speed_y]
	add [mario.y], edx
	
; TODO: clean this; this makes the color depend on whether mario is in the air
	cmp [mario.in_the_air], -1
	jne skippp
	call fillRect, eax, ebx, [mario.w], [mario.h], 2h
	jmp nxt
skippp:
	call fillRect, eax, ebx, [mario.w], [mario.h], [mario.color]
nxt:
	
	call wait_VBLANK, 3
	
	; undraw mario
	call fillRect, eax, ebx, [mario.w], [mario.h], 0h	
	
	
noJump:
	; gravity
	inc [mario.speed_y]
	
; check for collision
	; if mario is in the air, currentPlatform can change
	mov ecx, 4
	cmp [mario.in_the_air], -1
	je checkAllGrounds
	
	call checkCharCollision, offset mario, [mario.currentPlatform]
;	call x_collision, offset mario, offset ground1
;	call x_collision, offset mario, offset testground
	
checkX_collisionLoop:
	call x_collision, offset mario, [platformList + 4*ecx - 4]
	loop checkX_collisionLoop
	
	jmp rest
	
checkAllGrounds:
	call checkCharCollision, offset mario, [platformList + 4*ecx - 4]
	loop checkAllGrounds
	
rest:
	; reset mario's speed_x
	mov [mario.speed_x], 0
	jmp mainloop
	
dead:
	call fillRect, 0, 0, 320, 200, 0h
	call displayString, 7, 2, offset dead_message
	call wait_VBLANK, 60
	jmp mainMenu
	
exit:
	call __keyb_uninstallKeyboardHandler
	call terminateProcess
	ret
ENDP main	

DATASEG
	mario character <40,60,0,0,16,20,33h,1>
	testground newPlatform <150,162,190,167,10,25h>
	ground1 newPlatform <15,180,295,185,10,25h>
	ground2 newPlatform <240,160,280,162,5,25h>
	ground3 newPlatform <180,140,220,142,5,25h>
	ground4 newPlatform <120,115,150,118,5,25h>
	platformList dd ground1,ground2,ground3,ground4

	openErrorMsg db "could not open file", 13, 10, '$'
	readErrorMsg db "could not read data", 13, 10, '$'
	closeErrorMsg db "error during file closing", 13, 10, '$'
	
	dead_message db "ded.",13,10,'$'

	msg1 	db "New Game", 13, 10, '$'
	msg2 	db "Exit", 13, 10, '$'
	msgControlsLeft		db "Q: LEFT", 13, 10, '$'
	msgControlsRight	db "D: RIGHT", 13, 10, '$'
	msgControlsUp		db "Z: UP/JUMP", 13, 10, '$'
	msgControlsDown		db "S: DOWN", 13, 10, '$'
	msgControlsEnter	db "ENTER: SELECT", 13, 10, '$'
	
;	keybscancodes 	db 29h, 02h, 03h, 04h, 05h, 06h, 07h, 08h, 09h, 0Ah, 0Bh, 0Ch, 0Dh, 0Eh, 	52h, 47h, 49h, 	45h, 35h, 00h, 4Ah
;					db 0Fh, 10h, 11h, 12h, 13h, 14h, 15h, 16h, 17h, 18h, 19h, 1Ah, 1Bh, 		53h, 4Fh, 51h, 	47h, 48h, 49h, 		1Ch, 4Eh
;					db 3Ah, 1Eh, 1Fh, 20h, 21h, 22h, 23h, 24h, 25h, 26h, 27h, 28h, 2Bh,    						4Bh, 4Ch, 4Dh
;					db 2Ah, 00h, 2Ch, 2Dh, 2Eh, 2Fh, 30h, 31h, 32h, 33h, 34h, 35h, 36h,  			 48h, 		4Fh, 50h, 51h,  1Ch
;					db 1Dh, 0h, 38h,  				39h,  				0h, 0h, 0h, 1Dh,  		4Bh, 50h, 4Dh,  52h, 53h

UDATASEG;
	;filehandle dw ?
	;packedframe db FRAMESIZE dup (?)

	
STACK 100h

END main
