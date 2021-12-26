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
JUMP EQU 6			; initial vertical speed in a jump; total jump height is JUMP*(JUMP-1)/2
B_SPEED EQU 4		; barrel speed_x
B_TIMER EQU 64*6	; how long before all barrels are added

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
	in_the_air 		dd -1	; mario currently in the air? (-1 if yes, 0 if not)
	currentPlatform dd 0	; offset to current platform
	currentScreen 	dd 1	; current screen mario is on, default is the first 
	dead			dd 0	; 0 if not dead, 1 if dead
ENDS character

STRUC screen
	platforms 		dd platformList1		; array with platforms
	ladders			dd ladderList1		; array with ladders
ENDS screen

; macro that calculates the offset to the current screen in screenList
MACRO screen_pointer_offset
	mov edx, [mario.currentScreen]
	dec edx
	mov eax, 24  			; 4 * 6 because there are 6 parameters per screen in screenList
	mul edx
	mov edx, eax
ENDM screen_pointer_offset

PROC drawPlatforms
	LOCAL @@platforms: dword, @@ladders: dword
	USES eax, ebx, ecx, edx
	
	screen_pointer_offset
	
	mov eax, [screenList + edx + 12]
	mov [@@platforms], eax
	mov eax, [screenList + edx + 16]
	mov [@@ladders], eax
	
	mov ecx, [screenList + edx + 4]
@@drawLadderLoop:
	mov edx, [@@ladders]
	mov eax, [edx + 4*ecx-4]
	mov ebx, [eax + newPlatform.x1]
	sub ebx, [eax + newPlatform.x0]
	;call fillRect, [eax + newPlatform.x0], [eax + newPlatform.y0], ebx, [eax + newPlatform.h], [eax + newPlatform.color]
	call drawSprite, offset laddersprite, [eax + newPlatform.x0], [eax + newPlatform.y0], 10, 50
	loop @@drawLadderLoop
	
	mov edx, [mario.currentScreen]
	dec edx
	mov eax, 8
	mul edx
	mov edx, eax
	mov ecx, [screenList + edx]
@@drawPlatformLoop:
	mov edx, [@@platforms]
	mov eax, [edx + 4*ecx - 4]
	call platform_both, [eax + newPlatform.x0], [eax + newPlatform.y0], [eax + newPlatform.x1], [eax + newPlatform.y1], [eax + newPlatform.h], [eax + newPlatform.color]
	loop @@drawPlatformLoop
	
	ret
ENDP drawPlatforms

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

PROC checkBarrelHit
	ARG @@o_barrel: dword
	USES eax, ebx, ecx
	
	mov eax, [@@o_barrel]
	mov ebx, [mario.x]
	add ebx, [mario.w]
	mov ecx, [eax + character.x]
	cmp ebx, ecx
	jl @@noHit
	mov ebx, [eax + character.x]
	add ebx, [eax + character.w]
	mov ecx, [mario.x]
	cmp ebx, ecx
	jl @@noHit
	
@@checkY:
	mov ebx, [mario.y]
	add ebx, [mario.h]
	mov ecx, [eax + character.y]
	cmp ebx, ecx
	jl @@noHit
	mov ebx, [eax + character.y]
	add ebx, [eax + character.h]
	mov ecx, [mario.y]
	cmp ebx, ecx
	jl @@noHit
	
@@overlap:
	mov [mario.dead], 1
	jmp @@endProcedure
	
@@noHit:
	mov [mario.dead], 0
	
@@endProcedure:
	ret
ENDP checkBarrelHit

PROC checkCollision
	ARG @@n: dword
	LOCAL @@ground: dword, @@platforms: dword, @@ladders: dword, @@x0: dword, @@y0: dword, @@w: dword, @@h: dword
	USES eax, ebx, edx
	
	cld
	
	screen_pointer_offset
	
	mov eax, [screenList + edx + 12]
	mov [@@platforms], eax
	mov eax, [screenList + edx + 16]
	mov [@@ladders], eax
	
	mov eax, [@@n]
	dec eax
	mov edx, [@@platforms]
	mov ebx, [edx + 4*eax]
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


