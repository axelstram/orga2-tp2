/*  topPlane:
        Numero entre 0 y 1 que representa el porcentaje de imagen desde el cual
        va a comenzar la primera iteración de blur (habia arriba)

    bottomPlane:
        Numero entre 0 y 1 que representa el porcentaje de imagen desde el cual
        va a comenzar la primera iteración de blur (hacia abajo)

    iters:
        Cantidad de iteraciones. Por cada iteración se reduce el tamaño de
        ventana que deben blurear, con el fin de generar un blur más intenso
        a medida que se aleja de la fila centro de la imagen.
*/
void miniature_c(
                unsigned char *src,
                unsigned char *dst,
                int width, int height,
                float topPlane, float bottomPlane,
                int iters) {

	float M[5][5];
	M[0][0] = 0.01;
	M[1][0] = 0.05;
	M[2][0] = 0.18;
	M[1][1] = 0.32;
	M[2][1] = 0.64;
	M[2][2] = 1;
	M[0][4] = M[0][0];
	M[4][0] = M[0][0];
	M[4][4] = M[0][0];
	M[0][1] = M[1][0];
	M[0][3] = M[1][0];
	M[1][4] = M[1][0];
	M[3][0] = M[1][0];
	M[3][4] = M[1][0];
	M[4][1] = M[1][0];
	M[4][3] = M[1][0];
	M[0][2] = M[2][0];
	M[2][4] = M[2][0];
	M[4][2] = M[2][0];
	M[1][3] = M[1][1];
	M[3][1] = M[1][1];
	M[3][3] = M[1][1];
	M[1][2] = M[2][1];
	M[3][2] = M[2][1];
	M[2][3] = M[2][1];
	int i = 0;
	int j = 0;
/*	while(i < 5){
		while(j < 5){
			printf("|%f|",M[i][j]);
			j++;
		}
		printf("\n");
		j = 0;
		i++;
	}
*/	i = 0;
	float sumatoria = 0;
	while(i < 5){
		while(j < 5){
			sumatoria = sumatoria + M[i][j];
			j++;
		}
		j = 0;
		i++;
	}

//	printf("%f\n",sumatoria);

	int cantFilasArriba = height * topPlane;
	int cantFilasAbajo = height - (height * bottomPlane);
	int reduccionFilasArriba = cantFilasArriba/iters;
	int reduccionFilasAbajo = cantFilasAbajo/iters;
	i = 0;
	int f = 0;
	int c = 0;
	width = width *3; //para trabajar canal por canal en vez de pixel por pixel.
	while(i < iters){
//		cantFilasArriba = cantFilasArriba - (i * cantFilasArriba / iters);
//		cantFilasAbajo = cantFilasAbajo - (i * cantFilasAbajo / iters);
		
/*		while(f < 2){
			while(c < width){
				dst[f*width+c] = src[f*width+c];
				c++;
			}
			c = 0;
			f++;
		} // f = 2 */
		while(c < width){
			dst[f*width+c] = src[f*width+c];
			c++;
		}
		f++;
		c = 0;
		while(c < width){
			dst[f*width+c] = src[f*width+c];
			c++;
		}
		f++;
		c = 0;
		
		while(f <= cantFilasArriba){
/*			while(c < 6){
				dst[f*width+c] = src[f*width+c];
				c++;
			}
*/			dst[f*width+c] = src[f*width+c];
			
			dst[f*width+c+1] = src[f*width+c+1];
			
			dst[f*width+c+2] = src[f*width+c+2];
			
			dst[f*width+c+3] = src[f*width+c+3];
			
			dst[f*width+c+4] = src[f*width+c+4];
			
			dst[f*width+c+5] = src[f*width+c+5];
			c = 6; // c = 6
						
			while(c < width-6){
				//proceso byte (f,c)
				//Armo matriz con subimagen alrededor de (f,c)
				unsigned char I[5][5];
				int x = 0;
				int y = 0;
/*				while(x < 5){
					while(y < 5){
						I[x][y] = src[(f+x-2) *width + c + (y-2) *3];
						y++;
					}
					y = 0;
					x++;
				}
*/				I[0][0] = src[(f+0-2) *width + c + (0-2) *3];
				I[0][1] = src[(f+0-2) *width + c + (1-2) *3];
				I[0][2] = src[(f+0-2) *width + c + (2-2) *3];
				I[0][3] = src[(f+0-2) *width + c + (3-2) *3];
				I[0][4] = src[(f+0-2) *width + c + (4-2) *3];

				I[1][0] = src[(f+1-2) *width + c + (0-2) *3];
				I[1][1] = src[(f+1-2) *width + c + (1-2) *3];
				I[1][2] = src[(f+1-2) *width + c + (2-2) *3];
				I[1][3] = src[(f+1-2) *width + c + (3-2) *3];
				I[1][4] = src[(f+1-2) *width + c + (4-2) *3];

				I[2][0] = src[(f+2-2) *width + c + (0-2) *3];
				I[2][1] = src[(f+2-2) *width + c + (1-2) *3];
				I[2][2] = src[(f+2-2) *width + c + (2-2) *3];
				I[2][3] = src[(f+2-2) *width + c + (3-2) *3];
				I[2][4] = src[(f+2-2) *width + c + (4-2) *3];
				
				I[3][0] = src[(f+3-2) *width + c + (0-2) *3];
				I[3][1] = src[(f+3-2) *width + c + (1-2) *3];
				I[3][2] = src[(f+3-2) *width + c + (2-2) *3];
				I[3][3] = src[(f+3-2) *width + c + (3-2) *3];
				I[3][4] = src[(f+3-2) *width + c + (4-2) *3];
				
				I[4][0] = src[(f+4-2) *width + c + (0-2) *3];
				I[4][1] = src[(f+4-2) *width + c + (1-2) *3];
				I[4][2] = src[(f+4-2) *width + c + (2-2) *3];
				I[4][3] = src[(f+4-2) *width + c + (3-2) *3];
				I[4][4] = src[(f+4-2) *width + c + (4-2) *3];
											

				//multiplico cada punto de la matriz con su correspondiente en M y almaceno en R de floats para no perder precision.
				float R[5][5];
				x = 0;
/*				while(x < 5){
					while(y < 5){
						R[x][y] = I[x][y] * M[x][y];
						y++;
					}
					y = 0;
					x++;
				}
*/				R[0][0] = I[0][0] * M[0][0];
				R[0][1] = I[0][1] * M[0][1];
				R[0][2] = I[0][2] * M[0][2];
				R[0][3] = I[0][3] * M[0][3];
				R[0][4] = I[0][4] * M[0][4];
				
				R[1][0] = I[1][0] * M[1][0];
				R[1][1] = I[1][1] * M[1][1];
				R[1][2] = I[1][2] * M[1][2];
				R[1][3] = I[1][3] * M[1][3];
				R[1][4] = I[1][4] * M[1][4];
				
				R[2][0] = I[2][0] * M[2][0];
				R[2][1] = I[2][1] * M[2][1];
				R[2][2] = I[2][2] * M[2][2];
				R[2][3] = I[2][3] * M[2][3];
				R[2][4] = I[2][4] * M[2][4];
				
				R[3][0] = I[3][0] * M[3][0];
				R[3][1] = I[3][1] * M[3][1];
				R[3][2] = I[3][2] * M[3][2];
				R[3][3] = I[3][3] * M[3][3];
				R[3][4] = I[3][4] * M[3][4];
				
				R[4][0] = I[4][0] * M[4][0];
				R[4][1] = I[4][1] * M[4][1];
				R[4][2] = I[4][2] * M[4][2];
				R[4][3] = I[4][3] * M[4][3];
				R[4][4] = I[4][4] * M[4][4];

				//Hago la suma de todos los productos
				x = 0;
				float suma = 0;
/*				while(x < 5){
					while(y < 5){
						suma = suma + R[x][y];
						y++;
					}
					y = 0;
					x++;
				}
*/				
				suma = suma + R[0][0];
				suma = suma + R[0][1];
				suma = suma + R[0][2];
				suma = suma + R[0][3];
				suma = suma + R[0][4];

				suma = suma + R[1][0];
				suma = suma + R[1][1];
				suma = suma + R[1][2];
				suma = suma + R[1][3];
				suma = suma + R[1][4];
				
				suma = suma + R[2][0];
				suma = suma + R[2][1];
				suma = suma + R[2][2];
				suma = suma + R[2][3];
				suma = suma + R[2][4];
				
				suma = suma + R[3][0];
				suma = suma + R[3][1];
				suma = suma + R[3][2];
				suma = suma + R[3][3];
				suma = suma + R[3][4];
				
				suma = suma + R[4][0];
				suma = suma + R[4][1];
				suma = suma + R[4][2];
				suma = suma + R[4][3];
				suma = suma + R[4][4];

				suma = suma/sumatoria;
				unsigned char resultado;
				resultado = (unsigned char) suma;
				dst[f*width + c] = resultado;

				c++;
			}
			
/*			while(c < width){
				dst[f*width+c] = src[f*width+c];
				c++;
			}
*/			
			dst[f*width+c] = src[f*width+c];
			
			dst[f*width+c+1] = src[f*width+c+1];
			
			dst[f*width+c+2] = src[f*width+c+2];
			
			dst[f*width+c+3] = src[f*width+c+3];
			
			dst[f*width+c+4] = src[f*width+c+4];
			
			dst[f*width+c+5] = src[f*width+c+5];
			
			c = 0;
			f++;
		} // f == cantFilasArriba
		
// BANDA DEL MEDIO

		while(f < height - cantFilasAbajo){
			while(c < width){
				dst[f*width+c] = src[f*width+c];
				c++;
			}
			c = 0;
			f++;
		} // f == height - cantFilasAbajo

		
// BANDA DE ABAJO
		//f = height - cantFilasAbajo y c = 0
		while(f < height-2){
/*			while(c < 6){
				dst[f*width+c] = src[f*width+c];
				c++;
			}
*/			dst[f*width+c] = src[f*width+c];
			
			dst[f*width+c+1] = src[f*width+c+1];
			
			dst[f*width+c+2] = src[f*width+c+2];
			
			dst[f*width+c+3] = src[f*width+c+3];
			
			dst[f*width+c+4] = src[f*width+c+4];
			
			dst[f*width+c+5] = src[f*width+c+5];
			c = 6;
			
			while(c < width-6){
				//proceso byte (f,c)
				//Armo matriz con subimagen alrededor de (f,c)
				unsigned char I[5][5];
				int x = 0;
				int y = 0;
				
				
	/*			while(x < 5){
					while(y < 5){
						I[x][y] = src[(f+x-2) *width + c + (y-2)*3];
						y++;
					}
					y = 0;
					x++;
				}
		*/		
				I[0][0] = src[(f+0-2) *width + c + (0-2) *3];
				I[0][1] = src[(f+0-2) *width + c + (1-2) *3];
				I[0][2] = src[(f+0-2) *width + c + (2-2) *3];
				I[0][3] = src[(f+0-2) *width + c + (3-2) *3];
				I[0][4] = src[(f+0-2) *width + c + (4-2) *3];

				I[1][0] = src[(f+1-2) *width + c + (0-2) *3];
				I[1][1] = src[(f+1-2) *width + c + (1-2) *3];
				I[1][2] = src[(f+1-2) *width + c + (2-2) *3];
				I[1][3] = src[(f+1-2) *width + c + (3-2) *3];
				I[1][4] = src[(f+1-2) *width + c + (4-2) *3];

				I[2][0] = src[(f+2-2) *width + c + (0-2) *3];
				I[2][1] = src[(f+2-2) *width + c + (1-2) *3];
				I[2][2] = src[(f+2-2) *width + c + (2-2) *3];
				I[2][3] = src[(f+2-2) *width + c + (3-2) *3];
				I[2][4] = src[(f+2-2) *width + c + (4-2) *3];
				
				I[3][0] = src[(f+3-2) *width + c + (0-2) *3];
				I[3][1] = src[(f+3-2) *width + c + (1-2) *3];
				I[3][2] = src[(f+3-2) *width + c + (2-2) *3];
				I[3][3] = src[(f+3-2) *width + c + (3-2) *3];
				I[3][4] = src[(f+3-2) *width + c + (4-2) *3];
				
				I[4][0] = src[(f+4-2) *width + c + (0-2) *3];
				I[4][1] = src[(f+4-2) *width + c + (1-2) *3];
				I[4][2] = src[(f+4-2) *width + c + (2-2) *3];
				I[4][3] = src[(f+4-2) *width + c + (3-2) *3];
				I[4][4] = src[(f+4-2) *width + c + (4-2) *3];

				//multiplico cada punto de la matriz con su correspondiente en M y almaceno en R de floats para no perder precision.
				float R[5][5];
				x = 0;
/*				while(x < 5){
					while(y < 5){
						R[x][y] = I[x][y] * M[x][y];
						y++;
					}
					y = 0;
					x++;
				}
*/
				R[0][0] = I[0][0] * M[0][0];
				R[0][1] = I[0][1] * M[0][1];
				R[0][2] = I[0][2] * M[0][2];
				R[0][3] = I[0][3] * M[0][3];
				R[0][4] = I[0][4] * M[0][4];
				
				R[1][0] = I[1][0] * M[1][0];
				R[1][1] = I[1][1] * M[1][1];
				R[1][2] = I[1][2] * M[1][2];
				R[1][3] = I[1][3] * M[1][3];
				R[1][4] = I[1][4] * M[1][4];
				
				R[2][0] = I[2][0] * M[2][0];
				R[2][1] = I[2][1] * M[2][1];
				R[2][2] = I[2][2] * M[2][2];
				R[2][3] = I[2][3] * M[2][3];
				R[2][4] = I[2][4] * M[2][4];
				
				R[3][0] = I[3][0] * M[3][0];
				R[3][1] = I[3][1] * M[3][1];
				R[3][2] = I[3][2] * M[3][2];
				R[3][3] = I[3][3] * M[3][3];
				R[3][4] = I[3][4] * M[3][4];
				
				R[4][0] = I[4][0] * M[4][0];
				R[4][1] = I[4][1] * M[4][1];
				R[4][2] = I[4][2] * M[4][2];
				R[4][3] = I[4][3] * M[4][3];
				R[4][4] = I[4][4] * M[4][4];

				//Hago la suma de todos los productos
				x = 0;
				float suma = 0;
/*				while(x < 5){
					while(y < 5){
						suma = suma + R[x][y];
						y++;
					}
					y = 0;
					x++;
				}
*/				
				suma = suma + R[0][0];
				suma = suma + R[0][1];
				suma = suma + R[0][2];
				suma = suma + R[0][3];
				suma = suma + R[0][4];

				suma = suma + R[1][0];
				suma = suma + R[1][1];
				suma = suma + R[1][2];
				suma = suma + R[1][3];
				suma = suma + R[1][4];
				
				suma = suma + R[2][0];
				suma = suma + R[2][1];
				suma = suma + R[2][2];
				suma = suma + R[2][3];
				suma = suma + R[2][4];
				
				suma = suma + R[3][0];
				suma = suma + R[3][1];
				suma = suma + R[3][2];
				suma = suma + R[3][3];
				suma = suma + R[3][4];
				
				suma = suma + R[4][0];
				suma = suma + R[4][1];
				suma = suma + R[4][2];
				suma = suma + R[4][3];
				suma = suma + R[4][4];

				suma = suma/sumatoria;
				unsigned char resultado = (unsigned char) suma;

				dst[f*width + c] = resultado;


				c++;
			}
			
/*			while(c < width){
				dst[f*width+c] = src[f*width+c];
				c++;
			}
*/			
			
			dst[f*width+c] = src[f*width+c];
			
			dst[f*width+c+1] = src[f*width+c+1];
			
			dst[f*width+c+2] = src[f*width+c+2];
			
			dst[f*width+c+3] = src[f*width+c+3];
			
			dst[f*width+c+4] = src[f*width+c+4];
			
			dst[f*width+c+5] = src[f*width+c+5];
			
			c = 0;
			f++;
		} // f = heigth -2
		
	
/*		while(f < height){
			while(c < width){
				dst[f*width+c] = src[f*width+c];
				c++;
			}
			c = 0;
			f++;
		}
*/		
		while(c < width){
			dst[f*width+c] = src[f*width+c];
			c++;
		}
		f++;
		c = 0;
		while(c < width){
			dst[f*width+c] = src[f*width+c];
			c++;
		}
		f++;
		c = 0;

		cantFilasArriba = cantFilasArriba - reduccionFilasArriba;
		cantFilasAbajo = cantFilasAbajo - reduccionFilasAbajo;
		
		
		f = 0;
		unsigned char* temp;
		temp = dst;
		dst = src;
		src = temp;
		i++;
	} //while

}
