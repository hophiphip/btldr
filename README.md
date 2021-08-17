# btldr
Bootloader that does nothing useful

# Note
Requires [nasm](https://www.nasm.us/) compiler and [QEMU](https://www.qemu.org/) VM installed

# Usage

## Compile
```bash
nasm -f bin boot.asm -o boot.bin
```

##  Run in VM
```bash
qemu-system-x86_64 -drive format=raw,file=boot.bin
```
