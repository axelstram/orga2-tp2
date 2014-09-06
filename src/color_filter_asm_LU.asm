global color_filter_asm


;xmm9 y 10 auxiliares
;mayoresQueThreshold	xmm11
;menoresQueThreshold	xmm12
%define maskShuffle xmm13
%define coloresParametro xmm14
%define threshold xmm15
%define cantBytesImagen ebx
%define src rdi
%define dst rsi
%define width r11d
%define height edx
%define i r14d
%define j r15d


;------------------------------------------------------------------------------------------------------

;-----------------------------------    MACROS    ------------------------------------------------------



;------------------------------------------------------------------------------------------------------
%macro	desempaquetar	2

	cmp DWORD cantBytesImagen, 0		;Mientras haya bytes para leer...
	jle .fin

	pxor %1, %1
	pxor %2, %2
	pxor xmm10, xmm10					;Mascara de ceros
	
	
	cmp DWORD cantBytesImagen, 16
	jl %%caso_especial
	jmp %%seguir
	
%%caso_especial:
	
	sub src, 4
	movdqu xmm0, [src]
	psrldq xmm0, 4
	mov DWORD cantBytesImagen, 0
	jmp %%seguir2

%%seguir:

	movdqu xmm0, [src]					;Levanto 16 bytes (4 pixeles, los ultimos 4 bytes los ignoro)

%%seguir2:
	
		
	add src, 12	 
	sub cantBytesImagen, 12
	
	pshufb xmm0, maskShuffle

	movdqu %1, xmm0
	movdqu %2, xmm0

	punpcklbw %1, xmm10
	punpckhbw %2, xmm10

	pshufb %1, maskShuffle
	pshufb %2, maskShuffle

	;%2 = B | 0 | G | 0 | R | 0 | 0 | 0 | B | 0 | G | 0 | R | 0 | 0 | 0  (PIXEL 1 Y 2)
	;%3 = B | 0 | G | 0 | R | 0 | 0 | 0 | B | 0 | G | 0 | R | 0 | 0 | 0  (PIXEL 3 Y 4)
	
%endmacro




;------------------------------------------------------------------------------------------------------
%macro procesar 1

;----------------------------------------------------------------------------------
	;Calculo si distancia(pixel, coloresParametro) > threshold
	movdqu xmm11, %1				;xmm11 = B1 | 0 | G1 | 0 | R1 | 0 | 0 | 0 | B2 | 0 | G2 | 0 | R2 | 0 | 0 | 0
	movdqu xmm12, %1				;xmm12 = B1 | 0 | G1 | 0 | R1 | 0 | 0 | 0 | B2 | 0 | G2 | 0 | R2 | 0 | 0 | 0
	
	psubw %1, coloresParametro					;Resta de quadwords con saturacion
	
	pmullw %1, %1								;Elevo al cuadrado y me quedo con la parte baja de los resultados en xmm1 
	pxor xmm10, xmm10
	pxor xmm9, xmm9
	
	movdqu xmm9, %1
	punpcklwd %1, xmm10
	punpckhwd xmm9, xmm10

	movdqu xmm10, %1
	pslldq xmm10, 4									;shifteo 4 bytes a la izquierda
	paddd %1, xmm10
	pslldq xmm10, 4									;shifteo 4 bytes a la izquierda
	paddd %1, xmm10
	pslldq %1, 4									;shifteo 4 bytes a la izquierda para limpar basura
	psrldq %1, 12									;shifteo a la derecha 12 bytes

	movdqu xmm10, xmm9
	pslldq xmm10, 4									;shifteo 4 bytes a la izquierda
	paddd xmm9, xmm10
	pslldq xmm10, 4									;shifteo 4 bytes a la izquierda
	paddd xmm9, xmm10								
	pslldq xmm9, 4									;shifteo 4 bytes a la izquierda para limpar basura
	psrldq xmm9, 12									;shifteo a la derecha 12 bytes
	pslldq xmm9, 8									;shifteo a la izquierda 8 bytes

	por %1, xmm9
						
	cvtdq2ps %1, %1								;convierto double word a float 
	
	;Resto 0.5
	mov eax, 0x3f800000
	mov rcx, 0x4000000040000000	
	pxor xmm9, xmm9
	pxor xmm10, xmm10
	movq xmm10, rcx	
	movd xmm9, eax
	movlhps xmm9,xmm9
	movlhps xmm10,xmm10
	divps xmm9, xmm10
	subps %1, xmm9
	
	sqrtps %1, %1								;Calculo las raices cuadradas, xmm1 =  sqrt(B1 + G1 + R1) | 0 | sqrt(B2 + G2 + R2) | 0
	
	movdqu xmm10, %1
	pslldq xmm10, 4
	addps %1, xmm10
	cvttps2dq %1, %1							;Convierto los floats a double words
	;Entonces, xmm1 = resultado de la funcion distancia
