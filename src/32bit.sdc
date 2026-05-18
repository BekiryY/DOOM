//Copyright (C)2014-2026 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.11.03 (64-bit) 
//Created Time: 2026-05-13 16:12:02
create_clock -name sys_clk -period 37.037 -waveform {0 18.518} [get_ports {sys_clk}]
create_clock -name vga_clk -period 39.683 -waveform {0 19.841} [get_pins {u_clkdiv5/CLKOUT}]
create_clock -name ddr_user_clk -period 10 -waveform {0 5} [get_pins {main_ram/gw3_top/i4/fclkdiv/CLKOUT}]
create_clock -name ddr_mem_clk -period 2.5 -waveform {0 1.25} [get_nets {ddr_memory_clk}] -add
create_clock -name hdmi_clk -period 7.937 -waveform {0 3.969} [get_nets {hdmi_serial_clk}] -add
//set_clock_groups -asynchronous -group [get_clocks {sys_clk}] -group [get_clocks {vga_clk}] -group [get_clocks {ddr_mem_clk}] -group [get_clocks {tck_pad_i}] -group [get_clocks {ddr_user_clk}] -group [get_clocks {hdmi_clk}]
//create_clock -name tck_pad_i -period 50.0 -waveform {0 20.0} [get_ports {tck_pad_i}] -add
set_clock_groups -asynchronous -group [get_clocks {sys_clk}] -group [get_clocks {vga_clk}] -group [get_clocks {ddr_mem_clk}] -group [get_clocks {ddr_user_clk}] -group [get_clocks {hdmi_clk}]
