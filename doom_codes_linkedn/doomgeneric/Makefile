# ============================================================
# Bare-metal RISC-V Makefile for doomgeneric on FPGA
# WAD is embedded at 0x00400000 in the binary.
# Usage: make -f Makefile.fpga
# ============================================================

CC      = riscv64-elf-gcc
OBJCOPY = riscv64-elf-objcopy

ARCH    = -march=rv32im -mabi=ilp32

CFLAGS  = -O2 $(ARCH) \
          -std=gnu99 \
          -ffreestanding \
          -nostartfiles \
          -mstrict-align \
          -DNORMALUNIX -DLINUX -D_DEFAULT_SOURCE \
          -DDOOMGENERIC_RESX=320 -DDOOMGENERIC_RESY=200 \
          -Wno-implicit-function-declaration \
          -Wno-int-conversion
	  

LDFLAGS = -T linker.ld --specs=nosys.specs
LIBS    = -lgcc

WAD        = doom1.wad
WAD_OBJ    = wad_blob.o

TARGET_ELF = doom_fpga_im.elf
TARGET_BIN = doom_fpga_im.bin
OBJDIR     = build_fpga

# ── DOOM engine source files ──────────────────────────────────
SRC_DOOM = \
    dummy.o am_map.o doomdef.o doomstat.o dstrings.o \
    d_event.o d_items.o d_iwad.o d_loop.o d_main.o \
    d_mode.o d_net.o f_finale.o f_wipe.o g_game.o \
    hu_lib.o hu_stuff.o info.o i_cdmus.o i_endoom.o \
    i_joystick.o i_scale.o i_sound.o i_system.o i_timer.o \
    memio.o m_argv.o m_bbox.o m_cheat.o m_config.o \
    m_controls.o m_fixed.o m_menu.o m_misc.o m_random.o \
    p_ceilng.o p_doors.o p_enemy.o p_floor.o p_inter.o \
    p_lights.o p_map.o p_maputl.o p_mobj.o p_plats.o \
    p_pspr.o p_saveg.o p_setup.o p_sight.o p_spec.o \
    p_switch.o p_telept.o p_tick.o p_user.o r_bsp.o \
    r_data.o r_draw.o r_main.o r_plane.o r_segs.o \
    r_sky.o r_things.o sha1.o sounds.o statdump.o \
    st_lib.o st_stuff.o s_sound.o tables.o v_video.o \
    wi_stuff.o w_checksum.o w_file.o w_main.o w_wad.o \
    z_zone.o w_file_stdc.o i_input.o i_video.o \
    doomgeneric.o

OBJS = $(addprefix $(OBJDIR)/, $(SRC_DOOM))

# ── Targets ───────────────────────────────────────────────────
all: $(TARGET_BIN)
	@echo "===================================="
	@echo " Build complete: $(TARGET_BIN)"
	@riscv64-elf-size $(TARGET_ELF)
	@echo "===================================="

# Embed WAD into .wad_blob section so linker places it at 0x00400000
$(WAD_OBJ): $(WAD)
	$(OBJCOPY) -I binary -O elf32-littleriscv -B riscv \
	    --rename-section .data=.wad_blob \
	    $< $@

# Link — start.S first, WAD obj included so linker places it at 0x00400000
$(TARGET_ELF): start.S $(OBJS) $(WAD_OBJ) linker.ld
	$(CC) $(CFLAGS) $(LDFLAGS) start.S $(OBJS) $(WAD_OBJ) -o $@ $(LIBS)

# --pad-to ensures the binary is a true memory image:
# every section's VMA == its offset in the file.
# Without this, .data lands at the wrong address in RAM.
$(TARGET_BIN): $(TARGET_ELF)
	$(OBJCOPY) -O binary --gap-fill=0x00 $< $@

$(OBJDIR)/%.o: %.c | $(OBJDIR)
	@echo [CC] $<
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJDIR):
	mkdir -p $(OBJDIR)

clean:
	rm -rf $(OBJDIR) $(TARGET_ELF) $(TARGET_BIN) $(WAD_OBJ)

.PHONY: all clean