;-------------------------------------------------------------------------------------
	
	;xmm11 = B1 | 0 | G1 | 0 | R1 | 0 | 0 | 0 | B2 | 0 | G2 | 0 | R2 | 0 | 0 | 0	(bytes)
	;xmm11 = B1 | G1 | R1 | 0 | B2 | G2 | R2 | 0	(words)
	;xmm9 = B1 | 0 | G1 | 0 | R1 | 0 | 0 | 0 | B2 | 0 | G2 | 0 | R2 | 0 | 0 | 0
	;xmm9 = B1 | G1 | R1 | 0 | B2 | G2 | R2 | 0	(words)

	
	movdqu xmm9, %1
	pcmpgtd %1, threshold							;Comparo de a qwords contra el threshold por > y genero una mascara
	pcmpeqd xmm9, threshold							;Comparo de a qwords contra el threshold por = y genero una mascara
	por %1, xmm9									;xmm1 = mascara >=
	pand xmm11, %1								;xmm11 tiene los colores que son mayores al threshold y el resto en cero
	movq xmm10, r12
	movlhps xmm10, xmm10							;xmm10 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF 
	pxor %1, xmm10								;Complemento xmm1
	pand xmm12, %1								;xmm12 tiene los colores que son menores al threshold y el resto en cero
	
	
	;Optimizacion para no procesar los colores blancos
	mov r12, 0x000000FF00FF00FF
	movq xmm10, r12
	movlhps xmm10, xmm10
	pcmpeqq xmm10, xmm11
	movq r8, xmm10
	psrldq xmm10, 8
	movq rcx, xmm10

%%eval1:
	cmp QWORD r8, 0xFFFFFFFFFFFFFFFF
	je %%eval2
	jmp %%actualizar
%%eval2:
	cmp QWORD rcx, 0xFFFFFFFFFFFFFFFF
	je %%juntar_colores

	;Actualizo los colores
%%actualizar:


	phaddw xmm11, xmm11								;xmm8 = B1 + G1 | R1 + 0 | B2 + G2 | R2 + 0 | B1 + G1 | R1 + 0 | B2 + G2 | R2 + 0
	phaddw xmm11, xmm11								;xmm8 = B1 + G1 + R1 | B2 + G2 + R2 | B1 + G1 + R1 | B2 + G2 + R2 | B1 + G1 + R1 | B2 + G2+ R2 | B1 + G1 + R1 | B2 + G2 + R2

	pxor xmm10, xmm10
	mov rax, 0xFFFF00000000FFFF
	movq xmm10, rax									;xmm10 = mascara para poner ceros
	pand xmm11, xmm10								;xmm8 = B1 + G1 + R1 | 0 | 0 | B2 + G2 + R2 | 0 | 0 | 0 | 0  (words)
	movdqu xmm10, xmm11
	psrldq xmm10, 2									;xmm10 = 0 | 0 | B2 + G2 + R2 | 0 | 0 | 0 | 0 | 0 
	pslldq xmm10, 4									;xmm10 = 0 | 0 | 0 |  B2 + G2 + R2 | 0 | 0 | 0 | 0
	pslldq xmm11, 12
	psrldq xmm11, 12
	paddw xmm11, xmm10								;xmm8 = B1 + G1 + R1 | 0 | 0 | 0 | B2 + G2 + R2 | 0 | 0 | 0  (words)

	cvtdq2ps xmm11, xmm11							;convierto de ints a float
	mov rax, 0x3
	movq xmm10, rax
	movlhps xmm10, xmm10							;xmm10 = 3 | 0 | 3 | 0 |    (cada numero es un doubleword)
	cvtdq2ps xmm10, xmm10							;Convierto el 3 a float para hacer la division
	divps xmm11, xmm10								;xmm8 = (pixel[0] + pixel[1] + pixel[2]) / 3
	mov rax, 0xFF
	movq xmm10, rax
	movlhps xmm10, xmm10							;xmm10 = 255 | 0 | 255 | 0 |   (doublewords)
	cvtdq2ps xmm10, xmm10							;Convierto el 255 a float para poder usar min
	minps xmm11, xmm10								;xmm8 = min(255, pre@xmm8) | 0 | min(255, pre@xmm8) | 0 | (floats)
													;En realidad en xmm8 va a quedar algo como | * | 0 | 0 | 0 | 0 | 0 | 0 | 0 | * | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
	cvttps2dq xmm11, xmm11							;convierto de float a ints
	movdqu xmm10, xmm11
	pslldq xmm10, 2									;shifteo a izquierda 2 bytes
	por xmm11, xmm10								;xmm8 = | * | 0 | * | 0 | 0 | 0 | 0 | 0 | * | 0 | * | 0 | 0 | 0 | 0 | 0 |
	pslldq xmm10, 2 								;shifteo a izquierda 2 bytes
	por xmm11, xmm10								;xmm8 = | * | 0 | * | 0 | * | 0 | 0 | 0 | * | 0 | * | 0 | * | 0 | 0 | 0 |

%%juntar_colores:								 
	pxor %1, %1
	por %1, xmm11
	por %1, xmm12									;xmm1 tiene los colores actualizados					


%endmacro	
;-------------------------------------------------------------------------------------

%macro empaquetar_y_guardar 2
	
