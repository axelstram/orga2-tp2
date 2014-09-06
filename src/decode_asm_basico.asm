global decode_asm

section .data

section .text
;	void decode_asm(unsigned char* src,
;			  unsigned char* code,
;			  int size,
;             int width,
;             int height);

decode_asm:

	;rdi = puntero a src
	;rsi = puntero a code
	;edx = size
	;ecx = width
	;r8d = height

	push	r12
	push	r13
	push	r14
	push	r15
	sub		rsp, 8

	xor		r12, r12
	xor		r13, r13
	xor		r14, r14
	xor		r15, r15

	mov		r12d, edx			;r12d = size
	mov		r13d, ecx			;r13d = width
	mov		r14d, r8d			;r14d = height

	xor		rcx, rcx			;rcx = contador (cantBytesRecorridos)
	xor		rax, rax
	mov		eax, 3				;eax = 3
	imul	eax, r13d			;eax = 3 * width
	imul	eax, r14d			;eax = 3 * width * height
	mov		r15, rax			;r15 = cantBytesImagen


;---------------------------- GENERAR MÁSCARAS ESTÁTICAS ----------------------------


	;poner en xmm1, 16 bytes de 0x0F
	mov		edx, 0x0F0F0F0F
	movd	xmm1, edx
	shufps	xmm1, xmm1, 0000b

	;poner en xmm2, 16 bytes de 0x04
	mov		edx, 0x04040404
	movd	xmm2, edx
	shufps	xmm2, xmm2, 0000b

	;poner en xmm3, 16 bytes de 0x08
	mov		edx, 0x08080808
	movd	xmm3, edx
	shufps	xmm3, xmm3, 0000b

	;poner en xmm4, 16 bytes de 0x0C
	mov		edx, 0x0C0C0C0C
	movd	xmm4, edx
	shufps	xmm4, xmm4, 0000b

	;poner en xmm5, 16 bytes de 0x01
	mov		edx, 0x01010101
	movd	xmm5, edx
	shufps	xmm5, xmm5, 0000b

	;poner en xmm15, 16 bytes de 0x03
	mov		edx, 0x03030303
	movd	xmm15, edx
	shufps	xmm15, xmm15, 0000b

	;poner en xmm14, 4 doubles de 0xFF
	mov		edx, 0x000000FF
	movd	xmm14, edx
	shufps	xmm14, xmm14, 0000b

.inicio:

	cmp dword r12d, 0								;Si size < 0, termino
	jl		.fin

	movdqu  xmm0, [rdi]								;Levanto 16 bytes (decodifico 4 caracteres a la vez)

	pand	xmm0, xmm1								;xmm0 = xmm0 & 0f0f0f0f0f0f0f0f 0f0f0f0f0f0f0f0f (me quedo con los 4 bits menos significativos)


;---------------------------- GENERAR MÁSCARAS POR COMPARACIÓN ----------------------------


	;comparar por mayor sobre xmm2 con xmm0 (tengo la máscara para el 00 en xmm6)
	movdqu	xmm6, xmm2
	pcmpgtb xmm6, xmm0

	;comparar por menor o igual sobre xmm2 con xmm0
	movdqu	xmm7, xmm0
	pcmpgtb xmm7, xmm2

	movdqu	xmm8, xmm2
	pcmpeqb xmm8, xmm0

	por		xmm7, xmm8

	;comparar por mayor sobre xmm3 con xmm0
	movdqu	xmm8, xmm3
	pcmpgtb xmm8, xmm0

	;pand sobre xmm7 con xmm8 (tengo la mascara para el 01 en xmm7)
	pand	xmm7, xmm8

	;comparar por menor o igual sobre xmm3 con xmm0
	movdqu	xmm8, xmm0
	pcmpgtb	xmm8, xmm3

	movdqu	xmm9, xmm3
	pcmpeqb	xmm9, xmm0

	por		xmm8, xmm9

	;comparar por mayor sobre xmm4 con xmm0
	movdqu	xmm9, xmm4
	pcmpgtb xmm9, xmm0

	;pand sobre xmm8 con xmm9 (tengo la mascara para el 10 en xmm8)
	pand 	xmm8, xmm9

	;comparar por menor o igual sobre xmm4 con xmm0 (tengo la máscara para el 11 en xmm9)
	movdqu	xmm9, xmm0
	pcmpgtb	xmm9, xmm4

	movdqu	xmm10, xmm4
	pcmpeqb	xmm10, xmm0

	por		xmm9, xmm10


