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

__device__ inline int my_strlen(unsigned char* str){
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

__device__ void converter(ulong numeroEntrada, unsigned char str[MAX_STR_LENGTH])
{
	int i = 0;  // To store current index in str which is result

	while (numeroEntrada>0)
	{
		// Find remainder
		ulong rem = numeroEntrada%26;

		// If remainder is 0, then a 'Z' must be there in output
		if (rem==0)
		{
			str[i++] = 'z';
			numeroEntrada = (numeroEntrada/26)-1;
		}
		else // If remainder is non-zero
		{
			str[i++] = (rem-1) + 'a';
			numeroEntrada = numeroEntrada/26;
		}
	}
	str[i] = '\0';



}

__global__ void crack(unsigned char *password, ulong* starting_number , uint* d_current_hash_per_kernel ,volatile int* flag ,uint* d_v1, uint* d_v2, uint* d_v3, uint* d_v4 , DeviceReturnStruct *device_return)
{
	const ulong thread_per_block = THREADS_PER_BLOCK;
	const ulong blocks = BLOCKS;
	const ulong step = thread_per_block * blocks;

	const uint v1 = *d_v1;
	const uint v2 = *d_v2;
	const uint v3 = *d_v3;
	const uint v4 = *d_v4;

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
		len = idx /(TAM_ALFABETO + 1);
		while(len > 0){
			len /= (TAM_ALFABETO + 1);
			totalLen++;
		}

		converter(idx, palavra);
		md5_vfy(palavra,totalLen, &c1, &c2, &c3, &c4);

		if(c1 == v1 && c2 == v2 && c3 == v3 && c4 == v4)
		{
			my_strcpy(password,palavra);
			*flag = 1;
		}

		idx += step;

	}

}

void h_converter(ulong numeroEntrada, unsigned char pointerPalavra[][255])
{
	unsigned char* str = *pointerPalavra;  // To store result (Excel column name)
	int i = 0;  // To store current index in str which is result

	while (numeroEntrada>0)
	{
		// Find remainder
		ulong rem = numeroEntrada%26;

		// If remainder is 0, then a 'Z' must be there in output
		if (rem==0)
		{
			str[i++] = 'z';
			numeroEntrada = (numeroEntrada/26)-1;
		}
		else // If remainder is non-zero
		{
			str[i++] = (rem-1) + 'a';
			numeroEntrada = numeroEntrada/26;
		}
	}
	str[i] = '\0';

}

int main(int argc,  char *argv[]){

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


	//divido o hash em 4 partes
	md5_to_ints((unsigned char*)argv[1],&v1,&v2,&v3,&v4);

	//Saida de erro caso não tiver um hash como entrada no argumento
    if ( argc != 2 )
    {
        fprintf( stderr, "Erro na entrada de argumentos %s \n", argv[0] );
        exit( 1 );
    }

    //Copia o argumento para a variavel hash_entrada
    //memcpy(hash_entrada,argv[1], TAM_HASH);


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
		crack<<<dimGrid, dimBlock>>>(d_password, d_starting_number , d_current_hash_per_kernel ,d_flag, d_v1, d_v2, d_v3, d_v4, d_device_return);
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
		h_converter(currentNumber, &palavra);

		if(count++%1 == 0){
			printf("i = %d, number = %lu, palavra = %s\n",i, currentNumber, palavra);
			printf("hash_entrada = %s\n",argv[1]);
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