; EMPAQUETAR Y GUARDARLOS EN DST
	packuswb %1, %2
	movq xmm10, r10
	pslldq xmm10, 8
	movq xmm9, r9 					;xmm10 = mascara para juntar los registros
	por xmm10, xmm9
	pshufb %1, xmm10
	movdqu [dst], %1
	
	add dst, 12
	
;	jmp .ciclo
	

%endmacro



;------------------------------------------------------------------------------------------------------



section .data

	mascara: db 0xFF,0xFF,0x00,0x00,0x00,0x00,0xFF,0xFF,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	int3: db 0x03,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x03,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	int255: db 0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	mascaraTodoUno: db 0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff
	juntar_mask: db 0x00, 0x1, 0x2, 0x4, 0x5, 0x6, 0x8, 0x9, 0xA, 0xC, 0xD, 0xE , 0x88, 0x88, 0x88, 0x88

section .text


;void color_filter_asm(unsigned char *src,
;                    unsigned char *dst,
;                    unsigned char rc,
;                    unsigned char gc,
;                    unsigned char bc,
;                    int threshold,
;                    int width,
;                    int height);

color_filter_asm:

	;rdi = src
	;rsi = dst
	;dl = rc
	;cl = gc
	;r8b = bc
	;r9d = threshold
	;[rbp+16] = width
	;[rbp+24] = height
	
	push rbp
	mov rbp, rsp
	push r12
	push r13
	push r14
	push r15
	push rbx
	sub rsp, 8
	
	xor r12, r12
	xor r13, r13
	xor r14, r14
	xor r15, r15
	xor rbx, rbx
	
 
	mov r12b, r8b			
	mov r8, r12
	mov r12b, cl
	mov rcx, r12
	mov r12b, dl
	mov rdx, r12
	xor r12, r12


	pxor threshold, threshold
	movd threshold, r9d				;Cargo el threshold en la parte baja de xmm15. xmm15 = threshold | 0 | 0 | 0 |
	movdqu xmm10, threshold
	pslldq xmm10, 4
	paddd threshold, xmm10				; threshold = threshold | threshold | 0 | 0
	movlhps threshold, threshold	

	
	mov r12d, [rbp+24]	;r12d = width
	mov r13d, [rbp+16]  ;r13d = height

	mov cantBytesImagen, 3
	imul cantBytesImagen, r12d
	imul cantBytesImagen, r13d

;---------------------------------------------------------------------------------

	mov r9,  0xFFFF050403020100	;parte baja de la máscara para pshufb (1)
	mov r10, 0xFFFF0B0A09080706	;parte alta de la máscara para pshufb (1)

	movq xmm13, r10
	pslldq xmm13, 8
	movq xmm14, r9
	por xmm13, xmm14			;la máscara para pshufb (1) en xmm13

	mov r9 , 0xFFFF050403020100	;parte baja de la máscara para pshufb (2)
	mov r10, 0xFFFF0B0A09080706	;parte alta de la máscara para pshufb (2)

	movq xmm14, r10
	pslldq xmm14, 8
	movq xmm10, r9
	por xmm13, xmm14			;la máscara para shufb (2) en xmm14
	
;-------------------------------------------------------------------------------------------

	;Cargo los colores que me pasan por parametro

	movq coloresParametro, r8
	movq xmm6, rcx
	pslldq xmm6, 2 		;Shifteo 2 bytes a la izquierda
	por coloresParametro, xmm6
	movq xmm6, rdx
	pslldq xmm6, 4		;Shifteo 4 bytes a la izquierda
	por coloresParametro, xmm6
	movlhps coloresParametro, coloresParametro	;xmm7 = B | 0 | G | 0 | R | 0 | 0 | 0 | B | 0 | G | 0 | R | 0 | 0 | 0

	;Cargo mascaras
	mov r12, 0xFFFFFFFFFFFFFFFF
	mov r9, 0x0908060504020100			;Primera mitad de la mascara para empaquetar
	mov r10, 0x888888880E0D0C0A			;Segunda mitad de la mascara para empaquetar


	
;-----------------------------------------------------------------------------------------------

.ciclo:
	
	;xmm1 = B | 0 | G | 0 | R | 0 | 0 | 0 | B | 0 | G | 0 | R | 0 | 0 | 0  (PIXEL 1 Y 2)
	;xmm2 = B | 0 | G | 0 | R | 0 | 0 | 0 | B | 0 | G | 0 | R | 0 | 0 | 0  (PIXEL 3 Y 4)
	desempaquetar xmm1, xmm2
	desempaquetar xmm3, xmm4
	desempaquetar xmm5, xmm6
	desempaquetar xmm7, xmm8
												
	procesar xmm1
	procesar xmm2	
	procesar xmm3
	procesar xmm4
	procesar xmm5
	procesar xmm6
	procesar xmm7
	procesar xmm8
	
	empaquetar_y_guardar xmm1, xmm2
	empaquetar_y_guardar xmm3, xmm4
	empaquetar_y_guardar xmm5, xmm6
	empaquetar_y_guardar xmm7, xmm8
	
	jmp .ciclo
;-----------------------------------------------------------------------------------
	
.fin: 
	
	add rsp, 8
	pop rbx
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbp
	
    ret
