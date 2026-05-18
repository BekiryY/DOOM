/* start.S — bare-metal RISC-V startup
 * Stack initialised at 0x01000000 per SoC datasheet.
 */
.section .init
.global _start

_start:
    /* Stack pointer — 16MB mark, grows downward */
    li sp, 0x01000000

    /* Global pointer for relaxed addressing */
.option push
.option norelax
    la gp, __global_pointer$
.option pop

    /* Zero BSS */
    la t0, __bss_start
    la t1, __bss_end
bss_loop:
    bge  t0, t1, bss_done
    sw   zero, 0(t0)
    addi t0, t0, 4
    j    bss_loop
bss_done:

    call main

halt:
    j halt
