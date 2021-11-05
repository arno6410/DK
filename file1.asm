IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT, ds:FLAT, es:FLAT, fs:FLAT, gs:FLAT

CODESEG

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

PROC main
	sti
	cld
	
	push ds
	pop ds
	
	call setVideoMode, 13h
	
	call waitForSpecificKeystroke, 1Bh
	call terminateProcess
ENDP main	

DATASEG
	
STACK 100h

END main