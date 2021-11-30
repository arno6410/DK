IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT, ds:FLAT, es:FLAT, fs:FLAT, gs:FLAT

VMEMADR EQU 0A0000h	; video memory address
SCRWIDTH EQU 320	; screen witdth
SCRHEIGHT EQU 200	; screen height

CODESEG

INCLUDE "rect.inc"

STRUC rect
	x	dd 0
	y	dd 0
	w	dd 0
	h	dd 0
ENDS rect

; Draw a filled rectangle
PROC fillRect
	ARG @@x0: word, @@y0: word, @@w: word, @@h: word, @@col: byte
	USES eax, ecx, edx, edi
	
	; Compute top left corner
	movzx eax, [@@y0]
	mov edx, SCRWIDTH
	mul edx
	add ax, [@@x0]
	mov edi, VMEMADR
	add edi, eax
	
	movzx ecx, [@@h]
	movzx edx, [@@w]
	mov al, [@@col]
@@plotline:
	push ecx
	mov ecx, edx
	rep stosb
	add edi, SCRWIDTH
	sub edi, edx
	pop ecx
	loop @@plotline
	
	ret
ENDP fillRect

PROC drawPlatform
	ARG @@x0: word, @@y0: word, @@x1: word, @@y1: word, @@h: word, @@col: byte
	LOCAL @@d_x: word, @@d_y: word
	USES eax, ebx, ecx, edx, edi
	
	; calculate d_x & d_y
	movzx eax, [@@x1]
	sub ax, [@@x0]
	mov [@@d_x], ax
	movzx eax, [@@y1]
	sub ax, [@@y0]
	mov [@@d_y], ax
	
; first part
	; compute top left corner
	movzx eax, [@@y0]
	mov edx, SCRWIDTH
	mul edx
	add ax, [@@x0]
	mov edi, VMEMADR
	add edi, eax
	
	; eax contains the value d_x*(y-y0)
	xor eax, eax
	; ecx is the row counter
	xor ecx, ecx
@@loopLine:
;		dec eax
		; ebx contains the value d_y*(x-1-x0)
		movzx ebx, [@@x0]
		neg bx
		; edx is the column counter
		xor edx, edx
	@@loopPixel:
			cmp ax, bx
			jl @@notInside
			push eax
			movzx eax, [@@col]
			stosb
			pop eax
			jmp @@next
			
		@@notInside:
			inc edi
		@@next:
			add bx, [@@d_y]
			inc edx	
		cmp dx, [@@d_x]
		jle @@loopPixel
		
		; move to the next row
		add edi, SCRWIDTH
		sub di, [@@d_x]
		dec edi
		add ax, [@@d_x]
		inc ecx
	cmp cx, [@@h]
	jl @@loopLine
	
; second part
	movzx eax, [@@h]
	; ecx is the row counter
	xor ecx, ecx
@@loopLine2:
		; ebx contains the value d_y*(x+1-x0)
		movzx ebx, [@@x0]
		; edx is the column counter
		xor edx, edx
	@@loopPixel2:
			cmp ax, bx
			jg @@notInside2
			push eax
			movzx eax, [@@col]	
			stosb
			pop eax
			jmp @@next2
			
		@@notInside2:
			inc edi
		@@next2:
			add bx, [@@d_y]
			inc edx	
		cmp dx, [@@d_x]
		jle @@loopPixel2
		
		; move to the next row
		add edi, SCRWIDTH
		sub di, [@@d_x]
		dec edi
		add ax, [@@d_x]
		inc ecx
	cmp cx, [@@d_y]
	jl @@loopLine2
	
	ret
ENDP drawPlatform

; Draws the 'fixed' rect
PROC drawRects
	call fillRect, [rect1.x], [rect1.y], [rect1.w], [rect1.h], 25h
	call fillRect, [rect2.x], [rect2.y], [rect2.w], [rect2.h], 25h
	
	ret
ENDP drawRects

DATASEG
	; the 'fixed' rects
	rect1 rect <30, 170, SCRWIDTH-30, 10>
	rect2 rect <0, 120, SCRWIDTH-30, 10> 
	
STACK 100h

END