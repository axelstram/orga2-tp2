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
%macro	desempaquetar	3

	pshufb %1, xmm3

	movdqu %2, %1
	movdqu %3, %1

	punpcklbw %2, xmm5
	punpckhbw %3, xmm5

	pshufb %2, xmm3
	pshufb %3, xmm3

	;%2 = B | 0 | G | 0 | R | 0 | 0 | 0 | B | 0 | G | 0 | R | 0 | 0 | 0  (PIXEL 1 Y 2)
	;%3 = B | 0 | G | 0 | R | 0 | 0 | 0 | B | 0 | G | 0 | R | 0 | 0 | 0  (PIXEL 3 Y 4)
	
%endmacro




;------------------------------------------------------------------------------------------------------
%macro procesar 1

;----------------------------------------------------------------------------------
	;Calculo si distancia(pixel, coloresParametro) > threshold

	psubq %1, coloresParametro						;Resta de quadwords
	
	movdqu xmm6, %1
	pmullw %1, xmm6									;Elevo al cuadrado y me quedo con la parte baja de los resultados en %1 (creo que con esto alcanza, ver el manual)	
						
													;%1 = B1 | 0 | G1 | 0 | R1 | 0 | 0 | 0 | B2 | 0 | G2 | 0 | R2 | 0 | 0 | 0
	phaddw %1, %1									;%1 = B1 + G1 | R1 + 0 | B1 + G1 | R1 + 0 | B2 + G2 | R2 + 0 | B2 + G2 | R2 + 0 
	phaddw %1, %1									;%1 = B1 + G1 + R1 + 0 | B1 + G1 + R1 + 0 | B1 + G1 + R1 + 0 | B1 + G1 + R1 + 0 | B2 + G2 + R2 + 0 | B2 + G2+ R2 + 0 | B2 + G2 + R2 + 0| B2 + G2 + R2 + 0 
													;%1 = B1 + G1 + R1 | B1 + G1 + R1 | B1 + G1 + R1 | B1 + G1 + R1 | B2 + G2 + R2 | B2 + G2+ R2 | B2 + G2 + R2 | B2 + G2 + R2  
	movdqu xmm10, [mascara]
	pand %1, xmm10									;%1 = B1 + G1 + R1 | 0 | 0 | 0 | B2 + G2 + R2 | 0 | 0 | 0   (cada 0 es un dword en cero)
	cvtdq2ps %1, %1									;convierto double word a float (con signo, ver si eso la caga despues, creo que no porque cuando desempaquetamos con cero deberian quedar todos positivos)
													;%1 = B1 + G1 + R1 | 0 | B2 + G2 + R2 | 0
	
	movdqu xmm8, %1									;xmm8 = B1 + G1 + R1 | 0 | B2 + G2 + R2 | 0  (copia para usarla despues y no tener que volver a calcular la suma)
		
	sqrtps %1, %1									;Calculo las raices cuadradas, %1 =  sqrt(B1 + G1 + R1) | 0 | sqrt(B2 + G2 + R2) | 0
	
	roundps %1, %1, 00								;Redondeo al entero mas cercano
	cvtps2dq %1, %1									;Convierto los floats a double words
	
	;Entonces, %1 = resultado de la funcion distancia
;-------------------------------------------------------------------------------------
	
	movdqu xmm6, %1									;Me creo una copia
	pcmpgtq xmm6, threshold							;Comparo los enteros contra el threshold por > y genero una mascara
	pand xmm8, xmm6									;xmm8 tiene los colores que son mayores al threshold y el resto en cero
	movdqu xmm9, [mascaraTodoUno]					;xmm9 = todos los bytes en 1
	pandn xmm6, xmm9								;Complemento xmm6
	pand %1, xmm6									;%1 tiene los colores que son menores al threshold y el resto en cero
	
	;Actualizo los colores
	;La suma pixel[0] + pixel[1] + pixel[2] no la tengo que hacer porque ya lo hice cuando calculo la distancia (xmm8)
	
	movdqu xmm9, [int3]								;xmm9 = 3 | 0 | 3 | 0 |    (cada numero es un doubleword)
	cvtdq2ps xmm9, xmm9								;Convierto el 3 a float para hacer la division
	divps xmm8, xmm9								;xmm8 = pixel[0] + pixel[1] + pixel[2] / 3
	movdqu xmm9, [int255]							;xmm9 = 255 | 0 | 255 | 0 |   (doublewords)
	cvtdq2ps xmm9, xmm9								;Convierto el 255 a float para poder usar min
	minps xmm8, xmm9								;xmm8 = min(255, pre@xmm8) | 0 | min(255, pre@xmm8) | 0 | (floats)
	
	paddd %1, xmm8									;xmm1 tiene los colores actualizados
	cvtps2dq %1, %1									;convierto de floats a ints
														
	
