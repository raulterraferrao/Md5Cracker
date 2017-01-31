#include <stdio.h>
#include <time.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>

#include "md5.cu"

#define THREADS_PER_BLOCK 128
#define BLOCKS 1024
#define MAX_STR_LENGTH 16
#define TAM_HASH 33
#define TAM_ALFABETO 26
#define MAX_HASH_PER_KERNEL 8192
#define MIN_HASH_PER_KERNEL 256


#define CONST_CHARSET "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
#define CONST_CHARSET_LENGTH (sizeof(CONST_CHARSET) - 1)



#define cudaCheckErrors(msg) \
    do { \
        cudaError_t __err = cudaGetLastError(); \
        if (__err != cudaSuccess) { \
            fprintf(stderr, "Fatal error: %s (%s at %s:%d)\n", \
                msg, cudaGetErrorString(__err), \
                __FILE__, __LINE__); \
            fprintf(stderr, "*** FAILED - ABORTING\n"); \
            exit(1); \
        } \
    } while (0)


struct DeviceReturnStruct{

	int a;

};

__device__ uint d_unhex(unsigned char x)
{
    if(x <= 'F' && x >= 'A')
    {
        return  (uint)(x - 'A' + 10);
    }
    else if(x <= 'f' && x >= 'a')
    {
        return (uint)(x - 'a' + 10);
    }
    else if(x <= '9' && x >= '0')
    {
        return (uint)(x - '0');
    }
    return 0;
}

__device__ void d_md5_to_ints(unsigned char* md5, uint *r0, uint *r1, uint *r2, uint *r3)
{
    uint v0 = 0, v1 = 0, v2 = 0, v3 = 0;
    int i = 0;
    for(i = 0; i < 32; i+=2)
    {
        uint first = d_unhex(md5[i]);
        uint second = d_unhex(md5[i+1]);
        uint both = first * 16 + second;
        both = both << 24;
        if(i < 8)
        {
            v0 = (v0 >> 8 ) | both;
        }
        else if (i < 16)
        {
            v1 = (v1 >> 8) | both;
        }
        else if (i < 24)
        {
            v2 = (v2 >> 8) | both;
        }
        else if(i < 32)
        {
            v3 = (v3 >> 8) | both;
        }
    }

    *r0 = v0;
    *r1 = v1;
    *r2 = v2;
    *r3 = v3;
}

__device__ inline int my_strlen(char* str){
	int i = 0;
	while(str[i++] != '\0');
	return --i;
}

int host_my_strlen(char* str){
    int i = 0;
    while(str[i++] != '\0');
    return --i;
}


__device__ void my_strcpy(unsigned char *dest, const unsigned char *src){
  int i = 0;
  do {
    dest[i] = src[i];}
  while (src[i++] != '\0');
}


//This function transform the respective number that is passed as numeroEntrada to a string with the chars of charset

__device__ void converter(ulong numeroEntrada, unsigned char str[MAX_STR_LENGTH],char* charset)
{
            int size;
            size = my_strlen(charset);


            int i = 0;  // To store current index in str which is result

	while (numeroEntrada>0)
	{
		// Find remainder
		ulong rem = numeroEntrada%size;

		// If remainder is 0, then a 'Z' must be there in output
		if (rem==0)
		{
			str[i++] = charset[size-1];
			numeroEntrada = (numeroEntrada/size)-1;
		}
		else // If remainder is non-zero
		{
			str[i++] = charset[(rem-1)];
			numeroEntrada = numeroEntrada/size;
		}
	}
	str[i] = '\0';



}

__global__ void crack(unsigned char *password, ulong* starting_number , uint* d_current_hash_per_kernel ,volatile int* flag ,uint* d_v1, uint* d_v2, uint* d_v3, uint* d_v4 ,char* charset, DeviceReturnStruct *device_return)
{
	const ulong thread_per_block = THREADS_PER_BLOCK;
	const ulong blocks = BLOCKS;
	const ulong step = thread_per_block * blocks;

	const uint v1 = *d_v1;
	const uint v2 = *d_v2;
	const uint v3 = *d_v3;
	const uint v4 = *d_v4;

            int size;
            size = my_strlen(charset);

	const uint current_hash_per_kernel = *d_current_hash_per_kernel;

	unsigned char palavra[MAX_STR_LENGTH] = "";

	int count = 0;
	int totalLen;
	uint c1 = 0, c2 = 0, c3 = 0, c4 = 0;
	ulong len;

	ulong blockIdxx = blockIdx.x;
	ulong blockDimx = blockDim.x;
	ulong threadIdxx = threadIdx.x;


	ulong idx = (blockIdxx*blockDimx + threadIdxx) + *starting_number;

	while(*flag != 1 && count++ < current_hash_per_kernel ){
		totalLen = 1;
		len = idx /(size + 1);
		while(len > 0){
			len /= (size + 1);
			totalLen++;
		}

		converter(idx, palavra,charset);
		md5_vfy(palavra,totalLen, &c1, &c2, &c3, &c4);

		if(c1 == v1 && c2 == v2 && c3 == v3 && c4 == v4)
		{
			my_strcpy(password,palavra);
			*flag = 1;
		}

		idx += step;

	}

}

