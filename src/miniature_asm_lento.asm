global miniature_asm


%define fuente rdi
%define destino rsi
%define iterActual ebx
%define iters r8d
%define width r9d
%define filaActual r10d
%define colActual r11d
%define heigth r12d
%define cantFilasArriba r13d
%define cantFilasAbajo r14d

section .data
ALIGN 16
matriz1:
	dw 0x1, 0x5, 0x12, 0x5, 0x1
ALIGN 16
matriz2:
	dw 0x5, 0x20, 0x40, 0x20, 0x5
ALIGN 16
matriz3:
	dw 0x12, 0x40, 0x64, 0x40, 0x12
ALIGN 16	
mascarita:
	db 0xFF, 0x2, 0x5, 0x8, 0xB, 0xE, 0x1, 0x4, 0x7, 0xA, 0xD, 0x0, 0x3, 0x6, 0x9, 0xC

ALIGN 16
mascara:
	db 0xFF, 0x3, 0x6, 0x9, 0xC, 0xF, 0x2, 0x5, 0x8, 0xB, 0xE, 0x1, 0x4, 0x7, 0xA, 0xD

section .text


; void miniature_asm(unsigned char *src,
;                unsigned char *dst,
;                int width,
;                int height,
;                float topPlane,
;                float bottomPlane,
;                int iters);
miniature_asm:
;en rdi puntero a la fuente
;en rsi puntero al destino
;en edx ancho en pixeles
;en ecx alto en pixeles
;en xmm0 el topPlane (entre 0 y 1)
;en xmm1 el bottomPlane (entro 0 y 1)
;en r8d la cantidad iteraciones a hacer
	
	
	push rbp			
	mov rbp, rsp
	push r12
	push r13
	push r14
	push r15
	push rbx									;desalineada
	
	
	
	
	
;limpio xmm15 para usarlo para desempaquetar
	pxor xmm15, xmm15
	
;guardo en r12d heigth
	xor r12, r12
	mov heigth, ecx
	
	
	
	
;multiplico el width *3 para tener la cantidad de bytes en vez de pixeles
	xor rbx,rbx
	add ebx, edx
	add ebx, edx
	add ebx, edx								;ebx = 3*width
	mov width, ebx
	
	
	
	
	
	
;uso r13 y r14 como cantFilasArriba y cantFilasAbajo
	xor r13,r13
	CVTSI2SS xmm15, heigth
	MULSS xmm15, xmm0		; height * topPlane
	CVTTSS2SI cantFilasArriba, xmm15		; guardo en r13d la cantFilasArriba a procesar
	

	xor r14,r14
	CVTSI2SS xmm14, heigth
	MOVSS xmm15, xmm14		; copio height
	MULSS xmm14, xmm1		; height * bottomPlane
	SUBSS xmm15, xmm14		; height - ( heigth * bottomPlane)
	CVTTSS2SI cantFilasAbajo, xmm15 		; guardo en r14d la cantFilasAbajo a procesar
	
	
	xor rdx, rdx
	xor rcx, rcx
	
	mov eax, cantFilasArriba
	xor rdx, rdx
	IDIV iters
	
	mov ecx, eax
	
	
	mov eax, cantFilasAbajo
	xor rdx, rdx
	IDIV iters
	
	mov edx, eax
	
	push rdx
	push rcx



;limpio r10 y r11 para usar como indices de fila y columna, los inicializo en 2 y 6, para arrancar en 
;el pixel (2,2)
	xor r10, r10
	mov filaActual, 0
	xor r11, r11
	mov colActual, 0


; contador para la iteracion en cual estoy
	xor rbx, rbx			



miniature_asm_iterar:
	CMP iterActual, iters			; si el contador es igual a cantIteraciones termine
	JE miniature_asm_fin

	
	
;Actualizo cantFilasArriba(r13d)
;	mov eax, cantFilasArriba 			; copio el valor de r13d
;	IMUL eax, iterActual			; iter actual * cantFilasArriba

	; limpio la parte alta del dividendo (estamos con positivos siempre)
;	xor edx, edx			
;	IDIV iters				; eax = (iter actual * cantFilasArriba)/cantidadIteraciones
	
;	SUB cantFilasArriba, eax			; cantFilasArriba = cantFilasArriba - (iter actual * cantFilasArriba)/cantidadIteraciones






;Actualizo cantFilasAbajo(r14d)
;	mov eax, cantFilasAbajo 			; copio el valor de r14d
;	IMUL eax, iterActual			; iter actual * cantFilasAbajo

	; limpio la parte alta del dividendo (estamos con positivos siempre)
;	xor edx, edx	
;	IDIV iters			; eax = (iter actual * cantFilasAbajo)/cantidadIteraciones
	
;	SUB cantFilasAbajo, eax			; cantFilasAbajo = cantFilasAbajo - (iter actual * cantFilasAbajo)/cantidadIteraciones


;--------------Primeras 2 filas------------------------------

miniature_asm_primeras_2_filas:
	CMP filaActual, 2
	JAE miniature_asm_banda_arriba_borde
	
	
miniature_asm_primeras_2_filas_sigue_fila:
	
	push rdi
	push rsi
	
	xor r15, r15
	mov r15d, filaActual
	IMUL r15d, width
	add r15d, colActual
	
	lea rdi, [rdi+r15]
	lea rsi, [rsi+r15]
	
	mov r15b, [rdi]
	mov [rsi], r15b
	
	pop rsi
	pop rdi
	
	inc colActual
	
	cmp colActual, width
	
	JNE miniature_asm_primeras_2_filas_sigue_fila
	

	
miniature_asm_primeras_2_filas_fin_fila:
	mov colActual, 0
	inc filaActual
	
	jmp miniature_asm_primeras_2_filas
	

