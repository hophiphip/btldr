ASM=nasm
QEMU=qemu-system-x86_64 

all: boot.asm
	$(ASM) -f bin boot.asm -o boot.bin

run: boot.bin
	$(QEMU) -drive format=raw,file=boot.bin
