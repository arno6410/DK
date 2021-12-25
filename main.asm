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
JUMP EQU 5			; initial vertical speed in a jump; total jump height is JUMP*(JUMP-1)/2
NUMOFPF EQU 3		; number of platforms
NUMOFL EQU 4		; number of ladders

CODESEG

INCLUDE "utils.inc"
INCLUDE "rect.inc"
INCLUDE "keyb.inc"

STRUC character
	x				dd 0	; x position
	y				dd 0	; y position
	speed_x			dd 0	; x speedcomponent
	speed_y			dd 0	; y speedcomponent
	w				dd 16	; width
	h 				dd 20	; height
	color 			dd 33h	; color
	in_the_air 		dd 0	; mario currently in the air? (-1 if yes, 0 if not)
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
	USES eax, ebx, ecx
	
	mov ecx, NUMOFL
@@drawLadderLoop:
	mov eax, [ladderList + 4*ecx-4]
	mov ebx, [eax + newPlatform.x1]
	sub ebx, [eax + newPlatform.x0]
	call fillRect, [eax + newPlatform.x0], [eax + newPlatform.y0], ebx, [eax + newPlatform.h], [eax + newPlatform.color]
	loop @@drawLadderLoop
	
	mov ecx, NUMOFPF
@@drawPlatformLoop:
	mov eax, [platformList + 4*ecx - 4]
	call platform_both, [eax + newPlatform.x0], [eax + newPlatform.y0], [eax + newPlatform.x1], [eax + newPlatform.y1], [eax + newPlatform.h], [eax + newPlatform.color]
	loop @@drawPlatformLoop
	
	ret
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
	
	; check if the char is under the platform
	mov eax, [ecx + newPlatform.y0]
	add eax, [ecx + newPlatform.h]
	cmp eax, [ebx + character.y]
	jl @@nocol
	
	mov eax, [ebx + character.x]
	cmp eax, [ecx + newPlatform.x1]
	jg @@noXoverlap
	add eax, [ebx + character.w]
	cmp eax, [ecx + newPlatform.x0]
	jge @@check
	
@@noXoverlap:
	mov [ebx + character.in_the_air], -1
	cmp [ebx + character.currentPlatform], ecx
	je SHORT @@nocol
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
	ret
	
@@in_the_air:
	; om te checken of mario echt in de lucht is, kijken we of er collision zou zijn als we mario enkele pixels naar beneden zouden verschuiven
	mov [ebx + character.in_the_air], 0
	mov eax, [ebx + character.y]
	add eax, 2
	call collision_down, [ebx + character.x], eax, [ebx + character.w], [ebx + character.h], \
	 [ecx + newPlatform.x0], [ecx + newPlatform.y0], [ecx + newPlatform.x1], [ecx + newPlatform.y1]
	cmp eax, -1
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
	USES eax, ebx, ecx
	
	mov ebx, [@@o_char]
	mov ecx, [@@o_pf]
	
	cmp [ebx + character.currentPlatform], ecx
	je @@nocol
	
	; check if the char is under the platform
	mov eax, [ecx + newPlatform.y0]
	add eax, [ecx + newPlatform.h]
	cmp eax, [ebx + character.y]
	jl @@nocol

	mov eax, [ebx + character.x]
	cmp eax, [ecx + newPlatform.x1]
	jg @@nocol
	
	add eax, [ebx + character.w]
	cmp eax, [ecx + newPlatform.x0]
	jl @@nocol
	
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
	mov [mario.x], 30
	mov [mario.y], 160
	mov [mario.speed_x], 0
	mov [mario.speed_y], 0
	mov [mario.in_the_air], -1
	mov [mario.currentPlatform], 0
	
	mov [barrel1.x], 250
	mov [barrel1.y], 20
	mov [barrel1.speed_x], 0
	mov [barrel1.speed_y], 0
	mov [barrel1.h], 16
	mov [barrel1.in_the_air], -1
	mov [barrel1.currentPlatform], 0
	
	call fillRect, 0, 0, 320, 200, 0h
	
	call drawPlatforms
	
	call drawSprite, offset barrelsprite, [barrel1.x], [barrel1.y], [barrel1.w], [barrel1.h]
	
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
	mov [mario.speed_y], -JUMP
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
	
	mov ecx, [barrel1.speed_x]
	add [barrel1.x], ecx
	; mov ecx, [barrel1.speed_y]
	; add [barrel1.y], ecx
	
	cmp [mario.speed_x], 0
	jl drawLeft
	call drawSprite, offset mariospriteright, eax, ebx, [mario.w], [mario.h]
	jmp skipLeft
	
