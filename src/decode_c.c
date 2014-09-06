#include <stdio.h>

void decode_c(unsigned char* src,
              unsigned char* code,
			  int size,
              int width,
              int height)
{
	unsigned char charDecodificado;
	unsigned char caracter[4];
		
	int pos = 0;
	int cantBytesImagen = 3 * width * height;
	int cantBytesRecorridos;
	
				
	for (cantBytesRecorridos = 0; cantBytesRecorridos <= cantBytesImagen - 4; cantBytesRecorridos+=4) {
	
		int i;
			
		if (size >= 0) {
			
			for(i = 0; i <= 3; i++) {
			
				//Levanto 1 byte (termino levantando 4 al final, o sea, un caracter).
				caracter[i] = src[cantBytesRecorridos+i];
			
				//Me quedo con los 4 bits menos significativos.
				caracter[i] = caracter[i] & 0x0f;
	
				//Caso byte = 00 queda igual
				//Caso byte = 01
				if (caracter[i] >= 4 && caracter[i] < 8) {
				
					caracter[i] = ++caracter[i];
								
				} else if (caracter[i] >= 8 && caracter[i] < 12) {
				
					caracter[i] = --caracter[i];
								
				} else if (caracter[i] >= 12) {
				
					caracter[i] = ~caracter[i];
								
				}
				
				caracter[i] = caracter[i] & 0x03;	//Me quedo con los 2 bits menos significativos.
			
			} //for
			
			//Shifteo a izquierda
			caracter[3] = caracter[3] << 6;
			caracter[2] = caracter[2] << 4;
			caracter[1] = caracter[1] << 2;
			charDecodificado = caracter[0] + caracter[1] + caracter[2] + caracter[3];		
					
			code[pos] = charDecodificado;
		
			size--;
			pos++;

		}//if
		
	} //for

}