;-------------------------------------------------------------------------------------

	;GUARDARLOS EN DESTINO
	
	

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

	mov r9,  0xFFFF050403020100	;parte baja de la mÃ¡scara para pshufb (1)
	mov r10, 0xFFFF0B0A09080706	;parte alta de la mÃ¡scara para pshufb (1)

	movq xmm13, r10
	pslldq xmm13, 8
	movq xmm14, r9
	por xmm13, xmm14			;la mÃ¡scara para pshufb (1) en xmm13

	mov r9 , 0xFFFF050403020100	;parte baja de la mÃ¡scara para pshufb (2)
	mov r10, 0xFFFF0B0A09080706	;parte alta de la mÃ¡scara para pshufb (2)

	movq xmm14, r10
	pslldq xmm14, 8
	movq xmm10, r9
	por xmm13, xmm14			;la mÃ¡scara para shufb (2) en xmm14
	
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

	mov width, [rbp+24]
	mov height, [rbp+16]
	mov i, 0
	mov j, 0
	
;-----------------------------------------------------------------------------------------------

.ciclo:
	
	;cmp DWORD cantBytesImagen, 0		;Mientras haya bytes para leer...
	;je .fin
.if:
	cmp DWORD i, width	;width = 540
	jge .nuevaFila
	cmp DWORD j, height	;height = 960
	je .fin
	jmp .seguir
	
.nuevaFila:
	
	mov i, 0
	inc j
	jmp .if

.seguir:


	cmp DWORD i, 372
	je .p1
	jmp .seguir2
.p1:
	cmp DWORD j, 582
	je .p2
	jmp .seguir2

.p2:
	nop
	nop
	
.seguir2:
	
	pxor xmm1, xmm1
	pxor xmm2, xmm2
	pxor xmm10, xmm10					;Mascara de ceros

	movdqu xmm0, [src]					;Levanto 16 bytes (4 pixeles, los ultimos 4 bytes los ignoro)

	pshufb xmm0, maskShuffle

	movdqu xmm1, xmm0
	movdqu xmm2, xmm0

	punpcklbw xmm1, xmm10
	punpckhbw xmm2, xmm10

	pshufb xmm1, maskShuffle
	pshufb xmm2, maskShuffle

	;%2 = B | 0 | G | 0 | R | 0 | 0 | 0 | B | 0 | G | 0 | R | 0 | 0 | 0  (PIXEL 1 Y 2)
	;%3 = B | 0 | G | 0 | R | 0 | 0 | 0 | B | 0 | G | 0 | R | 0 | 0 | 0  (PIXEL 3 Y 4)	
	

	
;PRIMER REGISTRO (DESPUES CUANDO TERMINE PONGO UNA MACRO)
;----------------------------------------------------------------------------------
	;Calculo si distancia(pixel, coloresParametro) > threshold
	movdqu xmm11, xmm1				;xmm11 = B1 | 0 | G1 | 0 | R1 | 0 | 0 | 0 | B2 | 0 | G2 | 0 | R2 | 0 | 0 | 0
	movdqu xmm12, xmm1				;xmm12 = B1 | 0 | G1 | 0 | R1 | 0 | 0 | 0 | B2 | 0 | G2 | 0 | R2 | 0 | 0 | 0
	
	psubw xmm1, coloresParametro					;Resta de quadwords con saturacion
	
	pmullw xmm1, xmm1								;Elevo al cuadrado y me quedo con la parte baja de los resultados en xmm1 

	movdqu xmm9, xmm1
	punpcklwd xmm1, xmm10
	punpckhwd xmm9, xmm10

	movdqu xmm10, xmm1
	pslldq xmm10, 4									;shifteo 4 bytes a la izquierda
	paddd xmm1, xmm10
	pslldq xmm10, 4									;shifteo 4 bytes a la izquierda
	paddd xmm1, xmm10
	pslldq xmm1, 4									;shifteo 4 bytes a la izquierda para limpar basura
	psrldq xmm1, 12									;shifteo a la derecha 12 bytes

	movdqu xmm10, xmm9
	pslldq xmm10, 4									;shifteo 4 bytes a la izquierda
	paddd xmm9, xmm10
	pslldq xmm10, 4									;shifteo 4 bytes a la izquierda
	paddd xmm9, xmm10								
	pslldq xmm9, 4									;shifteo 4 bytes a la izquierda para limpar basura
	psrldq xmm9, 12									;shifteo a la derecha 12 bytes
	pslldq xmm9, 8									;shifteo a la izquierda 8 bytes

	por xmm1, xmm9
						
	cvtdq2ps xmm1, xmm1								;convierto double word a float 
	
;	mov eax, 0x3f800000
;	mov ecx, 0x40000000
	
	
;	pxor xmm9, xmm9
;	pxor xmm10, xmm10
	
