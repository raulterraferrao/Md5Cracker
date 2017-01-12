# Md5Cracker
It is a simple md5Cracker written in C or Cuda(Manycore) that pass through all lowercase letters a-z starting at "a" and stop when reach the corresponding password.
You need to pass as argument the md5 hash e.g 5f4dcc3b5aa765d61d8327deb882cf99 (it is the md5 of "password").

##Md5-serial.c##
It is a code made in C that use only one core of your CPU. It is a basic serial code.

##Md5pthr.c##
It is a code made in C that use pthreads which is faster than Md5-serial.c cause it use more cores of your CPU.

##Md5GPU.cu and md5.cu##
It is a code made in Cuda that use your GPU instead of your CPU to find the corresponding password of your md5 hash, it is much faster than md5-serial.c and md5pthr.c but it needs a Nvidia grafic card and Cuda installed in your machine.

##Compiling##
Md5-serial.c -> gcc Md5-serial.c -o Md5-serial
Md5pthr.c -> gcc Md5pthr.c -o Md5pthr -lcrypto -lprthread -lm (maybe you need to install these libraries.
Md5GPU.cu -> nvcc Md5GPU.cu -o Md5GPU (you need to make sure that md5.cu is in the same folder as Md5GPU.cu)

##Run##
./"Program's name" "md5hash"

Example:
./Md5-serial 5f4dcc3b5aa765d61d8327deb882cf99
