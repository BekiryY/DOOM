#!/bin/bash
echo "Compiling DOOM for Eburis..."

# Use wildcards to exclude all alternate frontends and OS-specific media wrappers.
# We also exclude doomgeneric.c here because you already explicitly include it in the gcc command below.
DOOM_SRCS=$(find . -maxdepth 1 -name "*.c" \
        ! -name "doomgeneric_*.c" \
        ! -name "i_sdl*.c" \
        ! -name "i_allegro*.c" \
        ! -name "i_main.c" \
        ! -name "doomgeneric.c")

riscv64-elf-gcc -O2 -march=rv32i -mabi=ilp32 -ffreestanding -nostartfiles -std=gnu99 --specs=nosys.specs \
        -Wno-implicit-function-declaration \
        -T linker.ld start.S doomgeneric.c $DOOM_SRCS \
        -o doom.elf -lgcc -lc -lm

riscv64-elf-objcopy -O binary doom.elf doom.bin

echo "Finished: doom.bin"
