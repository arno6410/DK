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

; Draws the 'fixed' rect
PROC drawRects
	call fillRect, [rect1.x], [rect1.y], [rect1.w], [rect1.h], 25h
	call fillRect, [rect2.x], [rect2.y], [rect2.w], [rect2.h], 25h
	
	ret
ENDP drawRects

; Test a certain rect for collision with the 'fixed' rects
PROC testCollision
	ARG @@rect: rect RETURNS eax
	USES ebx
	
	
	call testOverlap, [@@rect.x], [@@rect.y], [@@rect.w], [@@rect.h], \
		[rect1.x], [rect1.y], [rect1.w], [rect1.h]
	mov ebx, eax
	call testOverlap, [@@rect.x], [@@rect.y], [@@rect.w], [@@rect.h], \
		[rect2.x], [rect2.y], [rect2.w], [rect2.h]
	
	or eax, ebx
	
	ret
ENDP testCollision

PROC testXCollision
	ARG @@rect: rect RETURNS eax
	USES ebx, ecx, edx
	
	call xOverlap, [@@rect.x], [@@rect.y], [@@rect.w], [@@rect.h], \
		[rect1.x], [rect1.y], [rect1.w], [rect1.h]
	mov ebx, eax
	call xOverlap, [@@rect.x], [@@rect.y], [@@rect.w], [@@rect.h], \
		[rect2.x], [rect2.y], [rect2.w], [rect2.h]
	or ebx, eax
	
	; also test with left & right screen boundaries
	mov eax, 0
	mov ecx, [@@rect.x]
	add ecx, [@@rect.w]
	cmp ecx, SCRWIDTH
	jge rightSideOK
	mov eax, 1

rightSideOK:
	cmp [@@rect.x], 0
	jge leftSideOK
	mov eax, 1
	
leftSideOK:
	or eax, ebx
	
	ret
ENDP testXCollision

PROC testYCollision
	ARG @@rect: rect RETURNS eax
	USES ebx
	
	call yOverlap, [@@rect.x], [@@rect.y], [@@rect.w], [@@rect.h], \
		[rect1.x], [rect1.y], [rect1.w], [rect1.h]
	mov ebx, eax
	call yOverlap, [@@rect.x], [@@rect.y], [@@rect.w], [@@rect.h], \
		[rect2.x], [rect2.y], [rect2.w], [rect2.h]
	
	or eax, ebx
	
	ret
ENDP testYCollision

; Test if two rectangles overlap
PROC testOverlap
;	ARG @@r1: rect, @@r2: rect RETURNS eax
;	USES ebx, ecx, edx
;	
;	mov eax, 1 ; assume overlap
;	
;	; r1 above r2? <=> r1.y+r1.h < r2.y -> no overlap
;	mov ecx, [@@r1.y]
;	add ecx, [@@r1.h]
;	mov edx, [@@r2.y]
;	
;	cmp ecx, edx ; if ecx < edx: no overlap
;	jge overlapy1
;	mov eax, 0
;	ret
;
;overlapy1:
;	; r1 below r2? <=> r2.y+r2.h < r1.y -> no overlap
;	mov ecx, [@@r2.y]
;	add ecx, [@@r2.h]
;	mov edx, [@@r1.y]
;	
;	cmp ecx, edx ; if ecx < edx: no overlap
;	jge overlapy2
;	mov eax, 0
;	ret
;
;overlapy2:
;	; r1 left of r2? <=> r1.x+r1.w < r2.x -> no overlap
;	mov ecx, [@@r1.x]
;	add ecx, [@@r1.w]
;	mov edx, [@@r2.x]
;	
;	cmp ecx, edx ; if ecx < edx: no overlap
;	jg overlapx1
;	mov eax, 0
;	ret
;
;overlapx1:
;	; r1 right of r2? <=> r2.x+r2.w < r1.x -> no overlap
;	mov ecx, [@@r2.x]
;	add ecx, [@@r2.w]
;	mov edx, [@@r1.x]
;	
;	cmp ecx, edx ; if ecx < edx: no overlap
;	jg overlapx2
;	mov eax, 0
;	ret
;
;overlapx2:
	ret
ENDP testOverlap

PROC xOverlap
	ARG @@r1: rect, @@r2: rect RETURNS eax
	USES ebx, ecx, edx
	
	mov eax, 1 ; assume overlap
	
	; r1 left of r2? <=> r1.x+r1.w < r2.x -> no overlap
	mov ecx, [@@r1.x]
	add ecx, [@@r1.w]
	mov edx, [@@r2.x]
	
	cmp ecx, edx ; if ecx < edx: no overlap
	jge overlapx1
	mov eax, 0
	ret

overlapx1:
	; r1 right of r2? <=> r2.x+r2.w < r1.x -> no overlap
	mov ecx, [@@r2.x]
	add ecx, [@@r2.w]
	mov edx, [@@r1.x]
	
	cmp ecx, edx ; if ecx < edx: no overlap
	jge overlapx2
	mov eax, 0
	ret

overlapx2:
	ret
ENDP xOverlap

PROC yOverlap
	ARG @@r1: rect, @@r2: rect RETURNS eax
	USES ebx, ecx, edx
	
	mov eax, 1 ; assume overlap
	
	; r1 above r2? <=> r1.y+r1.h < r2.y -> no overlap
	mov ecx, [@@r1.y]
	add ecx, [@@r1.h]
	mov edx, [@@r2.y]
	
	cmp ecx, edx ; if ecx < edx: no overlap
	jge overlapy1
	mov eax, 0
	ret

overlapy1:
	; r1 below r2? <=> r2.y+r2.h < r1.y -> no overlap
	mov ecx, [@@r2.y]
	add ecx, [@@r2.h]
	mov edx, [@@r1.y]
	
	cmp ecx, edx ; if ecx < edx: no overlap
	jge overlapy2
	mov eax, 0
	ret

overlapy2:
	; r1 left of r2? <=> r1.x+r1.w < r2.x -> no overlap
	mov ecx, [@@r1.x]
	add ecx, [@@r1.w]
	mov edx, [@@r2.x]
	
	cmp ecx, edx ; if ecx < edx: no overlap
	jg overlapx1
	mov eax, 0
	ret
	
	ret
ENDP yOverlap

DATASEG
	; the 'fixed' rects
	rect1 rect <30, 170, SCRWIDTH-30, 10>
	rect2 rect <0, 120, SCRWIDTH-30, 10> 
	
STACK 100h

END