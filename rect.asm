IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT, ds:FLAT, es:FLAT, fs:FLAT, gs:FLAT

VMEMADR EQU 0A0000h	; video memory address
SCRWIDTH EQU 320	; screen witdth
SCRHEIGHT EQU 200	; screen height

CODESEG

INCLUDE "rect.inc"

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

; Draw a rectangle (video mode 13h)
; 	* draws the rectangle from position (x0,y0) with
;	  positive width 'w' and height 'h', with color "col"
PROC drawRectangle
	ARG 	@@x0:word, @@y0:word, @@w:word, @@h:word, @@col: byte
	USES 	eax, ecx, edx, edi ; note: MUL uses edx!

	; Compute the index of the rectangle's top left corner
	movzx eax, [@@y0]  ; movzx is verplaatsen en zeroextenden (tot 32 bit hier)
	mov edx, SCRWIDTH
	mul edx
	add	ax, [@@x0]

	; Compute top left corner address
	mov edi, VMEMADR
	add edi, eax
	
	; Plot the top horizontal edge.
	movzx edx, [@@w]	; store width in edx for later reuse
	mov	ecx, edx
	mov	al,[@@col]
	rep stosb
	sub edi, edx		; reset edi to left-top corner
	
	; plot both vertical edges
	movzx ecx,[@@h]
	@@vertLoop:
		mov	[edi],al		; left edge
		mov	[edi+edx-1],al	; right edge
		add	edi, SCRWIDTH
		loop @@vertLoop
	; edi should point at the bottom-left corner now
	sub edi, SCRWIDTH

	; Plot the bottom horizontal edge.
	mov	ecx, edx
	rep stosb
	ret
ENDP drawRectangle

PROC platform_both
	ARG @@x0: dword, @@y0: dword, @@x1: dword, @@y1: dword, @@h: dword, @@col: dword
	LOCAL @@d_x: dword, @@d_y: dword
	USES eax, ebx, ecx, edx, edi
	
	mov eax, [@@x1]
	sub eax, [@@x0]
	mov [@@d_x], eax
	
	mov eax, [@@y1]
	sub eax, [@@y0]
	mov [@@d_y], eax
	cmp eax, 0
	jl @@platform_up
	
@@platform_down:
	
	; first part
	; compute top left corner
	mov eax, [@@y0]
	mov edx, SCRWIDTH
	mul edx
	add eax, [@@x0]
	mov edi, VMEMADR
	add edi, eax
	
	; eax contains the value d_x*(y-y0)
	xor eax, eax
	; ecx is the row counter
	xor ecx, ecx
@@loopLine_d:
		; ebx contains the value d_y*(x-x0)
		xor ebx, ebx
		; edx is the column counter
		xor edx, edx
	@@loopPixel_d:
			cmp eax, ebx
			jl @@notInside_d
			push eax
			mov eax, [@@col]
			stosb
			pop eax
			jmp @@next_d
			
		@@notInside_d:
			inc edi
		@@next_d:
			add ebx, [@@d_y]
			inc edx	
		cmp edx, [@@d_x]
		jle @@loopPixel_d
		
		; move to the next row
		add edi, SCRWIDTH
		sub edi, [@@d_x]
		dec edi
		add eax, [@@d_x]
		inc ecx
	cmp ecx, [@@h]
	jl @@loopLine_d
	
; second part
	mov eax, [@@h]
	; ecx is the row counter
	xor ecx, ecx
@@loopLine_d2:
		; ebx contains the value d_y*(x-x0)
		xor ebx, ebx
		; edx is the column counter
		xor edx, edx
	@@loopPixel_d2:
			cmp eax, ebx
			jg @@notInside_d2
			push eax
			mov eax, [@@col]	
			stosb
			pop eax
			jmp @@next_d2
			
		@@notInside_d2:
			inc edi
		@@next_d2:
			add ebx, [@@d_y]
			inc edx	
		cmp edx, [@@d_x]
		jle @@loopPixel_d2
		
		; move to the next row
		add edi, SCRWIDTH
		sub edi, [@@d_x]
		dec edi
		add eax, [@@d_x]
		inc ecx
	cmp ecx, [@@d_y]
	jl @@loopLine_d2
	
	ret
	
@@platform_up:
	neg [@@d_y] ; now d_y is positive
	std
	; first part
	; compute top right corner
	mov eax, [@@y1]
	mov edx, SCRWIDTH
	mul edx
	add eax, [@@x1]
	mov edi, VMEMADR
	add edi, eax
	
	; eax contains the value d_x*(y-y0)
	xor eax, eax
	; ecx is the row counter
	xor ecx, ecx
