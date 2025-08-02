# Makefile

all: assembler link clean_obj run

assembler:
	nasm -f elf64 main.asm -o main.o

link:
	ld main.o -o main

clean_obj:
	rm main.o

run:
	./main

clean:
	rm -f main
