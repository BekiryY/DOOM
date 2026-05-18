/* linker.ld — RISC-V FPGA SoC
 *
 * Everything packed tightly to fit in 7MB flash window:
 *   0x00000000  .text + .rodata   (~460KB)
 *   0x00080000  .wad              (4MB doom1.wad, ends ~0x00480000)
 *   0x00490000  .data + .bss
 *   0x01000000  stack top
 *
 * Total binary: ~5MB — fits within 7MB bootloader limit.
 */

OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY {
    RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 32M
}

SECTIONS {
    .text 0x00000000 : {
        *(.init)
        *(.text*)
        *(.rodata*)
        . = ALIGN(4);
    } > RAM

    /* WAD immediately after code — no wasted gap */
    .wad : {
        . = ALIGN(4);
        _wad_start = .;
        KEEP(doom1.o(.data))    /* ← explicitly grab objcopy output */
        _wad_end = .;
        . = ALIGN(4);
    } > RAM

    .data : {
        . = ALIGN(4);
        PROVIDE(__global_pointer$ = . + 0x800);
        *(.data*)
        *(.sdata*)
        . = ALIGN(4);
    } > RAM

    .bss : {
        . = ALIGN(4);
        __bss_start = .;
        *(.bss*)
        *(.sbss*)
        *(COMMON)
        . = ALIGN(4);
        __bss_end = .;
    } > RAM

    . = ALIGN(8);
    PROVIDE(end  = .);
    PROVIDE(_end = .);

    __stack_top = 0x01000000;
}
