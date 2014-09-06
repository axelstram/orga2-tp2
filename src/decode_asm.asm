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

;(MANTENER LAS MÁSCARAS PARA COMPARAR Y PROCESAR.)

	;poner en xmm15, 16 bytes de 0x04
	mov		edx, 0x04040404
	movd	xmm15, edx
	shufps	xmm15, xmm15, 0000b

	;poner en xmm14, 16 bytes de 0x08
	mov		edx, 0x08080808
	movd	xmm14, edx
	shufps	xmm14, xmm14, 0000b

	;poner en xmm13, 16 bytes de 0x0C
	mov		edx, 0x0C0C0C0C
	movd	xmm13, edx
	shufps	xmm13, xmm13, 0000b

	;poner en xmm12, 16 bytes de 0x01
	mov		edx, 0x01010101
	movd	xmm12, edx
	shufps	xmm12, xmm12, 0000b

	
;---------------------------- ENTRAR AL CICLO ----------------------------

.inicio:

	cmp dword r12d, 0								;Si size < 0, termino
	jl		.fin

	mov		edx, 0x0F0F0F0F
	
	movdqu  xmm0, [rdi]
	
	movd	xmm3, edx								;Levanto 16 bytes (decodifico 4 caracteres a la vez)
	
	movdqu	xmm1, [rdi + 16]
		
	shufps	xmm3, xmm3, 0000b
	

	pand	xmm0, xmm3								;xmm0 = xmm0 & 0f0f0f0f0f0f0f0f 0f0f0f0f0f0f0f0f (me quedo con los 4 bits menos significativos)
	pand	xmm1, xmm3

;---------------------------- GENERAR MÁSCARAS POR COMPARACIÓN ----------------------------


	;comparar por mayor sobre 0x04 (tengo la máscara para el 00 en xmm2 y xmm3)
	movdqa	xmm2, xmm15
	movdqa	xmm3, xmm15
	
	pcmpgtb xmm2, xmm0
	pcmpgtb	xmm3, xmm1

	;comparar por menor o igual sobre 0x04
	movdqa	xmm4, xmm0
	movdqa	xmm5, xmm1
	
	pcmpgtb xmm4, xmm15
	pcmpgtb xmm5, xmm15

	movdqa	xmm6, xmm15
	movdqa	xmm7, xmm15
	
	pcmpeqb xmm6, xmm0
	pcmpeqb xmm7, xmm1

	por		xmm4, xmm6
	por		xmm5, xmm7

	;comparar por mayor sobre 0x08
	movdqa	xmm6, xmm14
	movdqa	xmm7, xmm14
	
	pcmpgtb xmm6, xmm0
	pcmpgtb	xmm7, xmm1

	;pand sobre xmm7 con xmm8 (tengo la mascara para el 01 en xmm4 y xmm5)
	pand	xmm4, xmm6
	pand	xmm5, xmm7

	;comparar por menor o igual sobre 0x08
	movdqa	xmm6, xmm0
	movdqa	xmm7, xmm1
	
	pcmpgtb	xmm6, xmm14
	pcmpgtb	xmm7, xmm14

	movdqa	xmm8, xmm14
	movdqa	xmm9, xmm14
		
	pcmpeqb	xmm8, xmm0
	pcmpeqb	xmm9, xmm1

	por		xmm6, xmm8
	por		xmm7, xmm9

	;comparar por mayor sobre 0xC con xmm0
	movdqa	xmm8, xmm13
	movdqa	xmm9, xmm13
	
	pcmpgtb	xmm8, xmm0
	pcmpgtb xmm9, xmm1

	;pand sobre xmm8 con xmm9 (tengo la mascara para el 10 en xmm6 y xmm7)
	pand 	xmm6, xmm8
	pand	xmm7, xmm9

	;comparar por menor o igual sobre 0x0C (tengo la máscara para el 11 en xmm8 y xmm9)
	movdqa	xmm8, xmm0
	movdqa	xmm9, xmm1
	
	pcmpgtb	xmm8, xmm13
	pcmpgtb	xmm9, xmm13

	movdqa	xmm10, xmm13
	movdqa	xmm11, xmm13

	pcmpeqb	xmm10, xmm0
	pcmpeqb	xmm11, xmm1

	por		xmm8, xmm10
	por		xmm9, xmm11