;--------------------------------BANDA ARRIBA-------------------------------------------

miniature_asm_banda_arriba_borde:
	;primero paso los bordes sin tocar
	CMP filaActual, cantFilasArriba
	JBE .primeros_6
	mov colActual, 6
	mov filaActual, 2
	jmp miniature_asm_banda_arriba
	
	
	
.primeros_6:
	CMP colActual, 6
	JAE .ultimos_6
	
	;paso sin procesar
	push rdi
	push rsi
	
	xor r15, r15
	mov r15d, filaActual
	IMUL r15d, width
	add r15d, colActual
	
	lea rdi, [rdi+r15]
	lea rsi, [rsi+r15]
	
	mov r15b, [rdi]
	mov [rsi], r15b
	
	pop rsi
	pop rdi
	inc colActual	
	
	jmp .primeros_6
	
	
	
	
.ultimos_6:
	mov colActual, width
	sub colActual, 6
	
	
	
.ultimos_6_sigue:
	CMP colActual, width
	JE .fin_fila
	
	;paso sin procesar
	push rdi
	push rsi
	
	xor r15, r15
	mov r15d, filaActual
	IMUL r15d, width
	add r15d, colActual
	
	lea rdi, [rdi+r15]
	lea rsi, [rsi+r15]
	
	mov r15b, [rdi]
	mov [rsi], r15b
	
	pop rsi
	pop rdi
	inc colActual
	
	jmp .ultimos_6_sigue
	
.fin_fila:
	mov colActual, 0
	inc filaActual
	jmp miniature_asm_banda_arriba_borde




miniature_asm_banda_arriba:
	;pregunto si termine la banda de arriba o si tengo que seguir
	CMP filaActual, cantFilasArriba
	JA miniature_asm_banda_medio

	
	;levanto de memoria lo necesario para procesar el primer pixel de la fila
	
	push rdi
	xor r15, r15
	mov r15d, filaActual
	sub r15d, 2							; r15d = filaActual-2
	IMUL r15d, width					; r15d = width * (filaActual-2)
	add r15d, colActual					; r15d = width * (filaActual-2) + colActual
	sub r15d, 6							; r15d = width * (filaActual-2) + colActual - 6
	
	lea rdi, [rdi+r15]					; apunto rdi a rdi+width * (filaActual-2) + colActual-6
	
	MOVDQU xmm0, [rdi]					; levanto 16 bytes (5 pixeles y un sobrante)
; xmm0 = parte alta -> basura | r4 | g4 | b4 | r3 | g3 | b3 | r2 | g2 | b2 | r1 | g1 | b1 | r0 | g0 | b0 |
	lea rdi, [rdi+r9]				; Bajo una fila
	
	MOVDQU xmm1, [rdi]
	lea rdi, [rdi+r9]				; Bajo una fila
	
	MOVDQU xmm2, [rdi]
	lea rdi, [rdi+r9]				; Bajo una fila
	
	MOVDQU xmm3, [rdi]
	lea rdi, [rdi+r9]				; Bajo una fila
	
	MOVDQU xmm4, [rdi]
	
	pop rdi
	

;aplico pshufb para que me quede xmm = parte alta -> |b4|b3|b2|b1|b0|g4|g3|g2|g1|g0|r4|r3|r2|r1|r0|x|

	PSHUFB xmm0, [mascarita]
	PSHUFB xmm1, [mascarita]
	PSHUFB xmm2, [mascarita]
	PSHUFB xmm3, [mascarita]
	PSHUFB xmm4, [mascarita]
	
	
miniature_asm_banda_arriba_sigue_fila:
	pxor xmm15,xmm15
	
; duplico los datos para no perderlos

	MOVDQA xmm5, xmm0
	MOVDQA xmm6, xmm1
	MOVDQA xmm7, xmm2
	MOVDQA xmm8, xmm3
	MOVDQA xmm9, xmm4
	
	
;desempaqueto para trabajar en words y no perder precision. Proceso los canales Bs

	PUNPCKHBW xmm5, xmm15
	;xmm5 = parte alta -> 00|b4|00|b3|00|b2|00|b1|00|b0|00|g4|00|g3|00|g2|
	PUNPCKHBW xmm6, xmm15
	PUNPCKHBW xmm7, xmm15
	PUNPCKHBW xmm8, xmm15
	PUNPCKHBW xmm9, xmm15
	
	
	
	
;shifteo para sacar la basura y acomodarlos para trabajar con la matriz
	PSRLDQ xmm5, 6
	;xmm5 = parte alta -> 00|00|00|00|00|00|00|b4|00|b3|00|b2|00|b1|00|b0|
	PSRLDQ xmm6, 6
	PSRLDQ xmm7, 6
	PSRLDQ xmm8, 6
	PSRLDQ xmm9, 6
	
	
