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
	
	
	
;calculo la cantidad de filas a restar en cada iteracion y las pusheo para poder pisar esos registros
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




;limpio r10 y r11 para usar como indices de fila y columna
	xor r10, r10
	mov filaActual, 0
	xor r11, r11
	mov colActual, 0



; contador para la iteracion en cual estoy
	xor rbx, rbx			



; cargo en xmm10, xmm11, xmm12 la matriz
	movdqa xmm10, [matriz1]
	movdqa xmm11, [matriz2]
	movdqa xmm12, [matriz3]
	
	
	
	
; cargo en xmm13 y xmm14 las mascaras para los pshufb
	movdqa xmm13, [mascara]
	movdqa xmm14, [mascarita]



miniature_asm_iterar:
	CMP iterActual, iters			; si el contador es igual a cantIteraciones termine
	JE miniature_asm_fin


;--------------Primeras 2 filas------------------------------
;paso las dos primeras filas sin procesarlas


miniature_asm_primeras_2_filas:
;pregunto si termine las primeras dos filas o no
	CMP filaActual, 2
	JAE miniature_asm_banda_arriba
	
	
	
miniature_asm_primeras_2_filas_sigue_fila:
;paso 16 bytes sin procesar
	
	push fuente
	push destino
	
	xor r15, r15
	mov r15d, filaActual
	IMUL r15d, width
	add r15d, colActual
	
	lea fuente, [fuente+r15]
	lea destino, [destino+r15]
	
	movdqu xmm0, [fuente]
	movdqu [destino], xmm0

	pop destino
	pop fuente
	
	add colActual, 16
	
	cmp colActual, width
	
	JNE miniature_asm_primeras_2_filas_sigue_fila
	

	
miniature_asm_primeras_2_filas_fin_fila:
	mov colActual, 0
	inc filaActual
	
	jmp miniature_asm_primeras_2_filas
	

;--------------------------------BANDA ARRIBA-------------------------------------------



miniature_asm_banda_arriba:
	;pregunto si termine la banda de arriba o si tengo que seguir
	CMP filaActual, cantFilasArriba
	JA miniature_asm_banda_medio
	
	
	
	;paso sin procesar los primeros 2 pixeles (6 canales)
	push fuente
	push destino
	
	xor r15,r15
	mov r15d, filaActual
	IMUL r15d, width
	add r15d, colActual 			; deberia ser 0 siempre
	
	lea destino, [destino + r15]
	lea fuente, [fuente + r15]
	
	movdqu xmm0, [fuente]
	movdqu [destino], xmm0
	
	pop destino
	pop fuente
	
	mov colActual, 6

	
	;levanto de memoria lo necesario para procesar el primer pixel de la fila
	
	push fuente
	xor r15, r15
	mov r15d, filaActual
	sub r15d, 2							; r15d = filaActual-2
	IMUL r15d, width					; r15d = width * (filaActual-2)
	add r15d, colActual					; r15d = width * (filaActual-2) + colActual
	sub r15d, 6							; r15d = width * (filaActual-2) + colActual - 6
	
	lea fuente, [fuente+r15]					; apunto rdi a rdi+width * (filaActual-2) + colActual-6
	
	MOVDQU xmm0, [fuente]					; levanto 16 bytes (5 pixeles y un sobrante)
; xmm0 = parte baja -> b0|g0|r0|b1|g1|r1|b2|g2|r2|b3|g3|r3|b4|g4|r4|basura
	lea fuente, [fuente+r9]				; Bajo una fila
	
	MOVDQU xmm1, [fuente]
	lea fuente, [fuente+r9]				; Bajo una fila
	
	MOVDQU xmm2, [fuente]
	lea fuente, [fuente+r9]				; Bajo una fila
	
	MOVDQU xmm3, [fuente]
	lea fuente, [fuente+r9]				; Bajo una fila
	
	MOVDQU xmm4, [fuente]
	
	pop fuente
	