PROC collision
	ARG @@o_char: dword
	LOCAL @@platforms: dword
	USES eax, ebx, ecx, edx
	
	mov ebx, [@@o_char]
	
	screen_pointer_offset
	
	mov eax, [screenList + edx + 12]
	mov [@@platforms], eax
	
; check for collision
	; if mario is in the air, currentPlatform can change
	; by increasing ecx, we make sure the ladders are also included
	; ecx is the number of platforms + number of ladders
	mov ecx, [screenList + edx]
	add ecx, [screenList + edx + 4]
	cmp [ebx + character.in_the_air], -1
	je @@checkAllGrounds
	
	call checkCharCollision, ebx, [ebx + character.currentPlatform]
@@checkX_collisionLoop:

	mov edx, [@@platforms]
	mov eax, [edx + 4*ecx - 4]
	call x_collision, ebx, eax
	loop @@checkX_collisionLoop
	jmp @@rest
	
@@checkAllGrounds:
	mov edx, [@@platforms]
	mov [ebx + character.currentPlatform], 0
	mov eax, [edx + 4*ecx-4]
	call checkCharCollision, ebx, eax
	mov eax, [ebx + character.currentPlatform]
	cmp eax, [edx + 4*ecx - 4]
	je @@rest
	loop @@checkAllGrounds
	
@@rest:
	ret
ENDP collision

PROC resetBarrels
	LOCAL @@barrels: dword
	USES eax, ecx, edx
	
	screen_pointer_offset
	
	mov eax, [screenList + edx + 20]
	mov [@@barrels], eax
	; move the number of barrels to ecx
	mov ecx, [screenList + edx + 8]
	
@@barrelLoop:
	mov edx, [@@barrels]
	mov eax, [edx + 4*ecx - 4]
	cmp [eax + character.y], SCRHEIGHT
	jg @@reset_barrel
	loop @@barrelLoop
	ret
@@reset_barrel:
	call resetBarrel, eax
	loop @@barrelLoop
	
	ret
ENDP resetBarrels

PROC resetBarrel
	ARG @@o_barrel: dword
	USES eax
	
	mov eax, [@@o_barrel]
	mov [eax + character.x], 250
	mov [eax + character.y], -16
	mov [eax + character.speed_x], 0
	mov [eax + character.speed_y], 0
	mov [eax + character.h], 16
	mov [eax + character.in_the_air], -1
	mov [eax + character.currentPlatform], 0
	
	ret
ENDP resetBarrel


PROC drawBarrels
	USES eax, ebx, ecx, edx
	
	screen_pointer_offset
	
	; store barrellist in ebx
	mov ebx, [screenList + edx + 20]
	
	xor ecx, ecx
@@drawLoop:
	mov eax, [ebx + 4*ecx]
	cmp [eax + character.x], -1
	je @@dont_draw
	call drawSprite, offset barrelsprite, [eax + character.x], [eax + character.y], [eax + character.w], [eax + character.h]
@@dont_draw:
	inc ecx
	cmp ecx, [screenList + edx + 8]
	jl @@drawLoop
	
	ret
ENDP drawBarrels

PROC updateBarrelSpeed
	ARG @@o_barrel: dword
	USES eax, ebx, ecx
	
	mov ecx, [@@o_barrel]
	; whether the barrel goes right or left depends on the slope of the current platform
	; reset speed_x -> the barrel doesn't move horizontally while in the air
	mov [ecx + character.speed_x], 0
	cmp [ecx + character.in_the_air], -1
	je @@finish
	mov eax, [ecx + character.currentPlatform]
	mov ebx, [eax + newPlatform.y1]
	cmp ebx, [eax + newPlatform.y0]
	jle @@downwards
	mov [ecx + character.speed_x], B_SPEED
	ret
@@downwards:
	mov [ecx + character.speed_x], -B_SPEED
@@finish:
	ret
ENDP

