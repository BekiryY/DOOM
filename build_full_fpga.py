import os
import subprocess
import sys
import glob

# Scriptin bulunduğu klasöre geç ki başka yerden çalıştırıldığında path'ler bozulmasın
base_dir = os.path.dirname(os.path.abspath(__file__))
os.chdir(os.path.join(base_dir, "doom_codes", "doomgeneric"))

toolchain_dir = r"C:\Users\musta\Documents\riscv_toolchain\xpack-riscv-none-elf-gcc-15.2.0-1\bin"
gcc = os.path.join(toolchain_dir, "riscv-none-elf-gcc.exe")
objcopy = os.path.join(toolchain_dir, "riscv-none-elf-objcopy.exe")
objdump = os.path.join(toolchain_dir, "riscv-none-elf-objdump.exe")

cflags = [
    "-O3", "-march=rv32im", "-mabi=ilp32", "-ffreestanding",
    "-nostartfiles", "-Wl,-T,linker.ld", "-I.", "-Wl,--gc-sections", 
    "-std=gnu99", "-Wno-implicit-function-declaration", "-Wno-implicit-int"
]

def main():
    # 1. doom1.wad dosyasını objeye çeviriyoruz (C kodu içine gömmek için)
    print("WAD dosyasi objeye donusturuluyor...")
    subprocess.run([objcopy, "-I", "binary", "-O", "elf32-littleriscv", "-B", "riscv", "doom1.wad", "doom1.o"], check=True)

    # 2. Sadece FPGA için gereken saf Doom motoru kodlarını derliyoruz
    src_files = [
        "am_map.c", "doomdef.c", "doomstat.c", "dstrings.c", "d_event.c", 
        "d_items.c", "d_iwad.c", "d_loop.c", "d_main.c", "d_mode.c", "d_net.c", 
        "f_finale.c", "f_wipe.c", "g_game.c", "hu_lib.c", "hu_stuff.c", "info.c", 
        "i_cdmus.c", "i_endoom.c", "i_joystick.c", "i_scale.c", "i_sound.c", 
        "i_system.c", "i_timer.c", "memio.c", "m_argv.c", "m_bbox.c", 
        "m_cheat.c", "m_config.c", "m_controls.c", "m_fixed.c", "m_menu.c", 
        "m_misc.c", "m_random.c", "p_ceilng.c", "p_doors.c", "p_enemy.c", 
        "p_floor.c", "p_inter.c", "p_lights.c", "p_map.c", "p_maputl.c", 
        "p_mobj.c", "p_plats.c", "p_pspr.c", "p_saveg.c", "p_setup.c", 
        "p_sight.c", "p_spec.c", "p_switch.c", "p_telept.c", "p_tick.c", 
        "p_user.c", "r_bsp.c", "r_data.c", "r_draw.c", "r_main.c", "r_plane.c", 
        "r_segs.c", "r_sky.c", "r_things.c", "sha1.c", "sounds.c", "statdump.c", 
        "st_lib.c", "st_stuff.c", "s_sound.c", "tables.c", "v_video.c", "wi_stuff.c", 
        "w_checksum.c", "w_file.c", "w_main.c", "w_wad.c", "z_zone.c", 
        "w_file_stdc.c", "i_input.c", "i_video.c", "doomgeneric.c",
        "dummy.c"
    ]
    
    # 3. Compile
    print("RISC-V Icin Doom Derleniyor... (Icinde doom1.wad ile birlikte)")
    cmd = [gcc] + cflags + src_files + ["start.S", "doom1.o", "-o", "doom_fpga_full.elf", "-lgcc", "-lc", "-lm"]
    
    result = subprocess.run(cmd)
    if result.returncode != 0:
        print("Derleme sirasinda hata olustu!")
        sys.exit(1)

    # Find next version number
    version = 1
    while os.path.exists(f"../../doom_eburis_v{version}.bin"):
        version += 1
        
    out_bin = f"../../doom_eburis_v{version}.bin"
    out_asm = f"../../doom_eburis_v{version}.asm"

    print("ELF -> BIN donusumu yapiliyor...")
    subprocess.run([objcopy, "-O", "binary", "doom_fpga_full.elf", out_bin], check=True)

    print("Assembly dökümü (objdump) olusturuluyor...")
    with open(out_asm, "w") as asm_file:
        subprocess.run([objdump, "-d", "doom_fpga_full.elf"], stdout=asm_file)

    print(f"BASARILI! Yeni surum olusturuldu: {out_bin}")

if __name__ == "__main__":
    main()