; multiplicamos por la matriz (solo nos interesa la parte baja de las multiplicaciones
; ya que tenemos todos los bytes mas significativos en 0
	PMULLW xmm5, [matriz1]
	PMULLW xmm6, [matriz2]	
	PMULLW xmm7, [matriz3]
	PMULLW xmm8, [matriz2]
	PMULLW xmm9, [matriz1]
	
;sumo horizontalmente las filas
	PHADDW xmm5, xmm15		;xmm5 = r0+r1|r2+r3|r4+0|0+0|0+0|0+0|0+0|0+0 ?
	PHADDW xmm6, xmm15
	PHADDW xmm7, xmm15
	PHADDW xmm8, xmm15
	PHADDW xmm9, xmm15
	
	
	PUNPCKLWD xmm5,xmm15		; xmm5 = r0+r1|0|r2+r3|0|r4|0|0|0
	PUNPCKLWD xmm6,xmm15
	PUNPCKLWD xmm7,xmm15
	PUNPCKLWD xmm8,xmm15
	PUNPCKLWD xmm9,xmm15
	
	PHADDD xmm5, xmm15			; xmm5 = r0+r1+r2+r3|r4|0|0
	PHADDD xmm6, xmm15
	PHADDD xmm7, xmm15
	PHADDD xmm8, xmm15
	PHADDD xmm9, xmm15
	
	PHADDD xmm5, xmm15			; xmm5 = r0+r1+r2+r3+r5|0|0|0
	PHADDD xmm6, xmm15
	PHADDD xmm7, xmm15
	PHADDD xmm8, xmm15
	PHADDD xmm9, xmm15
	
	
;acumulo las sumas en xmm5
	PADDD xmm5, xmm6
	PADDD xmm5, xmm7
	PADDD xmm5, xmm8
	PADDD xmm5, xmm9

	; xmm5 = sumadetodaslasfilas|0|0|0




;suma horizontal
;	pxor xmm15, xmm15
;	PHADDW xmm5, xmm15 
	;xmm5 = |x|x|x|x|6+7|5+4|3+2|1+0|
;	PHADDW xmm5, xmm15
	;xmm5 = |x|x|x|x|x|x|7+6+5+4|3+2+1+0|
;	PHADDW xmm5, xmm15
	;xmm5 = |x|x|x|x|x|x|x|7+6+5+4+3+2+1+0|
	
	
	movd eax, xmm5	;deberia tener todos ceros en la parte alta
	xor rdx,rdx
	mov ecx, 600
	DIV ecx			; me deja en ax el resultado

	
	push rsi
	xor r15, r15
	
	mov r15d, filaActual
	IMUL r15d, width
	add r15d, colActual
	lea rsi, [rsi+r15]
	mov [rsi], al 
	
	inc colActual
	pop rsi
	
	
	
;						 Proceso los canales Gs

; vuelvo a duplicar los datos para no perderlos

	MOVDQA xmm5, xmm0
	;xmm5 = x|r0|r1|r2|r3|r4|g0|g1|g2|g3|g4|b0|b1|b2|b3|b4
	MOVDQA xmm6, xmm1
	MOVDQA xmm7, xmm2
	MOVDQA xmm8, xmm3
	MOVDQA xmm9, xmm4
	
	
	
	
;shifteo para poder desempaquetar en un solo registro
	;PSLLDQ xmm5, 5
	; xmm5 = 0|0|0|0|0|x|r0|r1|r2|r3|r4|g0|g1|g2|g3|g4
	PSLLDQ xmm5, 2
	PSLLDQ xmm6, 2
	PSLLDQ xmm7, 2
	PSLLDQ xmm8, 2
	PSLLDQ xmm9, 2
	
	
	
;desempaqueto para trabajar en words y no perder precision.

	PUNPCKHBW xmm5, xmm15
	;xmm5 = parte alta -> |00|b2|00|b1|00|b0|00|g4|00|g3|00|g2|00|g1|00|g0
	PUNPCKHBW xmm6, xmm15
	PUNPCKHBW xmm7, xmm15
	PUNPCKHBW xmm8, xmm15
	PUNPCKHBW xmm9, xmm15
	
	
	
	
;shifteo para sacar la basura y acomodarlos para trabajar con la matriz
	PSLLDQ xmm5, 6
	PSRLDQ xmm5, 6
	;xmm5 = parte alta -> 00|00|00|00|00|00|00|b4|00|b3|00|b2|00|b1|00|b0|
	
	PSLLDQ xmm6, 6
	PSRLDQ xmm6, 6
	
	PSLLDQ xmm7, 6
	PSRLDQ xmm7, 6
	
	PSLLDQ xmm8, 6
	PSRLDQ xmm8, 6
	
	PSLLDQ xmm9, 6
	PSRLDQ xmm9, 6
	
	
	
	
; multiplicamos por la matriz (solo nos interesa la parte baja de las multiplicaciones
; ya que tenemos todos los bytes mas significativos en 0
	PMULLW xmm5, [matriz1]
	PMULLW xmm6, [matriz2]	
	PMULLW xmm7, [matriz3]
	PMULLW xmm8, [matriz2]
	PMULLW xmm9, [matriz1]
	
;sumo horizontalmente las filas
	PHADDW xmm5, xmm15		;xmm5 = r0+r1|r2+r3|r4+0|0+0|0+0|0+0|0+0|0+0 ?
	PHADDW xmm6, xmm15
	PHADDW xmm7, xmm15
	PHADDW xmm8, xmm15
	PHADDW xmm9, xmm15
	
	
	PUNPCKLWD xmm5,xmm15		; xmm5 = r0+r1|0|r2+r3|0|r4|0|0|0
	PUNPCKLWD xmm6,xmm15
	PUNPCKLWD xmm7,xmm15
	PUNPCKLWD xmm8,xmm15
	PUNPCKLWD xmm9,xmm15
	
	PHADDD xmm5, xmm15			; xmm5 = r0+r1+r2+r3|r4|0|0
	PHADDD xmm6, xmm15
	PHADDD xmm7, xmm15
	PHADDD xmm8, xmm15
	PHADDD xmm9, xmm15
	
	PHADDD xmm5, xmm15			; xmm5 = r0+r1+r2+r3+r5|0|0|0
	PHADDD xmm6, xmm15
	PHADDD xmm7, xmm15
	PHADDD xmm8, xmm15
	PHADDD xmm9, xmm15
	
	
;acumulo las sumas en xmm5
	PADDD xmm5, xmm6
	PADDD xmm5, xmm7
	PADDD xmm5, xmm8
	PADDD xmm5, xmm9

	; xmm5 = sumadetodaslasfilas|0|0|0




;suma horizontal
;	pxor xmm15, xmm15
;	PHADDW xmm5, xmm15 
	;xmm5 = |x|x|x|x|6+7|5+4|3+2|1+0|
;	PHADDW xmm5, xmm15
	;xmm5 = |x|x|x|x|x|x|7+6+5+4|3+2+1+0|
;	PHADDW xmm5, xmm15
	;xmm5 = |x|x|x|x|x|x|x|7+6+5+4+3+2+1+0|
	
	
	movd eax, xmm5	;deberia tener todos ceros en la parte alta
	xor rdx,rdx
	mov ecx, 600
	DIV ecx			; me deja en ax el resultado

	
	push rsi
	xor r15, r15
	
	mov r15d, filaActual
	IMUL r15d, width
	add r15d, colActual
	lea rsi, [rsi+r15]
	mov [rsi], al 
	
	inc colActual
	pop rsi
	
	
;						 Proceso los canales Rs

; vuelvo a duplicar los datos para no perderlos

	MOVDQA xmm5, xmm0
	;xmm5 = x|r0|r1|r2|r3|r4|g0|g1|g2|g3|g4|b0|b1|b2|b3|b4
	MOVDQA xmm6, xmm1
	MOVDQA xmm7, xmm2
	MOVDQA xmm8, xmm3
	MOVDQA xmm9, xmm4
	
	
	
;desempaqueto para trabajar en words y no perder precision.

	PUNPCKLBW xmm5, xmm15
	;xmm5 = parte alta -> |00|g1|00|g0|00|r4|00|r3|00|r2|00|r1|00|r0|xx|xx
	PUNPCKLBW xmm6, xmm15
	PUNPCKLBW xmm7, xmm15
	PUNPCKLBW xmm8, xmm15
	PUNPCKLBW xmm9, xmm15
	
	
	
	
;shifteo para sacar la basura y acomodarlos para trabajar con la matriz
	PSLLDQ xmm5, 4
	PSRLDQ xmm5, 6
	;xmm5 = parte alta -> 00|00|00|00|00|00|00|r4|00|r3|00|r2|00|r1|00|r0|
	
	PSLLDQ xmm6, 4
	PSRLDQ xmm6, 6
	
	PSLLDQ xmm7, 4
	PSRLDQ xmm7, 6
	
	PSLLDQ xmm8, 4
	PSRLDQ xmm8, 6
	
	PSLLDQ xmm9, 4
	PSRLDQ xmm9, 6
	
	
	
	
; multiplicamos por la matriz (solo nos interesa la parte baja de las multiplicaciones
; ya que tenemos todos los bytes mas significativos en 0
	PMULLW xmm5, [matriz1]
	PMULLW xmm6, [matriz2]	
	PMULLW xmm7, [matriz3]
	PMULLW xmm8, [matriz2]
	PMULLW xmm9, [matriz1]
	
	
;sumo horizontalmente las filas
	PHADDW xmm5, xmm15		;xmm5 = r0+r1|r2+r3|r4+0|0+0|0+0|0+0|0+0|0+0 ?
	PHADDW xmm6, xmm15
	PHADDW xmm7, xmm15
	PHADDW xmm8, xmm15
	PHADDW xmm9, xmm15
	
	
	PUNPCKLWD xmm5,xmm15		; xmm5 = r0+r1|0|r2+r3|0|r4|0|0|0
	PUNPCKLWD xmm6,xmm15
	PUNPCKLWD xmm7,xmm15
	PUNPCKLWD xmm8,xmm15
	PUNPCKLWD xmm9,xmm15
	
	PHADDD xmm5, xmm15			; xmm5 = r0+r1+r2+r3|r4|0|0
	PHADDD xmm6, xmm15
	PHADDD xmm7, xmm15
	PHADDD xmm8, xmm15
	PHADDD xmm9, xmm15
	
	PHADDD xmm5, xmm15			; xmm5 = r0+r1+r2+r3+r5|0|0|0
	PHADDD xmm6, xmm15
	PHADDD xmm7, xmm15
	PHADDD xmm8, xmm15
	PHADDD xmm9, xmm15
	
	
;acumulo las sumas en xmm5
	PADDD xmm5, xmm6
	PADDD xmm5, xmm7
	PADDD xmm5, xmm8
	PADDD xmm5, xmm9

	; xmm5 = sumadetodaslasfilas|0|0|0
	



;suma horizontal
;	pxor xmm15, xmm15
;	PHADDW xmm5, xmm15 
	;xmm5 = |x|x|x|x|6+7|5+4|3+2|1+0|
;	PHADDW xmm5, xmm15
	;xmm5 = |x|x|x|x|x|x|7+6+5+4|3+2+1+0|
;	PHADDW xmm5, xmm15
	;xmm5 = |x|x|x|x|x|x|x|7+6+5+4+3+2+1+0|
	
	
	movd eax, xmm5	;deberia tener todos ceros en la parte alta
	xor rdx,rdx
	mov ecx, 600
	DIV ecx			; me deja en ax el resultado

	
	push rsi
	xor r15, r15
	
	mov r15d, filaActual
	IMUL r15d, width
	add r15d, colActual
	lea rsi, [rsi+r15]
	mov [rsi], al 
	
	inc colActual
	pop rsi
	
	xor rcx, rcx
	mov ecx, width
	sub ecx, 6
	CMP colActual, ecx
	JE miniature_asm_banda_arriba_fin_fila
	
	
	;levanto memoria para seguir procesando
	push rdi
	
	xor r15, r15
	mov r15d, filaActual
	sub r15d, 2							; r15d = filaActual-2
	IMUL r15d, width					; r15d = width * (filaActual-2)
	add r15d, colActual					; r15d = width * (filaActual-2) + colActual
	sub r15d, 7							; r15d = width * (filaActual-2) + colActual - 7
	
	lea rdi, [rdi+r15]					; apunto rdi a rdi+width * (filaActual-2) + colActual-6
	
	MOVDQU xmm0, [rdi]					; levanto 16 bytes (5 pixeles y un sobrante)
; xmm0 = parte alta -> | r4 | g4 | b4 | r3 | g3 | b3 | r2 | g2 | b2 | r1 | g1 | b1 | r0 | g0 | b0 | basura |
	lea rdi, [rdi+r9]				; Bajo una fila
	
	MOVDQU xmm1, [rdi]
	lea rdi, [rdi+r9]				; Bajo una fila
	
	MOVDQU xmm2, [rdi]
	lea rdi, [rdi+r9]				; Bajo una fila
	
	MOVDQU xmm3, [rdi]
	lea rdi, [rdi+r9]				; Bajo una fila
	
	MOVDQU xmm4, [rdi]
	
	pop rdi
	
	
	;shuffleo para ordenar los datos para procesarlos despues (bbbbbgggggrrrrrx)
	PSHUFB xmm0, [mascara]
	PSHUFB xmm1, [mascara]
	PSHUFB xmm2, [mascara]
	PSHUFB xmm3, [mascara]
	PSHUFB xmm4, [mascara]
	

	jmp miniature_asm_banda_arriba_sigue_fila

miniature_asm_banda_arriba_fin_fila:
	mov colActual, 6
	inc filaActual
	jmp miniature_asm_banda_arriba





;---------------------------------BANDA DEL MEDIO---------------------------------------
miniature_asm_banda_medio:

	
	xor r15,r15
	mov r15d, heigth
	sub r15d, cantFilasAbajo
	
	
	cmp filaActual, r15d			;r15 = heigth - cantFilasAbajo
	JE miniature_asm_banda_abajo_borde

	
miniature_asm_banda_medio_sigue_fila:
	
	push rdi
	push rsi
	
	xor r15, r15
	mov r15d, filaActual
	IMUL r15d, width
	add r15d, colActual
	
	lea rdi, [rdi+r15]
	lea rsi, [rsi+r15]
	
	mov r15b, [rdi]
	mov [rsi], r15b
	
	pop rsi
	pop rdi
	
	inc colActual
	
	cmp colActual, width
	
	JNE miniature_asm_banda_medio_sigue_fila
	

	
miniature_asm_banda_medio_fin_fila:
	mov r11d, 0
	inc filaActual
	
	jmp miniature_asm_banda_medio
	
	
	
;--------------------Borde banda abajo----------------------
	

miniature_asm_banda_abajo_borde:
	;primero paso los bordes sin tocar
	mov r15d, heigth
	sub r15d, 2
	CMP filaActual, r15d
	JBE .primeros_6
	mov colActual, 6
	mov r15d, heigth
	sub r15d, cantFilasAbajo
	mov filaActual, r15d
	jmp miniature_asm_banda_abajo
	
	
	
.primeros_6:
	CMP colActual, 6
	JAE .ultimos_6
	
	;paso sin procesar
	push rdi
	push rsi
	
	xor r15, r15
	mov r15d, filaActual
	IMUL r15d, width
	add r15d, colActual
	
	lea rdi, [rdi+r15]
	lea rsi, [rsi+r15]
	
	mov r15b, [rdi]
	mov [rsi], r15b
	
	pop rsi
	pop rdi
	inc colActual	
	
	jmp .primeros_6
	
	
	
	
.ultimos_6:
	mov colActual, width
	sub colActual, 6
	
	
	
.ultimos_6_sigue:
	CMP colActual, width
	JE .fin_fila
	
	;paso sin procesar
	push rdi
	push rsi
	
	xor r15, r15
	mov r15d, filaActual
	IMUL r15d, width
	add r15d, colActual
	
	lea rdi, [rdi+r15]
	lea rsi, [rsi+r15]
	
	mov r15b, [rdi]
	mov [rsi], r15b
	
	pop rsi
	pop rdi
	inc colActual
	
	jmp .ultimos_6_sigue
	
.fin_fila:
	mov colActual, 0
	inc filaActual
	jmp miniature_asm_banda_abajo_borde
	
	
	
	
	
	
miniature_asm_banda_abajo:
	mov r15d, heigth
	sub r15d, 2
	CMP filaActual, r15d
	JE miniature_asm_ultimas_2_filas
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
;---CODIGO REPETIDO
;levanto de memoria lo necesario para procesar el primer pixel de la fila
	
	push rdi
	xor r15, r15
	mov r15d, filaActual
	sub r15d, 2							; r15d = filaActual-2
	IMUL r15d, width					; r15d = width * (filaActual-2)
	add r15d, colActual					; r15d = width * (filaActual-2) + colActual
	sub r15d, 6							; r15d = width * (filaActual-2) + colActual - 6
	
	lea rdi, [rdi+r15]					; apunto rdi a rdi+width * (filaActual-2) + colActual-6
	
	MOVDQU xmm0, [rdi]					; levanto 16 bytes (5 pixeles y un sobrante)
; xmm0 = parte alta -> basura | r4 | g4 | b4 | r3 | g3 | b3 | r2 | g2 | b2 | r1 | g1 | b1 | r0 | g0 | b0 |
	lea rdi, [rdi+r9]				; Bajo una fila
	
	MOVDQU xmm1, [rdi]
	lea rdi, [rdi+r9]				; Bajo una fila
	
	MOVDQU xmm2, [rdi]
	lea rdi, [rdi+r9]				; Bajo una fila
	
	MOVDQU xmm3, [rdi]
	lea rdi, [rdi+r9]				; Bajo una fila
	
	MOVDQU xmm4, [rdi]
	
	pop rdi
	

;aplico pshufb para que me quede xmm = parte alta -> |b4|b3|b2|b1|b0|g4|g3|g2|g1|g0|r4|r3|r2|r1|r0|x|

	PSHUFB xmm0, [mascarita]
	PSHUFB xmm1, [mascarita]
	PSHUFB xmm2, [mascarita]
	PSHUFB xmm3, [mascarita]
	PSHUFB xmm4, [mascarita]
	
	
miniature_asm_banda_abajo_sigue_fila:
	pxor xmm15,xmm15
	
; duplico los datos para no perderlos

	MOVDQA xmm5, xmm0
	MOVDQA xmm6, xmm1
	MOVDQA xmm7, xmm2
	MOVDQA xmm8, xmm3
	MOVDQA xmm9, xmm4
	
	
;desempaqueto para trabajar en words y no perder precision. Proceso los canales Bs

	PUNPCKHBW xmm5, xmm15
	;xmm5 = parte alta -> 00|b4|00|b3|00|b2|00|b1|00|b0|00|g4|00|g3|00|g2|
	PUNPCKHBW xmm6, xmm15
	PUNPCKHBW xmm7, xmm15
	PUNPCKHBW xmm8, xmm15
	PUNPCKHBW xmm9, xmm15
	
	
	
	
;shifteo para sacar la basura y acomodarlos para trabajar con la matriz
	PSRLDQ xmm5, 6
	;xmm5 = parte alta -> 00|00|00|00|00|00|00|b4|00|b3|00|b2|00|b1|00|b0|
	PSRLDQ xmm6, 6
	PSRLDQ xmm7, 6
	PSRLDQ xmm8, 6
	PSRLDQ xmm9, 6
	
	
; multiplicamos por la matriz (solo nos interesa la parte baja de las multiplicaciones
; ya que tenemos todos los bytes mas significativos en 0
	PMULLW xmm5, [matriz1]
	PMULLW xmm6, [matriz2]	
	PMULLW xmm7, [matriz3]
	PMULLW xmm8, [matriz2]
	PMULLW xmm9, [matriz1]
	
;sumo horizontalmente las filas
	PHADDW xmm5, xmm15		;xmm5 = r0+r1|r2+r3|r4+0|0+0|0+0|0+0|0+0|0+0 ?
	PHADDW xmm6, xmm15
	PHADDW xmm7, xmm15
	PHADDW xmm8, xmm15
	PHADDW xmm9, xmm15
	
	
	PUNPCKLWD xmm5,xmm15		; xmm5 = r0+r1|0|r2+r3|0|r4|0|0|0
	PUNPCKLWD xmm6,xmm15
	PUNPCKLWD xmm7,xmm15
	PUNPCKLWD xmm8,xmm15
	PUNPCKLWD xmm9,xmm15
	
	PHADDD xmm5, xmm15			; xmm5 = r0+r1+r2+r3|r4|0|0
	PHADDD xmm6, xmm15
	PHADDD xmm7, xmm15
	PHADDD xmm8, xmm15
	PHADDD xmm9, xmm15
	
	PHADDD xmm5, xmm15			; xmm5 = r0+r1+r2+r3+r5|0|0|0
	PHADDD xmm6, xmm15
	PHADDD xmm7, xmm15
	PHADDD xmm8, xmm15
	PHADDD xmm9, xmm15
	
	
;acumulo las sumas en xmm5
	PADDD xmm5, xmm6
	PADDD xmm5, xmm7
	PADDD xmm5, xmm8
	PADDD xmm5, xmm9

	; xmm5 = sumadetodaslasfilas|0|0|0




;suma horizontal
;	pxor xmm15, xmm15
;	PHADDW xmm5, xmm15 
	;xmm5 = |x|x|x|x|6+7|5+4|3+2|1+0|
;	PHADDW xmm5, xmm15
	;xmm5 = |x|x|x|x|x|x|7+6+5+4|3+2+1+0|
;	PHADDW xmm5, xmm15
	;xmm5 = |x|x|x|x|x|x|x|7+6+5+4+3+2+1+0|
	
	
	movd eax, xmm5	;deberia tener todos ceros en la parte alta
	xor rdx,rdx
	mov ecx, 600
	DIV ecx			; me deja en ax el resultado

	
	push rsi
	xor r15, r15
	
	mov r15d, filaActual
	IMUL r15d, width
	add r15d, colActual
	lea rsi, [rsi+r15]
	mov [rsi], al 
	
	inc colActual
	pop rsi
	
	
	
;						 Proceso los canales Gs

; vuelvo a duplicar los datos para no perderlos

	MOVDQA xmm5, xmm0
	;xmm5 = x|r0|r1|r2|r3|r4|g0|g1|g2|g3|g4|b0|b1|b2|b3|b4
	MOVDQA xmm6, xmm1
	MOVDQA xmm7, xmm2
	MOVDQA xmm8, xmm3
	MOVDQA xmm9, xmm4
	
	
	
	
;shifteo para poder desempaquetar en un solo registro
	;PSLLDQ xmm5, 5
	; xmm5 = 0|0|0|0|0|x|r0|r1|r2|r3|r4|g0|g1|g2|g3|g4
	PSLLDQ xmm5, 2
	PSLLDQ xmm6, 2
	PSLLDQ xmm7, 2
	PSLLDQ xmm8, 2
	PSLLDQ xmm9, 2
	
	
	
;desempaqueto para trabajar en words y no perder precision.

	PUNPCKHBW xmm5, xmm15
	;xmm5 = parte alta -> |00|b2|00|b1|00|b0|00|g4|00|g3|00|g2|00|g1|00|g0
	PUNPCKHBW xmm6, xmm15
	PUNPCKHBW xmm7, xmm15
	PUNPCKHBW xmm8, xmm15
	PUNPCKHBW xmm9, xmm15
	
	
	
	
;shifteo para sacar la basura y acomodarlos para trabajar con la matriz
	PSLLDQ xmm5, 6
	PSRLDQ xmm5, 6
	;xmm5 = parte alta -> 00|00|00|00|00|00|00|b4|00|b3|00|b2|00|b1|00|b0|
	
	PSLLDQ xmm6, 6
	PSRLDQ xmm6, 6
	
	PSLLDQ xmm7, 6
	PSRLDQ xmm7, 6
	
	PSLLDQ xmm8, 6
	PSRLDQ xmm8, 6
	
	PSLLDQ xmm9, 6
	PSRLDQ xmm9, 6
	
	
	
	
; multiplicamos por la matriz (solo nos interesa la parte baja de las multiplicaciones
; ya que tenemos todos los bytes mas significativos en 0
	PMULLW xmm5, [matriz1]
	PMULLW xmm6, [matriz2]	
	PMULLW xmm7, [matriz3]
	PMULLW xmm8, [matriz2]
	PMULLW xmm9, [matriz1]
	
;sumo horizontalmente las filas
	PHADDW xmm5, xmm15		;xmm5 = r0+r1|r2+r3|r4+0|0+0|0+0|0+0|0+0|0+0 ?
	PHADDW xmm6, xmm15
	PHADDW xmm7, xmm15
	PHADDW xmm8, xmm15
	PHADDW xmm9, xmm15
	
	
	PUNPCKLWD xmm5,xmm15		; xmm5 = r0+r1|0|r2+r3|0|r4|0|0|0
	PUNPCKLWD xmm6,xmm15
	PUNPCKLWD xmm7,xmm15
	PUNPCKLWD xmm8,xmm15
	PUNPCKLWD xmm9,xmm15
	
	PHADDD xmm5, xmm15			; xmm5 = r0+r1+r2+r3|r4|0|0
	PHADDD xmm6, xmm15
	PHADDD xmm7, xmm15
	PHADDD xmm8, xmm15
	PHADDD xmm9, xmm15
	
	PHADDD xmm5, xmm15			; xmm5 = r0+r1+r2+r3+r5|0|0|0
	PHADDD xmm6, xmm15
	PHADDD xmm7, xmm15
	PHADDD xmm8, xmm15
	PHADDD xmm9, xmm15
	
	
;acumulo las sumas en xmm5
	PADDD xmm5, xmm6
	PADDD xmm5, xmm7
	PADDD xmm5, xmm8
	PADDD xmm5, xmm9

	; xmm5 = sumadetodaslasfilas|0|0|0




;suma horizontal
;	pxor xmm15, xmm15
;	PHADDW xmm5, xmm15 
	;xmm5 = |x|x|x|x|6+7|5+4|3+2|1+0|
;	PHADDW xmm5, xmm15
	;xmm5 = |x|x|x|x|x|x|7+6+5+4|3+2+1+0|
;	PHADDW xmm5, xmm15
	;xmm5 = |x|x|x|x|x|x|x|7+6+5+4+3+2+1+0|
	
	
	movd eax, xmm5	;deberia tener todos ceros en la parte alta
	xor rdx,rdx
	mov ecx, 600
	DIV ecx			; me deja en ax el resultado

	
	push rsi
	xor r15, r15
	
	mov r15d, filaActual
	IMUL r15d, width
	add r15d, colActual
	lea rsi, [rsi+r15]
	mov [rsi], al 
	
	inc colActual
	pop rsi
	
	
;						 Proceso los canales Rs

; vuelvo a duplicar los datos para no perderlos

	MOVDQA xmm5, xmm0
	;xmm5 = x|r0|r1|r2|r3|r4|g0|g1|g2|g3|g4|b0|b1|b2|b3|b4
	MOVDQA xmm6, xmm1
	MOVDQA xmm7, xmm2
	MOVDQA xmm8, xmm3
	MOVDQA xmm9, xmm4
	
	
	
;desempaqueto para trabajar en words y no perder precision.

	PUNPCKLBW xmm5, xmm15
	;xmm5 = parte alta -> |00|g1|00|g0|00|r4|00|r3|00|r2|00|r1|00|r0|xx|xx
	PUNPCKLBW xmm6, xmm15
	PUNPCKLBW xmm7, xmm15
	PUNPCKLBW xmm8, xmm15
	PUNPCKLBW xmm9, xmm15
	
	
	
	
;shifteo para sacar la basura y acomodarlos para trabajar con la matriz
	PSLLDQ xmm5, 4
	PSRLDQ xmm5, 6
	;xmm5 = parte alta -> 00|00|00|00|00|00|00|r4|00|r3|00|r2|00|r1|00|r0|
	
	PSLLDQ xmm6, 4
	PSRLDQ xmm6, 6
	
	PSLLDQ xmm7, 4
	PSRLDQ xmm7, 6
	
	PSLLDQ xmm8, 4
	PSRLDQ xmm8, 6
	
	PSLLDQ xmm9, 4
	PSRLDQ xmm9, 6
	
	
	
	
; multiplicamos por la matriz (solo nos interesa la parte baja de las multiplicaciones
; ya que tenemos todos los bytes mas significativos en 0
	PMULLW xmm5, [matriz1]
	PMULLW xmm6, [matriz2]	
	PMULLW xmm7, [matriz3]
	PMULLW xmm8, [matriz2]
	PMULLW xmm9, [matriz1]
	
	
;sumo horizontalmente las filas
	PHADDW xmm5, xmm15		;xmm5 = r0+r1|r2+r3|r4+0|0+0|0+0|0+0|0+0|0+0 ?
	PHADDW xmm6, xmm15
	PHADDW xmm7, xmm15
	PHADDW xmm8, xmm15
	PHADDW xmm9, xmm15
	
	
	PUNPCKLWD xmm5,xmm15		; xmm5 = r0+r1|0|r2+r3|0|r4|0|0|0
	PUNPCKLWD xmm6,xmm15
	PUNPCKLWD xmm7,xmm15
	PUNPCKLWD xmm8,xmm15
	PUNPCKLWD xmm9,xmm15
	
	PHADDD xmm5, xmm15			; xmm5 = r0+r1+r2+r3|r4|0|0
	PHADDD xmm6, xmm15
	PHADDD xmm7, xmm15
	PHADDD xmm8, xmm15
	PHADDD xmm9, xmm15
	
	PHADDD xmm5, xmm15			; xmm5 = r0+r1+r2+r3+r5|0|0|0
	PHADDD xmm6, xmm15
	PHADDD xmm7, xmm15
	PHADDD xmm8, xmm15
	PHADDD xmm9, xmm15
	
	
;acumulo las sumas en xmm5
	PADDD xmm5, xmm6
	PADDD xmm5, xmm7
	PADDD xmm5, xmm8
	PADDD xmm5, xmm9

	; xmm5 = sumadetodaslasfilas|0|0|0
	



;suma horizontal
;	pxor xmm15, xmm15
;	PHADDW xmm5, xmm15 
	;xmm5 = |x|x|x|x|6+7|5+4|3+2|1+0|
;	PHADDW xmm5, xmm15
	;xmm5 = |x|x|x|x|x|x|7+6+5+4|3+2+1+0|
;	PHADDW xmm5, xmm15
	;xmm5 = |x|x|x|x|x|x|x|7+6+5+4+3+2+1+0|
	
	
	movd eax, xmm5	;deberia tener todos ceros en la parte alta
	xor rdx,rdx
	mov ecx, 600
	DIV ecx			; me deja en ax el resultado

	
	push rsi
	xor r15, r15
	
	mov r15d, filaActual
	IMUL r15d, width
	add r15d, colActual
	lea rsi, [rsi+r15]
	mov [rsi], al 
	
	inc colActual
	pop rsi
	
	xor rcx, rcx
	mov ecx, width
	sub ecx, 6
	CMP colActual, ecx
	JE miniature_asm_banda_abajo_fin_fila
	
	
	;levanto memoria para seguir procesando
	push rdi
	
	xor r15, r15
	mov r15d, filaActual
	sub r15d, 2							; r15d = filaActual-2
	IMUL r15d, width					; r15d = width * (filaActual-2)
	add r15d, colActual					; r15d = width * (filaActual-2) + colActual
	sub r15d, 7							; r15d = width * (filaActual-2) + colActual - 7
	
	lea rdi, [rdi+r15]					; apunto rdi a rdi+width * (filaActual-2) + colActual-6
	
	MOVDQU xmm0, [rdi]					; levanto 16 bytes (5 pixeles y un sobrante)
; xmm0 = parte alta -> | r4 | g4 | b4 | r3 | g3 | b3 | r2 | g2 | b2 | r1 | g1 | b1 | r0 | g0 | b0 | basura |
	lea rdi, [rdi+r9]				; Bajo una fila
	
	MOVDQU xmm1, [rdi]
	lea rdi, [rdi+r9]				; Bajo una fila
	
	MOVDQU xmm2, [rdi]
	lea rdi, [rdi+r9]				; Bajo una fila
	
	MOVDQU xmm3, [rdi]
	lea rdi, [rdi+r9]				; Bajo una fila
	
	MOVDQU xmm4, [rdi]
	
	pop rdi
	
	
	;shuffleo para ordenar los datos para procesarlos despues (bbbbbgggggrrrrrx)
	PSHUFB xmm0, [mascara]
	PSHUFB xmm1, [mascara]
	PSHUFB xmm2, [mascara]
	PSHUFB xmm3, [mascara]
	PSHUFB xmm4, [mascara]
	

	jmp miniature_asm_banda_abajo_sigue_fila

miniature_asm_banda_abajo_fin_fila:
	mov colActual, 6
	inc filaActual
	jmp miniature_asm_banda_abajo
	
;-----FIN CODIGO REPETIDO



;--------------Ultimas 2 filas------------------------------	
miniature_asm_ultimas_2_filas

	CMP filaActual, heigth
	JAE miniature_asm_fin_iteracion
	
	
miniature_asm_ultimas_2_filas_sigue_fila:
	
	push rdi
	push rsi
	
	xor r15, r15
	mov r15d, filaActual
	IMUL r15d, width
	add r15d, colActual
	
	lea rdi, [rdi+r15]
	lea rsi, [rsi+r15]
	
	mov r15b, [rdi]
	mov [rsi], r15b
	
	pop rsi
	pop rdi
	
	inc colActual
	
	cmp colActual, width
	
	JNE miniature_asm_ultimas_2_filas_sigue_fila
	

	
miniature_asm_ultimas_2_filas_fin_fila:
	mov colActual, 0
	inc filaActual
	
	jmp miniature_asm_ultimas_2_filas

	
	
	
miniature_asm_fin_iteracion:
	pop rcx
	pop rdx
	
	sub cantFilasArriba, ecx
	sub cantFilasAbajo, edx
	
	push rdx
	push rcx
	
	mov rax, fuente
	mov fuente, destino				; hago apuntar rdi al destino para iterar sobre la imagen ya procesada
	mov destino, rax
	
	mov filaActual, 2
	inc iterActual						; aumento el contador de iteraciones y vuelvo a iterar
	jmp miniature_asm_iterar



miniature_asm_fin:
	
	pop rcx
	pop rdx
	pop rbx
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbp

	ret
