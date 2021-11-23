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

PROC printUnsignedInteger
	ARG @@number: dword
	USES eax, ebx, ecx, edx
	
	; the number to be printed
	mov eax, [@@number]
	mov ebx, 10
	xor ecx, ecx
	
@@getNextDigit:
	inc ecx
	xor edx, edx
	div ebx
	push dx
	test eax, eax
	jnz @@getNextDigit
	
	mov ah, 2h
@@printDigits:
	pop dx
	add dl, '0'
	int 21h
	loop @@printDigits
	
	; \r\n
;	mov dl, 0Dh
;	int 21h
;	mov dl, 0Ah
;	int 21h
	
	ret
ENDP printUnsignedInteger

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