;aplico pshufb con la "mascarita" en xmm14 para que me quede
; xmm = parte baja -> |x|r0|r1|r2|r3|r4|g0|g1|g2|g3|g4|b0|b1|b2|b3|b4|

;	PSHUFB xmm0, [mascarita]
	PSHUFB xmm0, xmm14		; xmm14 = mascarita
	PSHUFB xmm1, xmm14
	PSHUFB xmm2, xmm14
	PSHUFB xmm3, xmm14
	PSHUFB xmm4, xmm14
	
	
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
	;xmm5 = parte baja -> g2|00|g3|00|g4|00|b0|00|b1|00|b2|00|b3|00|b4|00|
	PUNPCKHBW xmm6, xmm15
	PUNPCKHBW xmm7, xmm15
	PUNPCKHBW xmm8, xmm15
	PUNPCKHBW xmm9, xmm15
	
	
	
	
;shifteo para sacar la basura y acomodarlos para trabajar con la matriz
	PSRLDQ xmm5, 6
	;xmm5 = b0|00|b1|00|b2|00|b3|00|b4|00|00|00|00|00|00|00|
	PSRLDQ xmm6, 6
	PSRLDQ xmm7, 6
	PSRLDQ xmm8, 6
	PSRLDQ xmm9, 6
	
	