void h_converter(ulong numeroEntrada, unsigned char pointerPalavra[][255],char* charset)
{
	int size;
             size = host_my_strlen(charset);

            unsigned char* str = *pointerPalavra;  // To store result (Excel column name)
	int i = 0;  // To store current index in str which is result

	while (numeroEntrada>0)
	{
		// Find remainder
		ulong rem = numeroEntrada%size;

		// If remainder is 0, then a 'Z' must be there in output
		if (rem==0)
		{
			str[i++] = charset[size-1];
			numeroEntrada = (numeroEntrada/size)-1;
		}
		else // If remainder is non-zero
		{
			str[i++] = charset[(rem-1)];
			numeroEntrada = numeroEntrada/size;
		}
	}
	str[i] = '\0';

}

void n_converter(ulong numeroEntrada, unsigned char pointerPalavra[][255],char* charset)
{
    int size;
    size = host_my_strlen(charset);
    printf("%d",size);

    unsigned char* str = *pointerPalavra;  // To store result (Excel column name)
    int i = 0;  // To store current index in str which is result

    while (numeroEntrada>0)
    {
        // Find remainder
        ulong rem = numeroEntrada%size;

        // If remainder is 0, then a 'Z' must be there in output
        if (rem==0)
        {
            str[i++] = charset[size-1];
            numeroEntrada = (numeroEntrada/size)-1;
        }
        else // If remainder is non-zero
        {
            str[i++] = charset[(rem-1)];
            numeroEntrada = numeroEntrada/size;
        }
    }
    str[i] = '\0';

}