PROC main
	sti
	cld
	
	push ds
	pop es
	
	call setVideoMode, 13h
	call __keyb_installKeyboardHandler
	
mainMenu:
	
;	call fillRect,0,0,320,200,0h
	call displayString, 2, 2, offset game_title
	call drawRectangle,232,48,80,26,35h
	call displayString, 7, 30, offset msg1
	call displayString, 17, 30, offset msg2	
	call drawRectangle,15,124,122,61, 0fh
	call fillRect, 21, 124,69,1,0h
	call displayString, 15, 3, offset controls
	call displayString, 17, 3, offset msgControlsLeft
	call displayString, 18, 3, offset msgControlsRight
	call displayString, 19, 3, offset msgControlsUp
	call displayString, 20, 3, offset msgControlsDown
	call displayString, 21, 3, offset msgControlsEnter
	
	push 1 ; using the stack, 1 is the top button and 2 the bottom one
	
menuloop:
	mov ebx, [offset __keyb_keyboardState + 11h] ;Z
	cmp ebx, 1
	je upmenu
	
	mov ebx, [offset __keyb_keyboardState + 1Fh] ;S
	cmp ebx, 1
	je downmenu
	jmp SHORT checkKeypresses
	
upmenu:
	pop ebx
	cmp ebx, 1
	je pushValue
	mov ebx, 1
	call drawRectangle,263,128,49,26,00h
	call drawRectangle,232,48,80,26,35h
	jmp pushValue
	
downmenu:
	pop ebx
	cmp ebx, 2
	je pushValue
	mov ebx, 2
	call drawRectangle,232,48,80,26,00h
	call drawRectangle,263,128,49,26,35h
	
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
	mov [mario.currentScreen], 1
	
	mov [barrel2.x], -1
	mov [barrel3.x], -1
	mov [barrel4.x], -1
	mov [barrel5.x], -1
	mov [barrel6.x], -1
	call resetBarrel, offset barrel1
	
	call fillRect, 0, 0, 320, 200, 0h
	
	call drawPlatforms
	
	push 0
mainloop:
	pop edx
	inc edx
	
	cmp edx, B_TIMER
	jg noNewBarrel
	
	; store number of barrels - 1 in ecx
	push edx
	screen_pointer_offset
	mov ecx, [screenList + edx + 8] 
	dec ecx
	pop edx
	
barrelLoop:
	mov eax, ecx
	shl eax, 6
	cmp edx, eax
	jne donothing
	
	push edx
	screen_pointer_offset
	mov eax, [screenList + edx + 20] 
	pop edx	
	mov ebx, [eax+ 4*ecx]
	call resetBarrel, ebx
donothing:
	loop barrelLoop
	
noNewBarrel:
	push edx
	call resetBarrels
	
	call fillRect,0,0,320,200,0h
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
	cmp [mario.y], SCRHEIGHT
	jg dead
	
	cmp [mario.y], 0
	jle won
	
	; draw and update mario
	mov edx, [mario.speed_x]
	add [mario.x], edx
	mov edx, [mario.speed_y]
	add [mario.y], edx
	
	screen_pointer_offset
	; ecx contains the number of barrels, ebx the barrellist
	mov ecx, [screenList + edx + 8] 
	mov ebx, [screenList + edx + 20] 
	
barrel_update:
	mov eax, [ebx + 4*ecx - 4]
	
	call checkBarrelHit, eax
	cmp [mario.dead], 1
	je dead
	
	mov edx, [eax + character.speed_x]
	add [eax + character.x], edx
	mov edx, [eax + character.speed_y]
	add [eax + character.y], edx
	loop barrel_update
	
	call drawPlatforms
	cmp [mario.speed_x], 0
	jl drawLeft
	call drawSprite, offset mariospriteright, [mario.x], [mario.y], [mario.w], [mario.h]
	jmp skipLeft
	
drawLeft:
	call drawSprite_mirrored, offset mariospriteright, [mario.x], [mario.y], [mario.w], [mario.h]
	