; multiplicamos por la matriz (solo nos interesa la parte baja de las multiplicaciones
; ya que tenemos todos los bytes mas significativos en 0, en xmm10 tengo la fila 1 y 5 de la matriz
; en xmm11 tengo las filas 2 y 4 de la matriz y en xmm12 tengo la fila 3 de la matriz.
	PMULLW xmm5, xmm10
	PMULLW xmm6, xmm11	
	PMULLW xmm7, xmm12
	PMULLW xmm8, xmm11
	PMULLW xmm9, xmm10
	
	
	
;sumo horizontalmente las filas, en xmm15 tengo todos 0s
	PHADDW xmm5, xmm15		;xmm5 = r0+r1|r2+r3|r4+0|0+0|0+0|0+0|0+0|0+0 
	PHADDW xmm6, xmm15
	PHADDW xmm7, xmm15
	PHADDW xmm8, xmm15
	PHADDW xmm9, xmm15
	
	;extiendo a doubles para no perder precision en las sumas
	
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
	
	PHADDD xmm5, xmm15			; xmm5 = r0+r1+r2+r3+r4|0|0|0
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

;paso a eax la suma de todas las filas para devolverla a la imagen destino


	
	movd eax, xmm5	
	xor rdx,rdx		; limpio la parte alta del dividendo
	mov ecx, 600	; divido por 600 para normalizar la suma
	DIV ecx			; me deja en eax el resultado (es 255 o menos siempre,asi que solo ocupa al)

	
	push destino
	xor r15, r15
	
	mov r15d, filaActual
	IMUL r15d, width
	add r15d, colActual
	lea destino, [destino+r15]
	mov [destino], al 
	
	inc colActual
	pop destino
	
	
	
;						 Proceso los canales Gs

; vuelvo a duplicar los datos para no perderlos

	MOVDQA xmm5, xmm0
	;xmm5 = x|r0|r1|r2|r3|r4|g0|g1|g2|g3|g4|b0|b1|b2|b3|b4
	MOVDQA xmm6, xmm1
	MOVDQA xmm7, xmm2
	MOVDQA xmm8, xmm3
	MOVDQA xmm9, xmm4
	
	
	
	
;shifteo para poder desempaquetar en un solo registro
	; xmm5 = 0|0|x|r0|r1|r2|r3|r4|g0|g1|g2|g3|g4|b0|b1|b2|
	PSLLDQ xmm5, 2
	PSLLDQ xmm6, 2
	PSLLDQ xmm7, 2
	PSLLDQ xmm8, 2
	PSLLDQ xmm9, 2
	
	
	
;desempaqueto para trabajar en words y no perder precision.

	PUNPCKHBW xmm5, xmm15
	;xmm5 = g0|00|g1|00|g2|00|g3|00|g4|00|b0|00|b1|00|b2|00|
	PUNPCKHBW xmm6, xmm15
	PUNPCKHBW xmm7, xmm15
	PUNPCKHBW xmm8, xmm15
	PUNPCKHBW xmm9, xmm15
	
	
	
	
;shifteo para sacar la basura y acomodarlos para trabajar con la matriz
	PSLLDQ xmm5, 6
	PSRLDQ xmm5, 6
	;xmm5 = g0|00|g1|00|g2|00|g3|00|g4|00|00|00|00|00|00|00|
	
	PSLLDQ xmm6, 6
	PSRLDQ xmm6, 6
	
	PSLLDQ xmm7, 6
	PSRLDQ xmm7, 6
	
	PSLLDQ xmm8, 6
	PSRLDQ xmm8, 6
	
	PSLLDQ xmm9, 6
	PSRLDQ xmm9, 6
	
	
	
	
; multiplicamos por la matriz (solo nos interesa la parte baja de las multiplicaciones
; ya que tenemos todos los bytes mas significativos en 0, en xmm10 tengo la fila 1 y 5 de la matriz
; en xmm11 tengo las filas 2 y 4 de la matriz y en xmm12 tengo la fila 3 de la matriz.

	PMULLW xmm5, xmm10
	PMULLW xmm6, xmm11	
	PMULLW xmm7, xmm12
	PMULLW xmm8, xmm11
	PMULLW xmm9, xmm10
	
	
	
;sumo horizontalmente las filas
	PHADDW xmm5, xmm15		;xmm5 = r0+r1|r2+r3|r4+0|0+0|0+0|0+0|0+0|0+0
	PHADDW xmm6, xmm15
	PHADDW xmm7, xmm15
	PHADDW xmm8, xmm15
	PHADDW xmm9, xmm15
	
	
	;entiendo a double words para no perder precision en las sumas.
	
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


;paso a eax la suma de todas las filas para devolverla a la imagen destino
	
	
	movd eax, xmm5	
	xor rdx,rdx		; limpio la parte alta del dividendo
	mov ecx, 600	; normalizo el valor
	DIV ecx			; me deja en eax el resultado de la division(es 255 o menos siempre,asi que solo ocupa al)

	
	push destino
	xor r15, r15
	
	mov r15d, filaActual
	IMUL r15d, width
	add r15d, colActual
	lea destino, [destino+r15]
	mov [destino], al 
	
	inc colActual
	pop destino
	
	
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
	;xmm5 = |x|00|r0|00|r1|00|r2|00|r3|00|r4|00|g0|00|g1|00|
	PUNPCKLBW xmm6, xmm15
	PUNPCKLBW xmm7, xmm15
	PUNPCKLBW xmm8, xmm15
	PUNPCKLBW xmm9, xmm15
	
	
	
	
;shifteo para sacar la basura y acomodarlos para trabajar con la matriz
	PSLLDQ xmm5, 4
	PSRLDQ xmm5, 6
	;xmm5 = r0|00|r1|00|r2|00|r3|00|r4|00|00|00|00|00|00|00|
	
	PSLLDQ xmm6, 4
	PSRLDQ xmm6, 6
	
	PSLLDQ xmm7, 4
	PSRLDQ xmm7, 6
	
	PSLLDQ xmm8, 4
	PSRLDQ xmm8, 6
	
	PSLLDQ xmm9, 4
	PSRLDQ xmm9, 6
	
	
	
	
; multiplicamos por la matriz (solo nos interesa la parte baja de las multiplicaciones
; ya que tenemos todos los bytes mas significativos en 0.
	PMULLW xmm5, xmm10
	PMULLW xmm6, xmm11	
	PMULLW xmm7, xmm12
	PMULLW xmm8, xmm11
	PMULLW xmm9, xmm10
	
	
;sumo horizontalmente las filas
	PHADDW xmm5, xmm15		;xmm5 = r0+r1|r2+r3|r4+0|0+0|0+0|0+0|0+0|0+0 ?
	PHADDW xmm6, xmm15
	PHADDW xmm7, xmm15
	PHADDW xmm8, xmm15
	PHADDW xmm9, xmm15
	
	
	;extiendo a double words para no perder precision en las sumas
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
	




	
	
	movd eax, xmm5	
	xor rdx,rdx		; limpio la parte alta del dividendo
	mov ecx, 600	; normalizo la suma
	DIV ecx			; me deja en eax el resultado(es 255 o menos siempre,asi que solo ocupa al)

	
	push destino
	xor r15, r15
	
	mov r15d, filaActual
	IMUL r15d, width
	add r15d, colActual
	lea destino, [destino+r15]
	mov [destino], al 
	
	inc colActual
	pop destino
	
	
	
	;pregunto si llegue al final de la fila o si quedan pixeles por procesar
	xor rcx, rcx
	mov ecx, width
	sub ecx, 6
	CMP colActual, ecx
	JE miniature_asm_banda_arriba_fin_fila
	
	
	;levanto memoria para seguir procesando
	push fuente
	
	xor r15, r15
	mov r15d, filaActual
	sub r15d, 2							; r15d = filaActual-2
	IMUL r15d, width					; r15d = width * (filaActual-2)
	add r15d, colActual					; r15d = width * (filaActual-2) + colActual
	sub r15d, 7							; r15d = width * (filaActual-2) + colActual - 7
	
	lea fuente, [fuente+r15]					; apunto rdi a rdi+width * (filaActual-2) + colActual-6
	
	MOVDQU xmm0, [fuente]					; levanto 16 bytes (5 pixeles y un sobrante)
; xmm0 = basura|b0|g0|r0|b1|g1|r1|b2|g2|r2|b3|g3|r3|b4|g4|r4|

	lea fuente, [fuente+r9]				; Bajo una fila
	
	MOVDQU xmm1, [fuente]
	lea fuente, [fuente+r9]				; Bajo una fila
	
	MOVDQU xmm2, [fuente]
	lea fuente, [fuente+r9]				; Bajo una fila
	
	MOVDQU xmm3, [fuente]
	lea fuente, [fuente+r9]				; Bajo una fila
	
	MOVDQU xmm4, [fuente]
	
	pop fuente
	
	
;shuffleo para ordenar los datos para procesarlos despues, en xmm13 tengo la "mascara"

	PSHUFB xmm0, xmm13
	; xmm0 = 0|r0|r1|r2|r3|r4|g0|g1|g2|g3|g4|b0|b1|b2|b3|b4|
	PSHUFB xmm1, xmm13
	PSHUFB xmm2, xmm13
	PSHUFB xmm3, xmm13
	PSHUFB xmm4, xmm13
	

	jmp miniature_asm_banda_arriba_sigue_fila

miniature_asm_banda_arriba_fin_fila:
	;paso los ultimos 2 pixeles (6 canales) de la fila sin procesar.

	push fuente
	push destino
	
	xor r15,r15
	mov r15d, filaActual
	IMUL r15d, width
	add r15d, colActual 			; deberia ser width - 6 siempre
	
	lea destino, [destino + r15]
	lea fuente, [fuente + r15]
	
	movdqu xmm0, [fuente]
	movdqu [destino], xmm0
	
	pop destino
	pop fuente


	
	mov colActual, 0
	inc filaActual
	jmp miniature_asm_banda_arriba





;---------------------------------BANDA DEL MEDIO---------------------------------------
miniature_asm_banda_medio:

;pregunto si termine la banda del medio o si hay que seguir
	xor r15,r15
	mov r15d, heigth
	sub r15d, cantFilasAbajo
	
	
	cmp filaActual, r15d			;r15 = heigth - cantFilasAbajo
	JE miniature_asm_banda_abajo

	
miniature_asm_banda_medio_sigue_fila:
;paso 16 bytes sin tocarlos

	push fuente
	push destino
	
	xor r15, r15
	mov r15d, filaActual
	IMUL r15d, width
	add r15d, colActual
	
	lea fuente, [fuente+r15]
	lea destino, [destino+r15]
	
	movdqu xmm0, [fuente]
	movdqu [destino], xmm0
	
	
	pop destino
	pop fuente
	
	add colActual, 16
	
	cmp colActual, width
	
	JNE miniature_asm_banda_medio_sigue_fila
	

	
miniature_asm_banda_medio_fin_fila:
	mov colActual, 0
	inc filaActual
	
	jmp miniature_asm_banda_medio
	
	
	
;--------------------Borde banda abajo----------------------
	


miniature_asm_banda_abajo:
	mov r15d, heigth
	sub r15d, 2
	CMP filaActual, r15d
	JE miniature_asm_ultimas_2_filas
	
	
	
	push fuente
	push destino
	
	xor r15,r15
	mov r15d, filaActual
	IMUL r15d, width
	add r15d, colActual 			; deberia ser 0 siempre
	
	lea destino, [destino + r15]
	lea fuente, [fuente + r15]
	
	movdqu xmm0, [fuente]
	movdqu [destino], xmm0
	
	pop destino
	pop fuente
	
	mov colActual, 6
	
	
	
	
	
	
;---CODIGO REPETIDO
;levanto de memoria lo necesario para procesar el primer pixel de la fila
	
	push fuente
	xor r15, r15
	mov r15d, filaActual
	sub r15d, 2							; r15d = filaActual-2
	IMUL r15d, width					; r15d = width * (filaActual-2)
	add r15d, colActual					; r15d = width * (filaActual-2) + colActual
	sub r15d, 6							; r15d = width * (filaActual-2) + colActual - 6
	
	lea fuente, [fuente+r15]					; apunto rdi a rdi+width * (filaActual-2) + colActual-6
	
	MOVDQU xmm0, [fuente]					; levanto 16 bytes (5 pixeles y un sobrante)
; xmm0 = parte baja -> b0|g0|r0|b1|g1|r1|b2|g2|r2|b3|g3|r3|b4|g4|r4|basura
	lea fuente, [fuente+r9]				; Bajo una fila
	
	MOVDQU xmm1, [fuente]
	lea fuente, [fuente+r9]				; Bajo una fila
	
	MOVDQU xmm2, [fuente]
	lea fuente, [fuente+r9]				; Bajo una fila
	
	MOVDQU xmm3, [fuente]
	lea fuente, [fuente+r9]				; Bajo una fila
	
	MOVDQU xmm4, [fuente]
	
	pop fuente
	


;aplico pshufb con la "mascarita" en xmm14 para que me quede xmm = parte baja -> |x|r0|r1|r2|r3|r4|g0|g1|g2|g3|g4|b0|b1|b2|b3|b4|

;	PSHUFB xmm0, [mascarita]
	PSHUFB xmm0, xmm14		; xmm14 = mascarita
	PSHUFB xmm1, xmm14
	PSHUFB xmm2, xmm14
	PSHUFB xmm3, xmm14
	PSHUFB xmm4, xmm14
	
	
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
	;xmm5 = parte baja -> g2|00|g3|00|g4|00|b0|00|b1|00|b2|00|b3|00|b4|00|
	PUNPCKHBW xmm6, xmm15
	PUNPCKHBW xmm7, xmm15
	PUNPCKHBW xmm8, xmm15
	PUNPCKHBW xmm9, xmm15
	
	
	
	
;shifteo para sacar la basura y acomodarlos para trabajar con la matriz
	PSRLDQ xmm5, 6
	;xmm5 = b0|00|b1|00|b2|00|b3|00|b4|00|00|00|00|00|00|00|
	PSRLDQ xmm6, 6
	PSRLDQ xmm7, 6
	PSRLDQ xmm8, 6
	PSRLDQ xmm9, 6
	
	
; multiplicamos por la matriz (solo nos interesa la parte baja de las multiplicaciones
; ya que tenemos todos los bytes mas significativos en 0, en xmm10 tengo la fila 1 y 5 de la matriz
; en xmm11 tengo las filas 2 y 4 de la matriz y en xmm12 tengo la fila 3 de la matriz.
	PMULLW xmm5, xmm10
	PMULLW xmm6, xmm11	
	PMULLW xmm7, xmm12
	PMULLW xmm8, xmm11
	PMULLW xmm9, xmm10
	
	
	
;sumo horizontalmente las filas, en xmm15 tengo todos 0s
	PHADDW xmm5, xmm15		;xmm5 = r0+r1|r2+r3|r4+0|0+0|0+0|0+0|0+0|0+0 
	PHADDW xmm6, xmm15
	PHADDW xmm7, xmm15
	PHADDW xmm8, xmm15
	PHADDW xmm9, xmm15
	
	;extiendo a doubles para no perder precision en las sumas
	
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
	
	PHADDD xmm5, xmm15			; xmm5 = r0+r1+r2+r3+r4|0|0|0
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

;paso a eax la suma de todas las filas para devolverla a la imagen destino


	
	movd eax, xmm5	
	xor rdx,rdx		; limpio la parte alta del dividendo
	mov ecx, 600	; divido por 600 para normalizar la suma
	DIV ecx			; me deja en eax el resultado (es 255 o menos siempre,asi que solo ocupa al)

	
	push destino
	xor r15, r15
	
	mov r15d, filaActual
	IMUL r15d, width
	add r15d, colActual
	lea destino, [destino+r15]
	mov [destino], al 
	
	inc colActual
	pop destino
	
	
	
;						 Proceso los canales Gs

; vuelvo a duplicar los datos para no perderlos

	MOVDQA xmm5, xmm0
	;xmm5 = x|r0|r1|r2|r3|r4|g0|g1|g2|g3|g4|b0|b1|b2|b3|b4
	MOVDQA xmm6, xmm1
	MOVDQA xmm7, xmm2
	MOVDQA xmm8, xmm3
	MOVDQA xmm9, xmm4
	
	
	
	
;shifteo para poder desempaquetar en un solo registro
	; xmm5 = 0|0|x|r0|r1|r2|r3|r4|g0|g1|g2|g3|g4|b0|b1|b2|
	PSLLDQ xmm5, 2
	PSLLDQ xmm6, 2
	PSLLDQ xmm7, 2
	PSLLDQ xmm8, 2
	PSLLDQ xmm9, 2
	
	
	
;desempaqueto para trabajar en words y no perder precision.

	PUNPCKHBW xmm5, xmm15
	;xmm5 = g0|00|g1|00|g2|00|g3|00|g4|00|b0|00|b1|00|b2|00|
	PUNPCKHBW xmm6, xmm15
	PUNPCKHBW xmm7, xmm15
	PUNPCKHBW xmm8, xmm15
	PUNPCKHBW xmm9, xmm15
	
	
	
	
;shifteo para sacar la basura y acomodarlos para trabajar con la matriz
	PSLLDQ xmm5, 6
	PSRLDQ xmm5, 6
	;xmm5 = g0|00|g1|00|g2|00|g3|00|g4|00|00|00|00|00|00|00|
	
	PSLLDQ xmm6, 6
	PSRLDQ xmm6, 6
	
	PSLLDQ xmm7, 6
	PSRLDQ xmm7, 6
	
	PSLLDQ xmm8, 6
	PSRLDQ xmm8, 6
	
	PSLLDQ xmm9, 6
	PSRLDQ xmm9, 6
	
	
	
	
; multiplicamos por la matriz (solo nos interesa la parte baja de las multiplicaciones
; ya que tenemos todos los bytes mas significativos en 0, en xmm10 tengo la fila 1 y 5 de la matriz
; en xmm11 tengo las filas 2 y 4 de la matriz y en xmm12 tengo la fila 3 de la matriz.

	PMULLW xmm5, xmm10
	PMULLW xmm6, xmm11	
	PMULLW xmm7, xmm12
	PMULLW xmm8, xmm11
	PMULLW xmm9, xmm10
	
	
	
;sumo horizontalmente las filas
	PHADDW xmm5, xmm15		;xmm5 = r0+r1|r2+r3|r4+0|0+0|0+0|0+0|0+0|0+0
	PHADDW xmm6, xmm15
	PHADDW xmm7, xmm15
	PHADDW xmm8, xmm15
	PHADDW xmm9, xmm15
	
	
	;entiendo a double words para no perder precision en las sumas.
	
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


;paso a eax la suma de todas las filas para devolverla a la imagen destino
	
	
	movd eax, xmm5	
	xor rdx,rdx		; limpio la parte alta del dividendo
	mov ecx, 600	; normalizo el valor
	DIV ecx			; me deja en eax el resultado de la division(es 255 o menos siempre,asi que solo ocupa al)

	
	push destino
	xor r15, r15
	
	mov r15d, filaActual
	IMUL r15d, width
	add r15d, colActual
	lea destino, [destino+r15]
	mov [destino], al 
	
	inc colActual
	pop destino
	
	
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
	;xmm5 = |x|00|r0|00|r1|00|r2|00|r3|00|r4|00|g0|00|g1|00|
	PUNPCKLBW xmm6, xmm15
	PUNPCKLBW xmm7, xmm15
	PUNPCKLBW xmm8, xmm15
	PUNPCKLBW xmm9, xmm15
	
	
	
	
;shifteo para sacar la basura y acomodarlos para trabajar con la matriz
	PSLLDQ xmm5, 4
	PSRLDQ xmm5, 6
	;xmm5 = r0|00|r1|00|r2|00|r3|00|r4|00|00|00|00|00|00|00|
	
	PSLLDQ xmm6, 4
	PSRLDQ xmm6, 6
	
	PSLLDQ xmm7, 4
	PSRLDQ xmm7, 6
	
	PSLLDQ xmm8, 4
	PSRLDQ xmm8, 6
	
	PSLLDQ xmm9, 4
	PSRLDQ xmm9, 6
	
	
	
	
; multiplicamos por la matriz (solo nos interesa la parte baja de las multiplicaciones
; ya que tenemos todos los bytes mas significativos en 0.
	PMULLW xmm5, xmm10
	PMULLW xmm6, xmm11	
	PMULLW xmm7, xmm12
	PMULLW xmm8, xmm11
	PMULLW xmm9, xmm10
	
	
;sumo horizontalmente las filas
	PHADDW xmm5, xmm15		;xmm5 = r0+r1|r2+r3|r4+0|0+0|0+0|0+0|0+0|0+0 ?
	PHADDW xmm6, xmm15
	PHADDW xmm7, xmm15
	PHADDW xmm8, xmm15
	PHADDW xmm9, xmm15
	
	
	;extiendo a double words para no perder precision en las sumas
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
	




	
	
	movd eax, xmm5	
	xor rdx,rdx		; limpio la parte alta del dividendo
	mov ecx, 600	; normalizo la suma
	DIV ecx			; me deja en eax el resultado(es 255 o menos siempre,asi que solo ocupa al)

	
	push destino
	xor r15, r15
	
	mov r15d, filaActual
	IMUL r15d, width
	add r15d, colActual
	lea destino, [destino+r15]
	mov [destino], al 
	
	inc colActual
	pop destino
	
	
	
	;pregunto si llegue al final de la fila o si quedan pixeles por procesar
	xor rcx, rcx
	mov ecx, width
	sub ecx, 6
	CMP colActual, ecx
	JE miniature_asm_banda_abajo_fin_fila
	
	
	;levanto memoria para seguir procesando
	push fuente
	
	xor r15, r15
	mov r15d, filaActual
	sub r15d, 2							; r15d = filaActual-2
	IMUL r15d, width					; r15d = width * (filaActual-2)
	add r15d, colActual					; r15d = width * (filaActual-2) + colActual
	sub r15d, 7							; r15d = width * (filaActual-2) + colActual - 7
	
	lea fuente, [fuente+r15]					; apunto rdi a rdi+width * (filaActual-2) + colActual-6
	
	MOVDQU xmm0, [fuente]					; levanto 16 bytes (5 pixeles y un sobrante)
; xmm0 = basura|b0|g0|r0|b1|g1|r1|b2|g2|r2|b3|g3|r3|b4|g4|r4|

	lea fuente, [fuente+r9]				; Bajo una fila
	
	MOVDQU xmm1, [fuente]
	lea fuente, [fuente+r9]				; Bajo una fila
	
	MOVDQU xmm2, [fuente]
	lea fuente, [fuente+r9]				; Bajo una fila
	
	MOVDQU xmm3, [fuente]
	lea fuente, [fuente+r9]				; Bajo una fila
	
	MOVDQU xmm4, [fuente]
	
	pop fuente
	
	
;shuffleo para ordenar los datos para procesarlos despues, en xmm13 tengo la "mascara"

	PSHUFB xmm0, xmm13
	; xmm0 = 0|r0|r1|r2|r3|r4|g0|g1|g2|g3|g4|b0|b1|b2|b3|b4|
	PSHUFB xmm1, xmm13
	PSHUFB xmm2, xmm13
	PSHUFB xmm3, xmm13
	PSHUFB xmm4, xmm13
	

	jmp miniature_asm_banda_abajo_sigue_fila

miniature_asm_banda_abajo_fin_fila:
	;paso los ultimos 2 pixeles (6 canales) de la fila sin procesar.

	push fuente
	push destino
	
	xor r15,r15
	mov r15d, filaActual
	IMUL r15d, width
	add r15d, colActual 			; deberia ser width - 6 siempre
	
	lea destino, [destino + r15]
	lea fuente, [fuente + r15]
	
	movdqu xmm0, [fuente]
	movdqu [destino], xmm0
	
	pop destino
	pop fuente


	
	mov colActual, 0
	inc filaActual
	jmp miniature_asm_banda_abajo
	
;-----FIN CODIGO REPETIDO



;--------------Ultimas 2 filas------------------------------	
miniature_asm_ultimas_2_filas:
;paso las ultimas 2 filas de la imagen sin procesar


;pregunto si termine la imagen o si me quedan filas
	CMP filaActual, heigth
	JAE miniature_asm_fin_iteracion
	
	
miniature_asm_ultimas_2_filas_sigue_fila:
	
	;paso 16 bytes sin tocar
	push fuente
	push destino
	
	xor r15, r15
	mov r15d, filaActual
	IMUL r15d, width
	add r15d, colActual
	
	lea fuente, [fuente+r15]
	lea destino, [destino+r15]

	movdqu xmm0, [fuente]
	movdqu [destino], xmm0
	
	
	pop destino
	pop fuente
	
	add colActual, 16
	
	cmp colActual, width
	
	JNE miniature_asm_ultimas_2_filas_sigue_fila
	

	
miniature_asm_ultimas_2_filas_fin_fila:
	mov colActual, 0
	inc filaActual
	
	jmp miniature_asm_ultimas_2_filas

	
	
	
miniature_asm_fin_iteracion:
;termine la iteracion, actualizo el cantFilasAbajo y cantFilasArriba con los valores que calcule y pushie al principio.
	pop rcx
	pop rdx
	
	sub cantFilasArriba, ecx
	sub cantFilasAbajo, edx
	
	;vuelvo a pushear los valores para la proxima iteracion.
	push rdx
	push rcx
	
	
;swapeo los punteros asi conseguimos el efecto de aumentar el blurreado con varias iteraciones.
	
	mov rax, fuente
	mov fuente, destino	
	mov destino, rax
	
	mov filaActual, 0
	inc iterActual						; aumento el contador de iteraciones y vuelvo a iterar
	jmp miniature_asm_iterar



miniature_asm_fin:


	;popeo todo lo pusheado	
	pop rcx
	pop rdx
	pop rbx
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbp

	ret