@@loopLine_u:
		; ebx contains the value d_y*(x-x0)
		xor ebx, ebx
		; edx is the column counter
		xor edx, edx
	@@loopPixel_u:
			cmp eax, ebx
			jl @@notInside_u
			push eax
			mov eax, [@@col]
			stosb
			pop eax
			jmp @@next_u
			
		@@notInside_u:
			dec edi
		@@next_u:
			add ebx, [@@d_y]
			inc edx	
		cmp edx, [@@d_x]
		jl @@loopPixel_u
		
		; move to the next row
		add edi, SCRWIDTH
		add edi, [@@d_x]
		add eax, [@@d_x]
		inc ecx
	cmp ecx, [@@h]
	jl @@loopLine_u
	
; second part
	mov eax, [@@h]
	; ecx is the row counter
	xor ecx, ecx
@@loopLine_u2:
		; ebx contains the value d_y*(x-x0)
		xor ebx, ebx
		; edx is the column counter
		xor edx, edx
	@@loopPixel_u2:
			cmp eax, ebx
			jg @@notInside_u2
			push eax
			mov eax, [@@col]	
			stosb
			pop eax
			jmp @@next_u2
			
		@@notInside_u2:
			dec edi
		@@next_u2:
			add ebx, [@@d_y]
			inc edx	
		cmp edx, [@@d_x]
		jl @@loopPixel_u2
		
		; move to the next row
		add edi, SCRWIDTH
		add edi, [@@d_x]
		add eax, [@@d_x]
		inc ecx
	cmp ecx, [@@d_y]
	jl @@loopLine_u2
	cld
	
	ret
ENDP platform_both

; if there's no collision -> eax returns -1
; if there's overlap -> eax returns the y-coordinate of the correct placement
PROC collision_down
	ARG @@rect: rect, @@x0: dword, @@y0: dword, @@x1: dword, @@y1: dword RETURNS eax
	LOCAL @@d_x: dword, @@d_y: dword
	USES ebx, ecx, edx
	
	mov eax, [@@x1]
	sub eax, [@@x0]
	mov [@@d_x], eax
	
	mov edx, [@@y1]
	sub edx, [@@y0]
	mov [@@d_y], edx
	jl @@upwards
	
	; special exception for point (x0,y0)
	mov edx, [@@x0]
	cmp edx, [@@rect.x]
	jl @@skipThis_d
	mov edx, [@@rect.y]
	add edx, [@@rect.h]
	cmp edx, [@@y0]
	jl @@skipThis_d
	mov eax, [@@y0]
	sub eax, [@@rect.h]
	ret
	
@@skipThis_d:
	; if y1 > y0 (downwards slope): check the bottom left corner of character
	
	; bottom left corner: (x, y+h)
	; ebx contains d_x*(y+h-y0)
	mov edx, [@@rect.y]
	add edx, [@@rect.h]
	sub edx, [@@y0]
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
	jl @@noCollision
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
	
@@upwards:
	; if y1 < y0 (upwards slope): check the bottom right corner of character
	
	; special exception for point (x0,y0)
	mov edx, [@@rect.x]
	add edx, [@@rect.w]
	cmp edx, [@@x1]
	jl @@skipThis_u
	mov edx, [@@rect.y]
	add edx, [@@rect.h]
	cmp edx, [@@y1]
	jl @@skipThis_u
	mov eax, [@@y1]
	sub eax, [@@rect.h]
	ret
	
@@skipThis_u:
	; bottom right corner: (x+w, y+h)
	; ebx contains d_x*(y+h-y0)
	mov edx, [@@rect.y]
	add edx, [@@rect.h]
	sub edx, [@@y1]
	mov eax, [@@d_x]
	mul edx
	mov ebx, eax
	
	; ecx contains d_y*(x+w-x0)
	mov edx, [@@rect.x]
	sub edx, [@@x1]
	add edx, [@@rect.w]
	mov eax, [@@d_y]
	mul edx
	mov ecx, eax
	
	cmp ebx, ecx
	jl @@noCollision
	xor edx, edx
	mov eax, ecx
	div [@@d_x]
	add eax, [@@y1]
	sub eax, [@@rect.h]
	inc eax
	ret
	
@@noCollision:
	mov eax, -1
	ret
	
	ret
ENDP collision_down

DATASEG

STACK 100h

END