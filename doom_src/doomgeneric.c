/*
 * doomgeneric.c — FPGA bare-metal platform layer for doomgeneric
 *
 * Hardware map (from SoC datasheet):
 *   VRAM      0x40000000  — 64KB BRAM, 4 RGB332 pixels per 32-bit word
 *   KEYBOARD  0x40100000  — 32-bit read-only, bits[8:0] = key states
 *   UART TX   0x40200000  — 32-bit write-only, sends low byte out serial
 *   WAD       0x00400000  — Bootloader copies WAD here from SPI flash
 *
 * CPU constraints:
 *   - RV32I only: no MUL/DIV hardware, compiler uses __mulsi3/__divsi3
 *   - Only LW/SW memory ops: all pointers must be 32-bit aligned
 *   - All hardware registers must be volatile uint32_t*
 */

#include "doomkeys.h"
#include "doomgeneric.h"
#include "d_main.h"
#include "doomstat.h"

#include <string.h>
#include <stdint.h>

/* ── Hardware registers (always 32-bit volatile) ─────────────── */
#define VRAM_ADDR     ((volatile uint32_t*)0x40000000)
#define KEYBOARD_ADDR ((volatile uint32_t*)0x40100000)
#define UART_TX       ((volatile uint32_t*)0x40200000)

/* WAD is handled entirely by w_file_stdc.c via linker symbols _wad_start/_wad_end */

/* ── Screen buffer ────────────────────────────────────────────── */
pixel_t* DG_ScreenBuffer = 0;

/* ── Syscall stubs ────────────────────────────────────────────── */

/* Route printf/I_Error output to UART */
int _write(int file, char *ptr, int len) {
    (void)file;
    for (int i = 0; i < len; i++)
        *UART_TX = (uint32_t)(unsigned char)ptr[i];
    return len;
}

/* Heap allocator — _end is defined by linker.ld */
void* _sbrk(int incr) {
    extern char _end;
    extern char __stack_top;
    static char *heap_end = 0;
    if (!heap_end) heap_end = &_end;
    if (heap_end + incr > &__stack_top) return (void*)-1;
    char *prev = heap_end;
    heap_end += incr;
    return (void*)prev;
}

int _isatty(int file) { (void)file; return 1; }

void _exit(int status) { (void)status; while(1) {} }

/* ── DOOM platform callbacks ──────────────────────────────────── */

void DG_Init() {}

extern uint8_t rgb332_palette[256];

void DG_DrawFrame() {
    uint8_t* src = (uint8_t*)DG_ScreenBuffer;
    for (int i = 0; i < (DOOMGENERIC_RESX * DOOMGENERIC_RESY / 4); i++) {
        uint32_t word = 0;
        word |= ((uint32_t)rgb332_palette[src[(i * 4) + 0]] << 24);
        word |= ((uint32_t)rgb332_palette[src[(i * 4) + 1]] << 16);
        word |= ((uint32_t)rgb332_palette[src[(i * 4) + 2]] << 8);
        word |= ((uint32_t)rgb332_palette[src[(i * 4) + 3]]);
        VRAM_ADDR[i] = word;
    }
}

#define TIMER_ADDR ((volatile uint32_t*)0x40300000)

void DG_SleepMs(uint32_t ms) {
    uint32_t start = *TIMER_ADDR;
    while (*TIMER_ADDR - start < ms) {}
}

uint32_t DG_GetTicksMs() {
    return *TIMER_ADDR;
}

static uint32_t old_keys = 0;

int DG_GetKey(int *pressed, unsigned char *doomKey) {
    uint32_t cur = *KEYBOARD_ADDR;
    uint32_t changed = cur ^ old_keys;
    if (!changed) return 0;

    int bit;
    for (bit = 0; bit < 9; bit++)
        if ((changed >> bit) & 1) break;

    *pressed = (cur >> bit) & 1;
    old_keys ^= (1u << bit);

    switch (bit) {
        case 0: *doomKey = KEY_UPARROW;    break; /* W */
        case 1: *doomKey = KEY_DOWNARROW;  break; /* S */
        case 2: *doomKey = KEY_LEFTARROW;  break; /* A */
        case 3: *doomKey = KEY_RIGHTARROW; break; /* D */
        case 4: *doomKey = KEY_FIRE;       break; /* LCtrl */
        case 5: *doomKey = KEY_USE;        break; /* Space */
        case 6: *doomKey = KEY_RSHIFT;     break; /* LShift */
        case 7: *doomKey = KEY_ESCAPE;     break; /* Esc */
        case 8: *doomKey = KEY_ENTER;      break; /* Enter */
        default: return 0;
    }
    return 1;
}

void DG_SetWindowTitle(const char *title) { (void)title; }

int mkdir(const char *path, uint32_t mode) { (void)path; (void)mode; return 0; }

/* ── Float stubs ──────────────────────────────────────────────
 * v_video.c:V_DrawMouseSpeedBox uses fabs/float but is never called
 * on bare-metal. Stub using integer bit manipulation so zero soft-float
 * library functions are pulled in.
 */
double fabs(double x) {
    /* Clear the sign bit of a double without any float arithmetic */
    union { double d; uint64_t u; } v;
    v.d = x;
    v.u &= 0x7FFFFFFFFFFFFFFFull;
    return v.d;
}

/* ── Entry point ──────────────────────────────────────────────── */

void doomgeneric_Create(int argc, char **argv) {
    (void)argc; (void)argv;
    M_FindResponseFile();
    DG_ScreenBuffer = malloc(DOOMGENERIC_RESX * DOOMGENERIC_RESY * 4);
    DG_Init();
    D_DoomMain();
}

int main(void) {
    doomgeneric_Create(0, 0);
    while (1) {
        doomgeneric_Tick();
    }
    return 0;
}
