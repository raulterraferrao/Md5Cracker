#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <openssl/evp.h>

#define  TAM_ALFABETO 27

/**
 * Função que retorna o hash MD5 de uma string
 *
 * @param input String cujo MD5 queremos calcular
 * @param output String onde será escrito o MD5 (deve estar previamente alocada)
 */
char * md5FromString( char *input, char *output )
{
    EVP_MD_CTX mdctx;
    const EVP_MD *md;
    unsigned int output_len, i;
    unsigned char uOutput[EVP_MAX_MD_SIZE];



    /* You can pass the name of another algorithm supported by your version of OpenSSL here */
    /* For instance, MD2, MD4, SHA1, RIPEMD160 etc. Check the OpenSSL documentation for details */
    md = EVP_get_digestbyname( "MD5" );

    if ( ! md )
    {
        printf( "Unable to init MD5 digest\n" );
        exit( 1 );
    }

    EVP_MD_CTX_init( &mdctx );
    EVP_DigestInit_ex( &mdctx, md, NULL );
    EVP_DigestUpdate( &mdctx, input, strlen( input ) );

    EVP_DigestFinal_ex( &mdctx, uOutput, &output_len );
    EVP_MD_CTX_cleanup( &mdctx );

    // zera a string antes de começar a concatenação
    strcpy( output, "" );
    for(i = 0; i < output_len; i++)
    {
        sprintf( output, "%s%02x", output, uOutput[i] );
    }

    return output;
}
int converter(int numeroEntrada, char** pointerPalavra)
{
  int q,resto,i,flag;
  int isValido = 0;
  int tamanhoString = 1;

  char* palavra;

  palavra = malloc(sizeof(char));
  *palavra = '\0';

  if(numeroEntrada/TAM_ALFABETO > 0){flag = 1;}
  else{flag = 0;}
  do{
		q = (numeroEntrada / TAM_ALFABETO) ;
		resto = numeroEntrada % TAM_ALFABETO;
    if(resto == 0)
    {
        numeroEntrada =+ pow(TAM_ALFABETO,q-1);
        isValido = 0;
        return isValido;
    }

    realloc(palavra,sizeof(char) * ++tamanhoString);

    isValido = 1;
    numeroEntrada /= TAM_ALFABETO;

		switch(resto){
      case 1: strcat(palavra, "a"); break;
      case 2: strcat(palavra, "b"); break;
      case 3: strcat(palavra, "c"); break;
      case 4: strcat(palavra, "d"); break;
      case 5: strcat(palavra, "e"); break;
      case 6: strcat(palavra, "f"); break;
      case 7: strcat(palavra, "g"); break;
      case 8: strcat(palavra, "h"); break;
      case 9: strcat(palavra, "i"); break;
      case 10: strcat(palavra, "j"); break;
      case 11: strcat(palavra, "k"); break;
			case 12: strcat(palavra, "l"); break;
			case 13: strcat(palavra, "m"); break;
			case 14: strcat(palavra, "n"); break;
			case 15: strcat(palavra, "o"); break;
			case 16: strcat(palavra, "p"); break;
			case 17: strcat(palavra, "q"); break;
      case 18: strcat(palavra, "r"); break;
      case 19: strcat(palavra, "s"); break;
      case 20: strcat(palavra, "t"); break;
      case 21: strcat(palavra, "u"); break;
      case 22: strcat(palavra, "v"); break;
      case 23: strcat(palavra, "w"); break;
      case 24: strcat(palavra, "x"); break;
      case 25: strcat(palavra, "y"); break;
      case 26: strcat(palavra, "z"); break;
		}



	}while(q != 0);

  for(i=strlen(palavra); i >= 0; i--){
		//printf("%c", palavra[i]);
	}
  //md5FromString( palavra, output);

  *pointerPalavra = palavra;

  return isValido;

}
int comparar(char * palavra, char * hash)
{
  if(strcmp (palavra,hash) == 0)
  {
    return 1;
  }
  else
  {
    return 0;
  }
}

char * bruteforce(char *hash_arg,char *hash_fin){

  char * palavra;
  int flag = 0, i = 0,ok = 0;

  while(1){
    //palavra = malloc (sizeof(char) * ((i/TAM_ALFABETO) + 1));
    ok = converter(i++,&palavra);
    if(!ok) continue;

    //printf("%s <- hash passado como argumento \n",hash_arg);

    //printf("%s <- palavra convertida, ou seja decimal para alfabeto \n",palavra);

    hash_fin = md5FromString( palavra, hash_fin);

    //printf("%s <- hash da palavra \n",hash_fin);

    flag = comparar(hash_arg,hash_fin);

    //printf("%d <- valor da flag - 1 ok 0 falso \n",flag);

    if(flag == 1){
      return palavra;
    }
    else
    {
      free(palavra);
    }
  }


  //printf( "MD5( '%s' ) = %s\n", hash, converter(25,output));
}

int main(int argc, char *argv[])
{
  /* Initialize digests table */
    OpenSSL_add_all_digests();
    //char ** stringPointer;
    int i;
    int isOk;
    char output[33]; // 32 caracteres mais um para o \0
    //stringPointer = malloc (sizeof(char*));
    char* stringPointer[1];
    if ( argc != 2 )
    {
        fprintf( stderr, "Erro. Uso: %s \n", argv[0] );
        exit( 1 );
    }
    stringPointer[0] = bruteforce(argv[1],output);
    //printf( "MD5( '%s' ) = %s\n", argv[1], md5FromString( argv[1], output ) );

      printf("\n %s palavra",stringPointer[0]);



    return 0;
}