;---------------------------- PROCESAR LOS DATOS USANDO LAS MÁSCARAS ----------------------------


	;pand sobre xmm6 con xmm0
	pand	xmm6, xmm0

	;(procesados los 00 en xmm6)

	;mover a xmm10 xmm0
	movdqu	xmm10, xmm0

	;sumar sobre xmm10, xmm5
	paddb	xmm10, xmm5

	;pand sobre xmm10 con xmm10
	pand	xmm7, xmm10

	;(procesados los 01 en xmm7)

	;mover a xmm10 xmm0
	movdqu	xmm10, xmm0

	;restar sobre xmm10 xmm7
	psubb	xmm10, xmm5

	;pand sobre xmm8 con xmm10
	pand	xmm8, xmm10

	;(procesados los 10 en xmm8)

	;mover a xmm10 xmm0
	movdqu	xmm10, xmm0

	;negar xmm10
	pandn	xmm10, xmm9

	;pand sobre xmm5 con xmm6
	pand	xmm9, xmm10

	;(procesados los 11 en xmm9)


;---------------------------- JUNTAR LOS BITS EN UN SOLO BYTE ----------------------------


	;poner los bits procesados en xmm2
	paddb	xmm6, xmm7
	paddb	xmm8, xmm9
	paddb	xmm6, xmm8

    ;sacar el 3° y 4° bit menos significativo
	pand	xmm6, xmm15


	pxor	xmm0, xmm0

	;sumar a xmm0, xmm2
	paddb	xmm0, xmm6

	;shiftear 6 bits por double-word
	psrad	xmm6, 6

	;sumar los xmm donde estan los resultados
	paddb	xmm0, xmm6

	;shiftear 6 bits por double-word
	psrad	xmm6, 6

	;sumar los xmm donde estan los resultados
	paddb	xmm0, xmm6

	;shiftear 6 bits por double-word
	psrad	xmm6, 6

	;sumar los xmm donde estan los resultados
	paddb	xmm0, xmm6

	;xmm0 queda con basura del segundo a 4 byte en sus doublewords, hay que limpiarlo
	pand	xmm0, xmm14


;---------------------------- JUNTAR LOS BYTES EN UN SOLO DOUBLEWORD ----------------------------


	movdqu	xmm6, xmm0
	psrldq	xmm6, 3									;Shifteo 3 bytes a la derecha respecto a xmm0, de a double words (4 bytes)
	movdqu	xmm7, xmm6
	psrldq	xmm7, 3									;Shifteo 3 bytes a la derecha respecto a xmm0
	movdqu	xmm8, xmm7
	psrldq	xmm8, 3									;Shifteo 3 bytes a la derecha respecto a xmm0

	paddd	xmm0, xmm6								;sumo de a 4 bytes
	paddd	xmm0, xmm7
	paddd	xmm0, xmm8								;xmm0 = 4 caracteres decodificados


;---------------------------- ESCRIBIR EL DATO Y AUMENTAR CONTADORES ----------------------------


	movd	[rsi], xmm0								;Copio los 4 caracteres decodificados

	sub		r12d, 4										;size = size - 4
	add		rdi, 16										;Avanzo los punteros
	add		rsi, 4

	jmp		.inicio


.fin:

	add		rsp, 8
	pop		r15
	pop		r14
	pop		r13
	pop		r12

    ret
