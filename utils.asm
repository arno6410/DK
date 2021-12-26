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

	movzx ax, [@@mode]
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

PROC displayString
	ARG @@row:dword, @@column:dword, @@offset:dword
	USES eax, ebx, edx
	mov edx, [@@row] ; row in edx
	mov ebx, [@@column] ; column in ebx
	mov ah, 02h ; set cursor position
	shl edx, 08h ; row in dh (00h is top)
	mov dl, bl ; column in dl (00h is left)
	mov bh, 0 ; page number in bh
	int 10h ; raise interrupt
	mov ah, 09h ; write string to standard output
	mov edx, [@@offset] ; offset of ’$’-terminated string in edx
	int 21h ; raise interrupt
	ret	
ENDP displayString

; Draw a sprite
PROC drawSprite
	ARG @@sprite: dword, @@x: dword, @@y: dword, @@w: dword, @@h:dword
	USES eax, ebx, ecx, edx, edi
	
	mov eax, [@@y]
	cmp eax, 0
	jl @@finish
	
	mov edi, VMEMADR 			; start of video memory
	add edi, [@@x]
	mov eax, SCRWIDTH
	mul [@@y]
	add edi, eax
	mov ebx, [@@sprite] ; sprite address
	mov edx, [@@h]
	
@@nextRow:
	mov ecx, [@@w]				; sprite width	
	@@nextPixel:
		mov al, [ebx]			; data
		stosb
		inc ebx					; point to next byte
		loop @@nextPixel
	add edi, SCRWIDTH
	sub edi, [@@w]
	dec edx
	jnz @@nextRow
@@finish:
	ret
ENDP drawSprite

; Draw a sprite, but mirrored
PROC drawSprite_mirrored
	ARG @@sprite: dword, @@x: dword, @@y: dword, @@w: dword, @@h:dword
	USES eax, ebx, ecx, edx, edi
	
	std
	
	mov edi, VMEMADR 			; start of video memory
	add edi, [@@x]
	mov eax, SCRWIDTH
	mul [@@y]
	add edi, eax
	add edi, [@@w]
	dec edi
	mov ebx, [@@sprite] ; sprite address
	mov edx, [@@h]
	cmp edi, VMEMADR
	jl @@finish
	
@@nextRow:
	mov ecx, [@@w]				; sprite width	
	@@nextPixel:
		mov al, [ebx]			; data
		stosb
		inc ebx					; point to next byte
		loop @@nextPixel
	add edi, SCRWIDTH
	add edi, [@@w]
	dec edx
	jnz @@nextRow
	
@@finish:
	cld
	ret
ENDP drawSprite_mirrored

; wait for @@framecount frames
proc wait_VBLANK
	ARG @@framecount: word
	USES eax, ecx, edx
	mov dx, 03dah 					; Wait for screen refresh
	movzx ecx, [@@framecount]
	
	@@VBlank_phase1:
		in al, dx 
		and al, 8
		jnz @@VBlank_phase1
	@@VBlank_phase2:
		in al, dx 
		and al, 8
		jz @@VBlank_phase2
	loop @@VBlank_phase1
	
	ret 
endp wait_VBLANK

DATASEG
	
STACK 100h

END 