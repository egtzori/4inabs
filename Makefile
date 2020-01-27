all:
	nasm -f bin 4in.asm -o bs.bin

boot:
	qemu-system-x86_64 bs.bin