skipLeft:
	call drawBarrels
	
	
	call wait_VBLANK, 3
	; undraw mario and the barrels
	call fillRect, [mario.x], [mario.y], [mario.w], [mario.h], 0h	
	
	
	; gravity
	inc [mario.speed_y]
	call collision, offset mario
	screen_pointer_offset
	mov ecx, [screenList + edx + 8] 
	mov ebx, [screenList + edx + 20] 
barrel_gravity:
	mov eax, [ebx + 4*ecx - 4]
	call fillRect, [eax + character.x], [eax + character.y], [eax + character.w], [eax + character.h], 0h
	inc [eax + character.speed_y]
	call collision, eax
	call updateBarrelSpeed, eax
	loop barrel_gravity
	
rest:
	; reset mario's speed_x
	mov [mario.speed_x], 0
	
	jmp mainloop
	
dead:
	call fillRect, 0, 0, 320, 200, 0h
	call displayString, 7, 2, offset dead_message
	call wait_VBLANK, 60
	call fillRect, 0, 0, 320, 200, 0h
	jmp mainMenu
	
won:
	call fillRect, 0, 0, 320, 200, 0h
	call displayString, 7, 2, offset won_message
	call wait_VBLANK, 60
	call fillRect, 0, 0, 320, 200, 0h
	jmp mainMenu
	
exit:
	call __keyb_uninstallKeyboardHandler
	call terminateProcess
	ret
ENDP main	

DATASEG
	mario character <>
	
	ground1 newPlatform <25,180,295,170,10,25h>
	ground2 newPlatform <25,110,270,120,10,25h>
	ground3 newPlatform <50,58,295,50,10,25h>
	ground4 newPlatform <25,175,285,180,10,25h>
	ground5 newPlatform <50,120,150,110,10,25h>
	ground6 newPlatform <185,120,295,110,10,25h>

	ladder1 newPlatform <254,130,264,130,20,65h>
	ladder2 newPlatform <60,68,70,68,20,65h>
	ladder3 newPlatform <290,0,300,0,20,65h>
	ladder4 newPlatform <50,130,60,130,20,65h>
	
	barrel1 character <-1,,,,,,,,>
	barrel2 character <-1,,,,,,,,>
	barrel3 character <-1,,,,,,,,>
	barrel4 character <-1,,,,,,,,>
	barrel5 character <-1,,,,,,,,>
	barrel6 character <-1,,,,,,,,>
	
