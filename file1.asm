IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT, ds:FLAT, es:FLAT, fs:FLAT, gs:FLAT

CODESEG

PROC main
	sti
	cld
	
	; the number to be printed
	mov eax, 50000329
	mov ebx, 10
	xor ecx, ecx
	
getNextDigit:
	inc ecx
	xor edx, edx
	div ebx
	push dx
	test eax, eax
	jnz getNextDigit
	
	mov ah, 2h
printDigits:
	pop dx
	add dl, '0'
	int 21h
	loop printDigits
	
	; \r\n
	mov dl, 0Dh
	int 21h
	mov dl, 0Ah
	int 21h
	
	; terminate the program
	mov ah, 4Ch
    mov al, 00h
    int 21h
	
ENDP main	

DATASEG
	
STACK 100h

END main