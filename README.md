# btldr
Bootloader that does nothing useful

# Usage

## Compile
```bash
nasm -f bin boot.asm -o boot.bin
```

##  Run in VM
```bash
qemu-system-x86_64 -drive format=raw,file=boot.bin
```
