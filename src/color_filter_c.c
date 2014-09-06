#include <stdio.h>
#include <stdlib.h>
#include <math.h>

//Prototipo
int distancia(unsigned char* pixel, unsigned char* coloresParametro);
short min(short maxColorPermitido, short colorNuevo);

void color_filter_c(unsigned char *src,
                    unsigned char *dst,
                    unsigned char rc,
                    unsigned char gc,
                    unsigned char bc,
                    int threshold,
                    int width,
                    int height)
{
	//1 pixel = 3 bytes
	
	//Calculo la cantidad de bytes que tiene la imagen
	int cantBytesImagen = 3 * width * height;
	int cantBytesRecorridos;
	unsigned char pixel[3];
	int i;
	
	//Creo un arreglo con los colores que me pasan por parametro.
	unsigned char coloresParametro[3];
	coloresParametro[0] = bc;
	coloresParametro[1] = gc;
	coloresParametro[2] = rc;

	
	//for (cantBytesRecorridos = 0; cantBytesRecorridos <= cantBytesImagen - 3 ; cantBytesRecorridos+=3) {
	for (int i = 0; i < width; i++) {
		for (int j = 0; j< height; j++) {
		

		//Levanto un pixel
		for (int k = 0; k <= 2; k++) {

			pixel[k] = *src;
			src++;
				
		}

		
		if (distancia(pixel, coloresParametro) >= threshold) {
			//Actualizo el color
			short pixel0 = (short) pixel[0];
			short pixel1 = (short) pixel[1];
			short pixel2 = (short) pixel[2];
			
			short colorDestino = (pixel0 + pixel1 + pixel2) / 3;

			//colorDestino = min(255, colorDestino);
			pixel[0] = (unsigned char) colorDestino;
			pixel[1] = (unsigned char) colorDestino;
			pixel[2] = (unsigned char) colorDestino;
			
		}
		//En otro caso, queda el mismo color que habia antes en el pixel.
		
		//Guardo los pixeles filtrados.	
		
		*dst= pixel[0];
		dst++;
		*dst = pixel[1];
		dst++;
		*dst = pixel[2];
		dst++;

				
		} //for

	}
	
}



int distancia(unsigned char* pixel, unsigned char* coloresParametro) {

	//Color azul del pixel
	int b = (int) pixel[0];
	//Color verde del pixel
	int g = (int) pixel[1];
	//Color rojo del pixel
	int r = (int) pixel[2];
	
	b = b - ((int) coloresParametro[0]); 	//b = b - bc
	g = g - ((int) coloresParametro[1]); 	//g = g - gc
	r = r - ((int) coloresParametro[2]);	//r = r - rc
	
	b = b * b;
	g = g * g;
	r = r * r;
	
	int suma = b + g + r;
	
	float raiz = sqrt(((float) suma) - 0.5);
	
	int res = ((int) trunc(raiz));				
	
	return res;
	
} 


short min(short maxColorPermitido, short colorNuevo) {
	
	short colorFinal;
	
	if (colorNuevo > maxColorPermitido) {
		
		colorFinal = maxColorPermitido;
		
	} else {
		
		colorFinal = colorNuevo;
		
	}
	
	return colorFinal;
	
}
		
	
	
	
