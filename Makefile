all:
	nasm -f bin 1.asm -o 1.bin

boot:
	qemu-system-x86_64 1.bin