;	movd xmm9, eax
;	movd xmm10, ecx	
;	movlhps xmm9,xmm9
;	movlhps xmm10,xmm10
	
;	divps xmm9, xmm10
;	subps xmm1, xmm9
	
	sqrtps xmm1, xmm1								;Calculo las raices cuadradas, xmm1 =  sqrt(B1 + G1 + R1) | 0 | sqrt(B2 + G2 + R2) | 0
	
	movdqu xmm10, xmm1
	pslldq xmm10, 4
	addps xmm1, xmm10
	cvttps2dq xmm1, xmm1							;Convierto los floats a double words
	;Entonces, xmm1 = resultado de la funcion distancia
;-------------------------------------------------------------------------------------
	
	;xmm11 = B1 | 0 | G1 | 0 | R1 | 0 | 0 | 0 | B2 | 0 | G2 | 0 | R2 | 0 | 0 | 0	(bytes)
	;xmm11 = B1 | G1 | R1 | 0 | B2 | G2 | R2 | 0	(words)
	;xmm9 = B1 | 0 | G1 | 0 | R1 | 0 | 0 | 0 | B2 | 0 | G2 | 0 | R2 | 0 | 0 | 0
	;xmm9 = B1 | G1 | R1 | 0 | B2 | G2 | R2 | 0	(words)

	nop
	movdqu xmm9, xmm1
	pcmpgtd xmm1, threshold							;Comparo de a qwords contra el threshold por > y genero una mascara
	pcmpeqd xmm9, threshold							;Comparo de a qwords contra el threshold por = y genero una mascara
	por xmm1, xmm9									;xmm1 = mascara >=
	pand xmm11, xmm1								;xmm11 tiene los colores que son mayores al threshold y el resto en cero
	movq xmm10, r12
	movlhps xmm10, xmm10							;xmm10 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF 
	pxor xmm1, xmm10								;Complemento xmm1
	pand xmm12, xmm1								;xmm12 tiene los colores que son menores al threshold y el resto en cero
	
;	pxor xmm10, xmm10
;	pcmpeqq xmm10, xmm11
;	movq r8, xmm10
;	psrldq xmm10, 8
;	movq rcx, xmm10

.eval1:
;	cmp QWORD r8, 0xFFFFFFFFFFFFFFFF
;	je .eval2
;	jmp .actualizar
.eval2:
;	cmp QWORD rcx, 0xFFFFFFFFFFFFFFFF
;	je .juntar_colores

	;Actualizo los colores
.actualizar:


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

.juntar_colores:								 
	pxor xmm1, xmm1
	por xmm1, xmm11
	por xmm1, xmm12									;xmm1 tiene los colores actualizados
														
	
	
	
;SEGUNDO REGISTRO (DESPUES CUANDO TERMINE PONGO UNA MACRO)
;----------------------------------------------------------------------------------
	;Calculo si distancia(pixel, coloresParametro) > threshold
	movdqu xmm11, xmm2								;xmm8 = B1 | 0 | G1 | 0 | R1 | 0 | 0 | 0 | B2 | 0 | G2 | 0 | R2 | 0 | 0 | 0
	movdqu xmm12, xmm2								;xmm9 = B1 | 0 | G1 | 0 | R1 | 0 | 0 | 0 | B2 | 0 | G2 | 0 | R2 | 0 | 0 | 0
	
	psubw xmm2, coloresParametro					;Resta de quadwords con saturacion
	
	pmullw xmm2, xmm2								;Elevo al cuadrado y me quedo con la parte baja de los resultados en xmm1 (creo que con esto alcanza, ver el manual)	

	movdqu xmm9, xmm2
	punpcklwd xmm2, xmm10
	punpckhwd xmm9, xmm10

	movdqu xmm10, xmm2
	pslldq xmm10, 4									;shifteo 4 bytes a la izquierda
	paddd xmm2, xmm10
	pslldq xmm10, 4									;shifteo 4 bytes a la izquierda
	paddd xmm2, xmm10
	pslldq xmm2, 4									;limpio basura
	psrldq xmm2, 12									;shifteo a la derecha 12 bytes

	movdqu xmm10, xmm9
	pslldq xmm10, 4									;shifteo 4 bytes a la izquierda
	paddd xmm9, xmm10
	pslldq xmm10, 4									;shifteo 4 bytes a la izquierda
	paddd xmm9, xmm10
	pslldq xmm9, 4									;shifteo 4 bytes a la izquierda para limpar basura
	psrldq xmm9, 12									;shifteo a la derecha 12 bytes
	pslldq xmm9, 8									;shifteo a la izquierda 8 bytes

	por xmm2, xmm9

	cvtdq2ps xmm2, xmm2								;convierto double word a float 
	
	pxor xmm9, xmm9
	pxor xmm10, xmm10
	
