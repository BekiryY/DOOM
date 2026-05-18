/*
 * syscalls.c — newlib bare-metal syscall stubs for RISC-V FPGA DOOM
 *
 * newlib calls these when it needs OS services. We provide the minimum
 * set needed for DOOM to link and run.
 */

#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#include <stdint.h>

/* ── UART ─────────────────────────────────────────────────────── */
#define UART_TX ((volatile uint32_t*)0x40200000)

/* ── _write: routes printf/fprintf output to UART ────────────── */
int _write(int file, char *ptr, int len) {
    for (int i = 0; i < len; i++)
        *UART_TX = (uint32_t)(unsigned char)ptr[i];
    return len;
}

/* ── _sbrk: heap allocator — heap starts at linker _end symbol ─ */
void* _sbrk(int incr) {
    extern char _end;          /* defined in linker.ld */
    extern char __stack_top;   /* defined in linker.ld */
    static char *heap_end = 0;

    if (heap_end == 0)
        heap_end = &_end;

    /* Prevent heap from colliding with stack */
    if (heap_end + incr > &__stack_top) {
        errno = ENOMEM;
        return (void*)-1;
    }

    char *prev = heap_end;
    heap_end += incr;
    return (void*)prev;
}

/* ── _exit: trap on exit ──────────────────────────────────────── */
void _exit(int status) {
    (void)status;
    while (1) {}
}

/* ── _kill / _getpid: needed by newlib internals ─────────────── */
int _kill(int pid, int sig) {
    (void)pid; (void)sig;
    errno = EINVAL;
    return -1;
}

int _getpid(void) {
    return 1;
}

/* ── _isatty ──────────────────────────────────────────────────── */
int _isatty(int file) {
    (void)file;
    return 1;
}

/* ── WAD helpers (defined in doomgeneric.c) ───────────────────── */
extern int wad_open(void);
extern int wad_read(char *ptr, int len);
extern int wad_lseek(int ptr, int dir);
extern int wad_fstat_size(void);

/* ── _open ────────────────────────────────────────────────────── */
int _open(const char *name, int flags, int mode) {
    (void)flags; (void)mode;
    /* Any WAD file request → virtual fd 99 */
    const char *p = name;
    /* manual strstr for .wad / .WAD without pulling in string.h here */
    while (*p) {
        if ((p[0]=='.' && p[1]=='w' && p[2]=='a' && p[3]=='d') ||
            (p[0]=='.' && p[1]=='W' && p[2]=='A' && p[3]=='D'))
            return wad_open();
        p++;
    }
    errno = ENOENT;
    return -1;
}

/* ── _close ───────────────────────────────────────────────────── */
int _close(int file) {
    (void)file;
    return 0;
}

/* ── _fstat ───────────────────────────────────────────────────── */
int _fstat(int file, struct stat *st) {
    if (file == 99) {
        st->st_size = wad_fstat_size();
        st->st_mode = S_IFREG;
    } else {
        st->st_mode = S_IFCHR;
    }
    return 0;
}

/* ── _lseek ───────────────────────────────────────────────────── */
int _lseek(int file, int ptr, int dir) {
    if (file == 99) return wad_lseek(ptr, dir);
    return 0;
}

/* ── _read ────────────────────────────────────────────────────── */
int _read(int file, char *ptr, int len) {
    if (file == 99) return wad_read(ptr, len);
    return 0;
}
