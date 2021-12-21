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

PROC platformDown
	ARG @@x0: word, @@y0: word, @@d_x: word, @@d_y: word, @@h: word, @@col: byte
	LOCAL @@x1: word, @@y1: word
	USES eax, ebx, ecx, edx, edi
	
	cld
	
	; calculate x1 & y1
	movzx eax, [@@x0]
	add ax, [@@d_x]
	mov [@@x1], ax
	movzx eax, [@@y0]
	add ax, [@@d_y]
	mov [@@y1], ax
	
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
		; ebx contains the value d_y*(x-x0)
		xor ebx, ebx
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
		; ebx contains the value d_y*(x-x0)
		xor ebx, ebx
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
ENDP platformDown

; d_y is interpreted as being in the other direction (upwards)
; iow, y1 < y0
PROC platformUp
	ARG @@x0: word, @@y0: word, @@d_x: word, @@d_y: word, @@h: word, @@col: byte
	LOCAL @@x1: word, @@y1: word
	USES eax, ebx, ecx, edx, edi
	
	std
	
	; calculate x1 & y1
	movzx eax, [@@x0]
	add ax, [@@d_x]
	dec ax
	mov [@@x1], ax
	movzx eax, [@@y0]
	sub ax, [@@d_y]
	mov [@@y1], ax
	
; first part
	; compute top right corner
	movzx eax, [@@y1]
	mov edx, SCRWIDTH
	mul edx
	add ax, [@@x1]
	mov edi, VMEMADR
	add edi, eax
	
	; eax contains the value d_x*(y-y0)
	xor eax, eax
	; ecx is the row counter
	xor ecx, ecx
@@loopLine:
		; ebx contains the value d_y*(x-x0)
		xor ebx, ebx
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
			dec edi
		@@next:
			add bx, [@@d_y]
			inc edx	
		cmp dx, [@@d_x]
		jl @@loopPixel
		
		; move to the next row
		add edi, SCRWIDTH
		add di, [@@d_x]
		add ax, [@@d_x]
		inc ecx
	cmp cx, [@@h]
	jl @@loopLine
	
; second part
	movzx eax, [@@h]
	; ecx is the row counter
	xor ecx, ecx
@@loopLine2:
		; ebx contains the value d_y*(x-x0)
		xor ebx, ebx
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
			dec edi
		@@next2:
			add bx, [@@d_y]
			inc edx	
		cmp dx, [@@d_x]
		jl @@loopPixel2
		
		; move to the next row
		add edi, SCRWIDTH
		add di, [@@d_x]
		add ax, [@@d_x]
		inc ecx
	cmp cx, [@@d_y]
	jl @@loopLine2
	
	
	cld
	ret
ENDP platformUp

PROC collision_down
	ARG @@rect: rect, @@x0: dword, @@y0: dword, @@x1: dword, @@y1: dword RETURNS eax
	LOCAL @@d_x: dword, @@d_y: dword
	USES ebx, ecx, edx
	
	mov eax, [@@x1]
	sub eax, [@@x0]
	mov [@@d_x], eax
	
	mov edx, [@@y1]
	cmp edx, [@@y0]
	jl @@upwards
	
	mov edx, [@@x0]
	cmp edx, [@@rect.x]
	jge @@noCheck
	
	; if y1 > y0 (downwards slope): check the bottom left corner of character
	mov eax, [@@y1]
	sub eax, [@@y0]
	mov [@@d_y], eax
	
	; bottom left corner: (x, y+h)
	; ebx contains d_x*(y+h-y0)
	mov edx, [@@rect.y]
	add edx, [@@rect.h]
	sub edx, [@@y0]
	dec edx ; hackje om ervoor te zorgen dat raken != overlappen
	mov eax, [@@d_x]
	mul edx
	mov ebx, eax
	
	; ecx contains d_y*(x-x0)
	mov edx, [@@rect.x]
	sub edx, [@@x0]
	mov eax, [@@d_y]
	mul edx
	mov ecx, eax
	
	cmp ebx, ecx
	jl @@noCollision_dd
	; ecx/d_x = d_y/d_x * (x-x0) -> y-y0 op rechte -> +y0 doen -> y waarde op rechte
	push edx
	xor edx, edx
	mov eax, ecx
	div [@@d_x]
	add eax, [@@y0]
	sub eax, [@@rect.h]
	inc eax
	pop edx
	ret
	
@@noCollision_dd:
	xor eax, eax
	ret
	
@@upwards:
	; if y1 < y0 (upwards slope): check the bottom right corner of character
	mov eax, [@@y0]
	sub eax, [@@y1]
	mov [@@d_y], eax
	
	; bottom right corner: (x+w, y+h)
	; ebx contains d_x*(y+h-y0)
	mov edx, [@@rect.y]
	add edx, [@@rect.h]
	sub edx, [@@y0]
	mov eax, [@@d_x]
	mul edx
	mov ebx, eax
	
	; ecx contains d_y*(x+w-x0)
	mov edx, [@@rect.x]
	sub edx, ecx
	add edx, [@@rect.w]
	mov eax, [@@d_y]
	mul edx
	mov ecx, eax
	
	cmp ebx, ecx
	jl @@noCollision_du
	push edx
	xor edx, edx
	mov eax, ecx
	div [@@d_x]
	add eax, [@@y0]
	sub eax, [@@rect.h]
	inc eax
	pop edx
	ret
	
@@noCollision_du:
	xor eax, eax
	ret
	
@@noCheck:
	mov eax, [@@y0]
	add eax, [@@rect.h]
	ret
ENDP collision_down

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