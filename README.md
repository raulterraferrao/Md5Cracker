# Md5Cracker Serial and Pthread Multicore version
It is a simple md5Cracker written in C that pass through all lowercase letters a-z starting at "a" and stop when reach the corresponding password.
You need to pass as argument the md5 hash e.g 5f4dcc3b5aa765d61d8327deb882cf99 (it is the md5 of "password").

##Md5-serial.c##
It is a code made in C that use only one core of your CPU. It is a basic serial code.

##Md5pthr.c##
It is a code made in C that use pthreads which is faster than Md5-serial.c cause it use more cores of your CPU.

##Compiling##
*Md5-serial.c*  : gcc Md5-serial.c -o Md5-serial

*Md5pthr.c*  : gcc Md5pthr.c -o Md5pthr -lcrypto -lprthread -lm (maybe you need to install these libraries.

##Run##
./"Program's name" "md5hash"

Example:
./Md5-serial 5f4dcc3b5aa765d61d8327deb882cf99

# Md5Cracker CUDA Manycore Version
 
##Md5GPU.cu and md5.cu##
It is a code made in Cuda that use your GPU instead of your CPU to find the corresponding password of your md5 hash, it is much faster than md5-serial.c and md5pthr.c but it needs a Nvidia grafic card and Cuda installed in your machine.
You can choose what charset you want to set up, it can be :

0: a-z
1: A-Z
2: 0-9
3: a-z A-Z
4: a-z 0-9
5: A-Z 0-9
6: a-z A-z 0-9

In case of CUDA version you do not need to insert the hash as argument, you just need to run the program as follow:

##Compiling##
*Md5GPU.cu*  : nvcc Md5GPU.cu -o Md5GPU (you need to make sure that md5.cu is in the same folder as Md5GPU.cu)

Example:
./Md5GPU

Obs:The way it was implemented the words are being presented traversed backwards to the user when it is running, that is after reach aaaa the next word will be baaa not aaab. For na example if your hash is correspond to "password" the word that represent "password" when it is running is "drowssap", but don't be mad, when you get to the respective password it shows normally.

Obs2 : Sometimes a core of your gpu can reach a word of size 6 while others are still checking some remaining words of size 5. In other words, if it appears to you that the program is in the word with a size 6 and you have placed a hash that corresponds to a word of size 5 is a matter of little time until the later core finds it. 