drawLeft:
	call drawSprite, offset mariospriteleft, eax, ebx, [mario.w], [mario.h]
	
skipLeft:
	call drawSprite, offset barrelsprite, [barrel1.x], [barrel1.y], [barrel1.w], [barrel1.h]
	
	call drawPlatforms
	
	call wait_VBLANK, 3
	; undraw mario
	call fillRect, eax, ebx, [mario.w], [mario.h], 0h	
	call fillRect, [barrel1.x], [barrel1.y], [barrel1.w], [barrel1.h], 0h	
	
	
noJump:
	; gravity
	inc [mario.speed_y]
	inc [barrel1.speed_y]
	
; check for collision
	; if mario is in the air, currentPlatform can change
	; by increasing ecx, we make sure the ladders are also included
	mov ecx, NUMOFPF + NUMOFL
	cmp [mario.in_the_air], -1
	je checkAllGrounds
	
	call checkCharCollision, offset mario, [mario.currentPlatform]
checkX_collisionLoop:
	call x_collision, offset mario, [platformList + 4*ecx-4]
	loop checkX_collisionLoop
	jmp rest
	
checkAllGrounds:
	mov [mario.currentPlatform], 0
	call checkCharCollision, offset mario, [platformList + 4*ecx-4]
	mov eax, [mario.currentPlatform]
	cmp eax, [platformList + 4*ecx - 4]
	je rest
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
	mario character <>
	barrel1 character <>
	ground1 newPlatform <25,180,295,170,10,25h>
	ground2 newPlatform <25,110,270,120,10,25h>
	ground3 newPlatform <50,60,295,50,10,25h>