;---------------------------- PROCESAR LOS DATOS USANDO LAS MÁSCARAS ----------------------------


	;pand sobre xmm6 con xmm0
	pand	xmm2, xmm0
	pand	xmm3, xmm1

	;(procesados los 00 en xmm2 y xmm3)

	;mover a xmm10 xmm0
	movdqa	xmm10, xmm0
	movdqa	xmm11, xmm1

	;sumar sobre xmm10, xmm5
	paddb	xmm10, xmm12
	paddb	xmm11, xmm12

	;pand sobre xmm10 con xmm10
	pand	xmm4, xmm10
	pand	xmm5, xmm11

	;(procesados los 01 en xmm4 y xmm5)

	;mover a xmm10 xmm0
	movdqa	xmm10, xmm0
	movdqa	xmm11, xmm1

	;restar sobre xmm10 xmm7
	psubb	xmm10, xmm12
	psubb	xmm11, xmm12

	;pand sobre xmm8 con xmm10
	pand	xmm6, xmm10
	pand	xmm7, xmm11

	;(procesados los 10 en xmm6 y xmm7)

	;mover a xmm10 xmm0
	movdqa	xmm10, xmm0
	movdqa	xmm11, xmm1

	;negar xmm10
	pandn	xmm10, xmm8
	pandn	xmm11, xmm9

	;pand sobre xmm5 con xmm6
	pand	xmm8, xmm10
	pand	xmm9, xmm11

	;(procesados los 11 en xmm8 y xmm9)


;---------------------------- JUNTAR LOS BITS EN UN SOLO BYTE ----------------------------

	mov		edx, 0x03030303
	
	;poner los bits procesados en xmm1
	paddb	xmm2, xmm4
	paddb	xmm6, xmm8
	
	movd	xmm10, edx
	
	
	paddb	xmm3, xmm5
	paddb	xmm7, xmm9

	shufps	xmm10, xmm10, 0000b

	paddb	xmm2, xmm6
	paddb	xmm3, xmm7

    ;sacar el 3° y 4° bit menos significativo
	pand	xmm2, xmm10
	pand	xmm3, xmm10

	pxor	xmm0, xmm0
	pxor	xmm1, xmm1


	mov		edx, 0x000000FF

	;sumar a xmm0, xmm2
	movdqa	xmm0, xmm2
	movdqa	xmm1, xmm3

	;shiftear 6 bits por double-word
	psrad	xmm2, 6
	psrad	xmm3, 6

	movd	xmm9, edx

	;sumar los xmm donde estan los resultados
	por		xmm0, xmm2
	por		xmm1, xmm3

	;shiftear 6 bits por double-word
	psrad	xmm2, 6
	psrad	xmm3, 6

	shufps	xmm9, xmm9, 0000b

	;sumar los xmm donde estan los resultados
	por		xmm0, xmm2
	por		xmm1, xmm3

	;shiftear 6 bits por double-word
	psrad	xmm2, 6
	psrad	xmm3, 6

	;sumar los xmm donde estan los resultados
	por		xmm0, xmm2
	por		xmm1, xmm3

	;xmm0 queda con basura del segundo a 4 byte en sus doublewords, hay que limpiarlo
	pand	xmm0, xmm9
	pand	xmm1, xmm9


;---------------------------- JUNTAR LOS BYTES EN UN SOLO DOUBLEWORD ----------------------------


	movdqu	xmm2, xmm0
	movdqu	xmm4, xmm0
	movdqu	xmm6, xmm0
	
	movdqu	xmm3, xmm1
	movdqu	xmm5, xmm1
	movdqu	xmm7, xmm1


	psrldq	xmm2, 3
	psrldq	xmm3, 3
	por		xmm0, xmm2
	por		xmm1, xmm3
	
	psrldq	xmm4, 6
	psrldq	xmm5, 6
	por		xmm0, xmm4
	por		xmm1, xmm5

	psrldq	xmm6, 9
	psrldq	xmm7, 9	
	por		xmm0, xmm6
	por		xmm1, xmm7
	
;---------------------------- ESCRIBIR EL DATO Y AUMENTAR CONTADORES ----------------------------


	movd	[rsi], xmm0								;Copio los 4 caracteres decodificados
	movd	[rsi + 4], xmm1

	sub		r12d, 8										;size = size - 4
	add		rdi, 32										;Avanzo los punteros
	add		rsi, 8

	jmp		.inicio


.fin:

	add		rsp, 8
	pop		r15
	pop		r14
	pop		r13
	pop		r12

    ret