; BELANGRIJK: ladderList moet juist na platformList komen
	platformList1 dd ground1,ground2,ground3
	ladderList1 dd ladder1,ladder2,ladder3
	barrelList1 dd barrel1,barrel2,barrel3,barrel4,barrel5,barrel6
	
	platformList2 dd ground4, ground5, ground6
	ladderList2 dd ladder4
	
	; het eerste getal is het aantal platformen, het tweede het aantal ladders en het derde het aantal tonnen
	screenList 	dd 3, 3, 6, platformList1, ladderList1, barrelList1
				dd 3, 1, 6, platformList2, ladderList2, barrelList1
	
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
	
	dead_message db "ded.",13,10,'$'
	won_message db "You won!",13,10,'$'

	msg1 	db "New Game", 13, 10, '$'
	msg2 	db "    Exit", 13, 10, '$'
	controls		db "Controls", 13, 10, '$'
	msgControlsLeft		db "Q: LEFT", 13, 10, '$'
	msgControlsRight	db "D: RIGHT", 13, 10, '$'
	msgControlsUp		db "Z: UP/JUMP", 13, 10, '$'
	msgControlsDown		db "S: DOWN", 13, 10, '$'
	msgControlsEnter	db "ENTER: SELECT", 13, 10, '$'
	game_title			db "(soort van) DONKEY KONG", 13, 10,'$'
	
	laddersprite 	dd 4Dh, 4Dh, 00h, 00h, 00h, 00h, 00h, 00h, 4Dh, 4Dh
				dd 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh
				dd 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh
				dd 4Dh, 4Dh, 00h, 00h, 00h, 00h, 00h, 00h, 4Dh, 4Dh
				dd 4Dh, 4Dh, 00h, 00h, 00h, 00h, 00h, 00h, 4Dh, 4Dh
				dd 4Dh, 4Dh, 00h, 00h, 00h, 00h, 00h, 00h, 4Dh, 4Dh
				dd 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh
				dd 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh
				dd 4Dh, 4Dh, 00h, 00h, 00h, 00h, 00h, 00h, 4Dh, 4Dh
				dd 4Dh, 4Dh, 00h, 00h, 00h, 00h, 00h, 00h, 4Dh, 4Dh
				dd 4Dh, 4Dh, 00h, 00h, 00h, 00h, 00h, 00h, 4Dh, 4Dh
				dd 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh
				dd 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh
				dd 4Dh, 4Dh, 00h, 00h, 00h, 00h, 00h, 00h, 4Dh, 4Dh
				dd 4Dh, 4Dh, 00h, 00h, 00h, 00h, 00h, 00h, 4Dh, 4Dh
				dd 4Dh, 4Dh, 00h, 00h, 00h, 00h, 00h, 00h, 4Dh, 4Dh
				dd 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh
				dd 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh
				dd 4Dh, 4Dh, 00h, 00h, 00h, 00h, 00h, 00h, 4Dh, 4Dh
				dd 4Dh, 4Dh, 00h, 00h, 00h, 00h, 00h, 00h, 4Dh, 4Dh
				dd 4Dh, 4Dh, 00h, 00h, 00h, 00h, 00h, 00h, 4Dh, 4Dh
				dd 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh
				dd 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh
				dd 4Dh, 4Dh, 00h, 00h, 00h, 00h, 00h, 00h, 4Dh, 4Dh
				dd 4Dh, 4Dh, 00h, 00h, 00h, 00h, 00h, 00h, 4Dh, 4Dh
				dd 4Dh, 4Dh, 00h, 00h, 00h, 00h, 00h, 00h, 4Dh, 4Dh
				dd 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh
				dd 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh
				dd 4Dh, 4Dh, 00h, 00h, 00h, 00h, 00h, 00h, 4Dh, 4Dh
				dd 4Dh, 4Dh, 00h, 00h, 00h, 00h, 00h, 00h, 4Dh, 4Dh
				dd 4Dh, 4Dh, 00h, 00h, 00h, 00h, 00h, 00h, 4Dh, 4Dh
				dd 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh
				dd 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh
				dd 4Dh, 4Dh, 00h, 00h, 00h, 00h, 00h, 00h, 4Dh, 4Dh
				dd 4Dh, 4Dh, 00h, 00h, 00h, 00h, 00h, 00h, 4Dh, 4Dh
				dd 4Dh, 4Dh, 00h, 00h, 00h, 00h, 00h, 00h, 4Dh, 4Dh
				dd 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh
				dd 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh
				dd 4Dh, 4Dh, 00h, 00h, 00h, 00h, 00h, 00h, 4Dh, 4Dh
				dd 4Dh, 4Dh, 00h, 00h, 00h, 00h, 00h, 00h, 4Dh, 4Dh
				dd 4Dh, 4Dh, 00h, 00h, 00h, 00h, 00h, 00h, 4Dh, 4Dh
				dd 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh
				dd 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh
				dd 4Dh, 4Dh, 00h, 00h, 00h, 00h, 00h, 00h, 4Dh, 4Dh
				dd 4Dh, 4Dh, 00h, 00h, 00h, 00h, 00h, 00h, 4Dh, 4Dh
				dd 4Dh, 4Dh, 00h, 00h, 00h, 00h, 00h, 00h, 4Dh, 4Dh
				dd 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh
				dd 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh, 4Dh
				dd 4Dh, 4Dh, 00h, 00h, 00h, 00h, 00h, 00h, 4Dh, 4Dh
				dd 4Dh, 4Dh, 00h, 00h, 00h, 00h, 00h, 00h, 4Dh, 4Dh

UDATASEG
	
STACK 100h

END main