;	ground4 newPlatform <40,60,295,50,10,25h>
; BELANGRIJK: uplist moet juist na platformlist komen
	platformList dd ground1,ground2,ground3
	ladderList dd ladder1,ladder2,ladder3,ladder4
	ladder1 newPlatform <250,130,260,130,20,65h>
	ladder2 newPlatform <70,70,80,70,20,65h>
	ladder3 newPlatform <100,130,110,130,20,65h>
	ladder4 newPlatform <150,70,160,70,20,65h>
	
	mariospriteright db 00h, 00h, 00h, 00h, 00h, 48h, 48h, 48h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
				db 00h, 00h, 00h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 00h, 00h, 00h, 00h, 00h 
				db 00h, 00h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h 
				db 00h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h 
				db 00h, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 00h, 00h, 00h, 00h 
				db 00h, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 00h, 00h, 00h 
				db 00h, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 00h, 00h
				db 00h, 00h, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 00h, 00h 
				db 00h, 00h, 00h, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 00h, 00h, 00h
				db 00h, 00h, 00h, 00h, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 00h, 00h, 00h, 00h, 00h
				db 00h, 00h, 00h, 00h, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 00h, 00h, 00h, 00h, 00h, 00h
				db 00h, 00h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 00h, 00h, 00h
				db 00h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 00h, 00h
				db 5Ah, 5Ah, 5Ah, 5Ah, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 5Ah, 5Ah, 5Ah, 00h
				db 5Ah, 5Ah, 5Ah, 5Ah, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah
				db 5Ah, 5Ah, 5Ah, 5Ah, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah
				db 5Ah, 5Ah, 5Ah, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 5Ah, 5Ah, 5Ah, 00h
				db 00h, 00h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 00h, 00h, 00h
				db 00h, 00h, 48h, 48h, 48h, 48h, 00h, 00h, 00h, 48h, 48h, 48h, 48h, 48h, 00h, 00h
				db 00h, 00h, 48h, 48h, 48h, 48h, 48h, 00h, 00h, 48h, 48h, 48h, 48h, 48h, 00h, 00h
	
	mariospriteleft db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 48h, 48h, 48h, 00h, 00h, 00h, 00h, 00h
				db 00h, 00h, 00h, 00h, 00h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 00h, 00h, 00h 
				db 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 00h, 00h 
				db 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 00h 
				db 00h, 00h, 00h, 00h, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 00h 
				db 00h, 00h, 00h, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 00h 
				db 00h, 00h, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 00h
				db 00h, 00h, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 00h, 00h 
				db 00h, 00h, 00h, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 00h, 00h, 00h
				db 00h, 00h, 00h, 00h, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 00h, 00h, 00h, 00h, 00h
				db 00h, 00h, 00h, 00h, 00h, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 00h, 00h, 00h, 00h, 00h
				db 00h, 00h, 00h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 00h, 00h
				db 00h, 00h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 00h
				db 00h, 5Ah, 5Ah, 5Ah, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 5Ah, 5Ah, 5Ah, 5Ah
				db 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 5Ah, 5Ah, 5Ah, 5Ah
				db 5Ah, 5Ah, 5Ah, 5Ah, 5Ah, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 5Ah, 5Ah, 5Ah, 5Ah
				db 00h, 5Ah, 5Ah, 5Ah, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 5Ah, 5Ah, 5Ah
				db 00h, 00h, 00h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 48h, 00h, 00h
				db 00h, 00h, 48h, 48h, 48h, 48h, 48h, 00h, 00h, 00h, 48h, 48h, 48h, 48h, 00h, 00h
				db 00h, 00h, 48h, 48h, 48h, 48h, 48h, 00h, 00h, 48h, 48h, 48h, 48h, 48h, 00h, 00h
				
	barrelsprite 	db 00h, 00h, 00h, 00h, 00h, 40h, 40h, 40h, 40h, 40h, 40h, 00h, 00h, 00h, 00h, 00h
					db 00h, 00h, 00h, 40h, 40h, 40h, 42h, 42h, 42h, 42h, 40h, 40h, 40h, 00h, 00h, 00h 
					db 00h, 00h, 40h, 40h, 42h, 42h, 42h, 42h, 42h, 42h, 42h, 42h, 40h, 40h, 00h, 00h 
					db 00h, 40h, 40h, 42h, 42h, 42h, 40h, 40h, 40h, 40h, 42h, 42h, 42h, 40h, 40h, 00h 
					db 00h, 40h, 42h, 42h, 40h, 40h, 40h, 42h, 42h, 40h, 40h, 40h, 42h, 42h, 40h, 00h 
					db 40h, 40h, 42h, 42h, 40h, 42h, 42h, 42h, 42h, 42h, 42h, 40h, 42h, 42h, 40h, 40h 
					db 40h, 42h, 42h, 40h, 40h, 42h, 42h, 40h, 40h, 42h, 42h, 40h, 40h, 42h, 42h, 40h
					db 40h, 42h, 42h, 40h, 42h, 42h, 40h, 40h, 40h, 40h, 42h, 42h, 40h, 42h, 42h, 40h 
					db 40h, 42h, 42h, 40h, 42h, 42h, 40h, 40h, 40h, 40h, 42h, 42h, 40h, 42h, 42h, 40h
					db 40h, 42h, 42h, 40h, 40h, 42h, 42h, 40h, 40h, 42h, 42h, 40h, 40h, 42h, 42h, 40h		
					db 40h, 40h, 42h, 42h, 40h, 42h, 42h, 42h, 42h, 42h, 42h, 40h, 42h, 42h, 40h, 40h
					db 00h, 40h, 42h, 42h, 40h, 40h, 40h, 42h, 42h, 40h, 40h, 40h, 42h, 42h, 40h, 00h
					db 00h, 40h, 40h, 42h, 42h, 42h, 40h, 40h, 40h, 40h, 42h, 42h, 42h, 40h, 40h, 00h
					db 00h, 00h, 40h, 40h, 42h, 42h, 42h, 42h, 42h, 42h, 42h, 42h, 40h, 40h, 00h, 00h
					db 00h, 00h, 00h, 40h, 40h, 40h, 42h, 42h, 42h, 42h, 40h, 40h, 40h, 00h, 00h, 00h 
					db 00h, 00h, 00h, 00h, 00h, 40h, 40h, 40h, 40h, 40h, 40h, 00h, 00h, 00h, 00h, 00h

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

UDATASEG;
	;filehandle dw ?
	;packedframe db FRAMESIZE dup (?)

	
STACK 100h

END main