;	mov eax, 0x3f800000
;	mov ecx, 0x40000000
	
;	movd xmm9, eax
;	movd xmm10, ecx
	
;	movlhps xmm9, xmm9
;	movlhps xmm10, xmm10
;	divps xmm9, xmm10
;	subps xmm2, xmm9
	
	sqrtps xmm2, xmm2								;Calculo las raices cuadradas, xmm1 =  sqrt(B1 + G1 + R1) | 0 | sqrt(B2 + G2 + R2) | 0
	movdqu xmm10, xmm2
	pslldq xmm10, 4
	addps xmm2, xmm10
	cvttps2dq xmm2, xmm2							;Convierto los floats a double words

	;Entonces, xmm1 = resultado de la funcion distancia
;-------------------------------------------------------------------------------------
	
	;xmm11 = B1 | 0 | G1 | 0 | R1 | 0 | 0 | 0 | B2 | 0 | G2 | 0 | R2 | 0 | 0 | 0	(bytes)
	;xmm11 = B1 | G1 | R1 | 0 | B2 | G2 | R2 | 0	(words)
	;xmm12 = B1 | 0 | G1 | 0 | R1 | 0 | 0 | 0 | B2 | 0 | G2 | 0 | R2 | 0 | 0 | 0
	;xmm12 = B1 | G1 | R1 | 0 | B2 | G2 | R2 | 0	(words)

	nop
	movdqu xmm9, xmm2
	pcmpgtd xmm2, threshold							;Comparo de a qwords contra el threshold por > y genero una mascara
	pcmpeqd xmm9, threshold							;Comparo de a qwords contra el threshold por = y genero una mascara
	por xmm2, xmm9									;xmm2 = mascara >=	pand xmm11, xmm2		
	pand xmm11, xmm2
	movq xmm10, r12
	movlhps xmm10, xmm10							;xmm10 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF 
	pxor xmm2, xmm10								;Complemento xmm1
	pand xmm12, xmm2								;xmm9 tiene los colores que son menores al threshold y el resto en cero
	
	
;	pxor xmm10, xmm10
;	pcmpeqq xmm10, xmm11
;	movq r8, xmm10
;	psrldq xmm10, 8
;	movq rcx, xmm10

.eval1_2:
;	cmp QWORD r8, 0xFFFFFFFFFFFFFFFF
;	je .eval2_2
;	jmp .actualizar2
.eval2_2:
;	cmp QWORD rcx, 0xFFFFFFFFFFFFFFFF
;	je .juntar_colores2

	;Actualizo los colores
.actualizar2:

	;Actualizo los colores
	
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
	mov rax, 0x0000000000000003
	movq xmm10, rax	
	movlhps xmm10, xmm10							;xmm10 = 3 | 0 | 3 | 0 |    (cada numero es un doubleword)
	cvtdq2ps xmm10, xmm10							;Convierto el 3 a float para hacer la division
	divps xmm11, xmm10								;xmm8 = (pixel[0] + pixel[1] + pixel[2]) / 3
	mov rax, 0x00000000000000FF
	movq xmm10, rax
	movlhps xmm10, xmm10							;xmm10 = 255 | 0 | 255 | 0 |   (doublewords)
	cvtdq2ps xmm10, xmm10							;Convierto el 255 a float para poder usar min
	minps xmm11, xmm10								;xmm8 = min(255, pre@xmm8) | 0 | min(255, pre@xmm8) | 0 | (floats)
													;En realidad en xmm8 va a quedar algo como | * | 0 | 0 | 0 | 0 | 0 | 0 | 0 | * | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
	cvttps2dq xmm11, xmm11							;convierto de float a ints
	movdqu xmm10, xmm11
	pslldq xmm10, 2									;shifteo a izquierda 2 bytes
	por xmm11, xmm10									;xmm8 = | * | 0 | * | 0 | 0 | 0 | 0 | 0 | * | 0 | * | 0 | 0 | 0 | 0 | 0 |
	pslldq xmm10, 2 								;shifteo a izquierda 2 bytes
	por xmm11, xmm10									;xmm8 = | * | 0 | * | 0 | * | 0 | 0 | 0 | * | 0 | * | 0 | * | 0 | 0 | 0 |

.juntar_colores2:
	pxor xmm2, xmm2
	por xmm2, xmm11
	por xmm2, xmm12									;xmm1 tiene los colores actualizados
														
	

; EMPAQUETAR Y GUARDARLOS EN DST
	packuswb xmm1, xmm2
	movq xmm10, r10
	pslldq xmm10, 8
	movq xmm9, r9 					;xmm10 = mascara para juntar los registros
	por xmm10, xmm9
	pshufb xmm1, xmm10
	movdqu [dst], xmm1
	
	add src, 12	 
	add dst, 12									
	;sub cantBytesImagen, 12
	add i, 4	
	
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