int main(int argc,  char *argv[]){

	/*======================================
                RESPECTIVE NUMBERS OF CHARSET
            ========================================

            0: a-z
            1: A-Z
            2: 0-9
            3: a-z A-Z
            4: a-z 0-9
            5: A-Z 0-9
            6: a-z A-z 0-9

            */
            char *charset,*d_charset;
            int charset_choice,charset_flag = 0,hash_flag = 0;
            unsigned char hash_entrada[TAM_HASH];
            //unsigned char teste[255] = "";
            //ulong testenumero;

            unsigned char *d_password;
	ulong* d_starting_number;
	ulong h_starting_number = 0;
	int *d_flag;
	int h_flag = 0;
	unsigned char h_password[MAX_STR_LENGTH] = "";

	uint v1,v2,v3,v4;
	uint *d_v1, *d_v2, *d_v3, *d_v4;
	DeviceReturnStruct h_device_return, *d_device_return;


	uint h_current_hash_per_kernel = MIN_HASH_PER_KERNEL;
	uint* d_current_hash_per_kernel;

             printf("\n\nCuda Md5 Brute Force Cracker - made by: Raul Terra Ferrão & Victor Terra Ferrão\n\n");

              do{
                     printf("------- Please paste the md5 hash below -------\n\n");
                     scanf("%s",hash_entrada);
                     (host_my_strlen((char*)hash_entrada) != 32 ) ? (printf("\n\nYour md5 hash is wrong, it must be 32 char length \n\n")) : (hash_flag=1);
            }while(hash_flag == 0);

             printf("\nThe hash is : %s\n\n",hash_entrada);

             do{
                     printf("------- Please choose the number of the charset that you want -------\n");
                     printf("0: a-z\n");
                     printf("1: A-Z\n");
                     printf("2: 0-9\n");
                     printf("3: a-z A-Z\n");
                     printf("4: a-z 0-9\n");
                     printf("5: A-Z 0-9\n");
                     printf("6: a-z A-z 0-9\n");
                     printf("----------------------------------------------------------------------\n\n");
                     scanf("%d",&charset_choice);
                     (charset_choice > 6 ||  charset_choice < 0 ) ? (printf("\n\nYou need to write a number between 0 and 6\n\n")) : (charset_flag=1);
             }while(charset_flag == 0);

             printf("The number of charset is : %d\n\n",charset_choice);

             switch(charset_choice){

                case 0:
                      charset =  (char*) malloc (sizeof (char) * 26);
                      strcpy (charset,"abcdefghijklmnopqrstuvwxyz");
                      cudaMalloc( (void**)&d_charset, sizeof(char) * 26);
                      cudaCheckErrors("d_charset");
                      cudaMemcpy( d_charset, charset, sizeof(char) * 26, cudaMemcpyHostToDevice);
                      printf("%s\n",charset);
                break;
                case 1:
                      charset =  (char*) malloc (sizeof (char) * 26);
                      strcpy (charset,"ABCDEFGHIJKLMNOPQRSTUVWXYZ");
                      cudaMalloc( (void**)&d_charset, sizeof(char) * 26);
                      cudaCheckErrors("d_charset");
                      cudaMemcpy( d_charset, charset, sizeof(char) * 26, cudaMemcpyHostToDevice);
                      printf("%s\n",charset);
                break;
                case 2:
                      charset =  (char*) malloc (sizeof (char) * 10);
                      strcpy (charset,"0123456789");
                      cudaMalloc( (void**)&d_charset, sizeof(char) * 10);
                      cudaCheckErrors("d_charset");
                      cudaMemcpy( d_charset, charset, sizeof(char) * 10, cudaMemcpyHostToDevice);
                      printf("%s\n",charset);
                break;
                case 3:
                      charset =  (char*) malloc (sizeof (char) * 52);
                      strcpy (charset,"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ");
                      cudaMalloc( (void**)&d_charset, sizeof(char) * 52);
                      cudaCheckErrors("d_charset");
                      cudaMemcpy( d_charset, charset, sizeof(char) * 52, cudaMemcpyHostToDevice);
                      printf("%s\n",charset);
                break;
                case 4:
                      charset =  (char*) malloc (sizeof (char) * 36);
                      strcpy (charset,"abcdefghijklmnopqrstuvwxyz0123456789");
                      cudaMalloc( (void**)&d_charset, sizeof(char) * 36);
                      cudaCheckErrors("d_charset");
                      cudaMemcpy( d_charset, charset, sizeof(char) * 36, cudaMemcpyHostToDevice);
                      printf("%s\n",charset);
                break;
                case 5:
                      charset =  (char*) malloc (sizeof (char) * 36);
                      strcpy (charset,"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789");
                      cudaMalloc( (void**)&d_charset, sizeof(char) * 36);
                      cudaCheckErrors("d_charset");
                      cudaMemcpy( d_charset, charset, sizeof(char) * 36, cudaMemcpyHostToDevice);
                      printf("%s\n",charset);
                break;
                case 6:
                      charset =  (char*) malloc (sizeof (char) * 62);
                      strcpy (charset,"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789");
                      cudaMalloc( (void**)&d_charset, sizeof(char) * 62);
                      cudaCheckErrors("d_charset");
                      cudaMemcpy( d_charset, charset, sizeof(char) * 62, cudaMemcpyHostToDevice);
                      printf("%s\n",charset);
                break;
             }

            md5_to_ints((unsigned char*)hash_entrada,&v1,&v2,&v3,&v4);
            //printf("v1,v2,v3,v4 %u,%u,%u,%u\n",v1,v2,v3,v4);



	cudaMalloc( (void**)&d_password, MAX_STR_LENGTH*sizeof(unsigned char));
	cudaCheckErrors("d_password");
	cudaMalloc( (void**)&d_flag, sizeof(int));
	cudaCheckErrors("d_flag");
	cudaMalloc( (void**)&d_starting_number, sizeof(ulong));
	cudaCheckErrors("d_starting_number");
	cudaMalloc( (void**)&d_v1, sizeof(uint));
	cudaCheckErrors("d_v1");
	cudaMalloc( (void**)&d_v2, sizeof(uint));
	cudaCheckErrors("d_v2");
	cudaMalloc( (void**)&d_v3, sizeof(uint));
	cudaCheckErrors("d_v3");
	cudaMalloc( (void**)&d_v4, sizeof(uint));
	cudaCheckErrors("d_v4");
	cudaMalloc( (void**)&d_current_hash_per_kernel, sizeof(uint));
	cudaCheckErrors("d_current_hash_per_kernel");



	cudaMalloc( (void**)&d_current_hash_per_kernel, sizeof(uint));
	cudaMalloc( (void**)&d_device_return, sizeof(DeviceReturnStruct));


	if(d_password ==0  || d_flag ==0)
	{
      printf("couldn't allocate memory\n");
      return 1;
	}

	cudaMemcpy( d_flag, &h_flag, sizeof(int),  cudaMemcpyHostToDevice);
	cudaCheckErrors("cudaMemcpy( d_flag, &h_flag,sizeof(int),  cudaMemcpyHostToDevice);");
	cudaMemcpy( d_starting_number, &h_starting_number, sizeof(ulong), cudaMemcpyHostToDevice);
	cudaCheckErrors("cudaMemset( d_starting_number, 0,sizeof(int) );");
	cudaDeviceSynchronize();
	cudaCheckErrors("cudaDeviceSynchronize();");

	cudaMemcpy( d_v1, &v1, sizeof(uint), cudaMemcpyHostToDevice);
	cudaMemcpy( d_v2, &v2, sizeof(uint), cudaMemcpyHostToDevice);
	cudaMemcpy( d_v3, &v3, sizeof(uint), cudaMemcpyHostToDevice);
	cudaMemcpy( d_v4, &v4, sizeof(uint), cudaMemcpyHostToDevice);
	cudaMemcpy( d_password, h_password, MAX_STR_LENGTH*sizeof(unsigned char), cudaMemcpyHostToDevice);
	cudaMemcpy( d_current_hash_per_kernel, &h_current_hash_per_kernel, sizeof(uint), cudaMemcpyHostToDevice);
	cudaMemcpy( d_device_return, &h_device_return, sizeof(DeviceReturnStruct), cudaMemcpyHostToDevice);


	//run the kernel
	dim3 dimGrid(BLOCKS);
	dim3 dimBlock(THREADS_PER_BLOCK);
	ulong blocks = BLOCKS;
	ulong threads_per_block = THREADS_PER_BLOCK;
	ulong currentNumber = 0;

	int i = 0, count = 0;
	unsigned char palavra[255] = "";
	while(h_flag != 1){
		crack<<<dimGrid, dimBlock>>>(d_password, d_starting_number , d_current_hash_per_kernel ,d_flag, d_v1, d_v2, d_v3, d_v4,d_charset, d_device_return);
		cudaCheckErrors("crack");
		//cudaCheckErrors("cudaDeviceSynchronize();");
		cudaMemcpy( &h_flag, d_flag,sizeof(int), cudaMemcpyDeviceToHost );
		//cudaCheckErrors("cudaMemcpy( &h_flag, d_flag,sizeof(int), cudaMemcpyDeviceToHost )");


		//cudaCheckErrors("cudaMemcpy( d_starting_number, &h_starting_number, sizeof(ulong), cudaMemcpyHostToDevice );");
		currentNumber = h_starting_number;
		h_starting_number += threads_per_block*blocks*h_current_hash_per_kernel;
		h_current_hash_per_kernel = h_current_hash_per_kernel + MIN_HASH_PER_KERNEL;
		if(h_current_hash_per_kernel  > MAX_HASH_PER_KERNEL){
			h_current_hash_per_kernel = MAX_HASH_PER_KERNEL;
		}
		h_converter(currentNumber, &palavra,charset);

		if(count++%1 == 0){
			printf("i = %d, number = %lu, palavra = %s\n",i, currentNumber, palavra);
			//printf("hash_entrada = %s\n",argv[1]);
		}

		cudaMemcpy( d_current_hash_per_kernel, &h_current_hash_per_kernel, sizeof(uint), cudaMemcpyHostToDevice );
		cudaMemcpy( d_starting_number, &h_starting_number, sizeof(ulong), cudaMemcpyHostToDevice );

		i++;
	}
	//cudaCheckErrors("cudaMemcpy( hash_entrada, d_hash_entrada,num_bytes, cudaMemcpyDeviceToHost );");
	cudaMemcpy( h_password, d_password, MAX_STR_LENGTH, cudaMemcpyDeviceToHost );
	//cudaCheckErrors("cudaMemcpy( h_password, d_password,num_bytes*2, cudaMemcpyDeviceToHost );");


	printf("---------------------------------------\n");
	printf("Password = %s\n",h_password);
	printf("Flag %d \n", h_flag );


	 cudaFree( d_password);
	 cudaFree( d_flag);
	 cudaFree( d_starting_number);
	 cudaFree( d_v1);
	 cudaFree( d_v2);
	 cudaFree( d_v3);
	 cudaFree( d_v4);
	 cudaFree( d_device_return);


	return 0;
}

