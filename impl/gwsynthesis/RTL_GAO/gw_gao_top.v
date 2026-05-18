module gw_gao(
    boot_done,
    ddr_calib_complete,
    cpu_done,
    fb_dma_busy,
    dma_line_pulse,
    ddr_cmd_en,
    ddr_rd_data_valid,
    cpu_rd_data_valid,
    dma_rd_data_valid,
    ddr_wr_data_rdy,
    ddr_cmd_ready,
    \u_cpu/state[5] ,
    \u_cpu/state[4] ,
    \u_cpu/state[3] ,
    \u_cpu/state[2] ,
    \u_cpu/state[1] ,
    \u_cpu/state[0] ,
    \program_counter[27] ,
    \program_counter[26] ,
    \program_counter[25] ,
    \program_counter[24] ,
    \program_counter[23] ,
    \program_counter[22] ,
    \program_counter[21] ,
    \program_counter[20] ,
    \program_counter[19] ,
    \program_counter[18] ,
    \program_counter[17] ,
    \program_counter[16] ,
    \program_counter[15] ,
    \program_counter[14] ,
    \program_counter[13] ,
    \program_counter[12] ,
    \program_counter[11] ,
    \program_counter[10] ,
    \program_counter[9] ,
    \program_counter[8] ,
    \program_counter[7] ,
    \program_counter[6] ,
    \program_counter[5] ,
    \program_counter[4] ,
    \icache_inst/cpu_valid ,
    \u_cpu/icache_req ,
    icache_fill_en,
    \u_cpu/dcache_req ,
    \u_cpu/dcache_fill_en ,
    current_owner,
    \own_fifo[3] ,
    \own_fifo[2] ,
    \own_fifo[1] ,
    \own_fifo[0] ,
    uart_wr_en,
    uart_write_done,
    TX,
    \b_state[3] ,
    \b_state[2] ,
    \b_state[1] ,
    \b_state[0] ,
    ddr_user_clk,
    tms_pad_i,
    tck_pad_i,
    tdi_pad_i,
    tdo_pad_o
);

input boot_done;
input ddr_calib_complete;
input cpu_done;
input fb_dma_busy;
input dma_line_pulse;
input ddr_cmd_en;
input ddr_rd_data_valid;
input cpu_rd_data_valid;
input dma_rd_data_valid;
input ddr_wr_data_rdy;
input ddr_cmd_ready;
input \u_cpu/state[5] ;
input \u_cpu/state[4] ;
input \u_cpu/state[3] ;
input \u_cpu/state[2] ;
input \u_cpu/state[1] ;
input \u_cpu/state[0] ;
input \program_counter[27] ;
input \program_counter[26] ;
input \program_counter[25] ;
input \program_counter[24] ;
input \program_counter[23] ;
input \program_counter[22] ;
input \program_counter[21] ;
input \program_counter[20] ;
input \program_counter[19] ;
input \program_counter[18] ;
input \program_counter[17] ;
input \program_counter[16] ;
input \program_counter[15] ;
input \program_counter[14] ;
input \program_counter[13] ;
input \program_counter[12] ;
input \program_counter[11] ;
input \program_counter[10] ;
input \program_counter[9] ;
input \program_counter[8] ;
input \program_counter[7] ;
input \program_counter[6] ;
input \program_counter[5] ;
input \program_counter[4] ;
input \icache_inst/cpu_valid ;
input \u_cpu/icache_req ;
input icache_fill_en;
input \u_cpu/dcache_req ;
input \u_cpu/dcache_fill_en ;
input current_owner;
input \own_fifo[3] ;
input \own_fifo[2] ;
input \own_fifo[1] ;
input \own_fifo[0] ;
input uart_wr_en;
input uart_write_done;
input TX;
input \b_state[3] ;
input \b_state[2] ;
input \b_state[1] ;
input \b_state[0] ;
input ddr_user_clk;
input tms_pad_i;
input tck_pad_i;
input tdi_pad_i;
output tdo_pad_o;

wire boot_done;
wire ddr_calib_complete;
wire cpu_done;
wire fb_dma_busy;
wire dma_line_pulse;
wire ddr_cmd_en;
wire ddr_rd_data_valid;
wire cpu_rd_data_valid;
wire dma_rd_data_valid;
wire ddr_wr_data_rdy;
wire ddr_cmd_ready;
wire \u_cpu/state[5] ;
wire \u_cpu/state[4] ;
wire \u_cpu/state[3] ;
wire \u_cpu/state[2] ;
wire \u_cpu/state[1] ;
wire \u_cpu/state[0] ;
wire \program_counter[27] ;
wire \program_counter[26] ;
wire \program_counter[25] ;
wire \program_counter[24] ;
wire \program_counter[23] ;
wire \program_counter[22] ;
wire \program_counter[21] ;
wire \program_counter[20] ;
wire \program_counter[19] ;
wire \program_counter[18] ;
wire \program_counter[17] ;
wire \program_counter[16] ;
wire \program_counter[15] ;
wire \program_counter[14] ;
wire \program_counter[13] ;
wire \program_counter[12] ;
wire \program_counter[11] ;
wire \program_counter[10] ;
wire \program_counter[9] ;
wire \program_counter[8] ;
wire \program_counter[7] ;
wire \program_counter[6] ;
wire \program_counter[5] ;
wire \program_counter[4] ;
wire \icache_inst/cpu_valid ;
wire \u_cpu/icache_req ;
wire icache_fill_en;
wire \u_cpu/dcache_req ;
wire \u_cpu/dcache_fill_en ;
wire current_owner;
wire \own_fifo[3] ;
wire \own_fifo[2] ;
wire \own_fifo[1] ;
wire \own_fifo[0] ;
wire uart_wr_en;
wire uart_write_done;
wire TX;
wire \b_state[3] ;
wire \b_state[2] ;
wire \b_state[1] ;
wire \b_state[0] ;
wire ddr_user_clk;
wire tms_pad_i;
wire tck_pad_i;
wire tdi_pad_i;
wire tdo_pad_o;
wire tms_i_c;
wire tck_i_c;
wire tdi_i_c;
wire tdo_o_c;
wire [9:0] control0;
wire gao_jtag_tck;
wire gao_jtag_reset;
wire run_test_idle_er1;
wire run_test_idle_er2;
wire shift_dr_capture_dr;
wire update_dr;
wire pause_dr;
wire enable_er1;
wire enable_er2;
wire gao_jtag_tdi;
wire tdo_er1;

IBUF tms_ibuf (
    .I(tms_pad_i),
    .O(tms_i_c)
);

IBUF tck_ibuf (
    .I(tck_pad_i),
    .O(tck_i_c)
);

IBUF tdi_ibuf (
    .I(tdi_pad_i),
    .O(tdi_i_c)
);

OBUF tdo_obuf (
    .I(tdo_o_c),
    .O(tdo_pad_o)
);

GW_JTAG  u_gw_jtag(
    .tms_pad_i(tms_i_c),
    .tck_pad_i(tck_i_c),
    .tdi_pad_i(tdi_i_c),
    .tdo_pad_o(tdo_o_c),
    .tck_o(gao_jtag_tck),
    .test_logic_reset_o(gao_jtag_reset),
    .run_test_idle_er1_o(run_test_idle_er1),
    .run_test_idle_er2_o(run_test_idle_er2),
    .shift_dr_capture_dr_o(shift_dr_capture_dr),
    .update_dr_o(update_dr),
    .pause_dr_o(pause_dr),
    .enable_er1_o(enable_er1),
    .enable_er2_o(enable_er2),
    .tdi_o(gao_jtag_tdi),
    .tdo_er1_i(tdo_er1),
    .tdo_er2_i(1'b0)
);

gw_con_top  u_icon_top(
    .tck_i(gao_jtag_tck),
    .tdi_i(gao_jtag_tdi),
    .tdo_o(tdo_er1),
    .rst_i(gao_jtag_reset),
    .control0(control0[9:0]),
    .enable_i(enable_er1),
    .shift_dr_capture_dr_i(shift_dr_capture_dr),
    .update_dr_i(update_dr)
);

ao_top_0  u_la0_top(
    .control(control0[9:0]),
    .trig0_i(boot_done),
    .trig1_i(cpu_done),
    .trig2_i(uart_wr_en),
    .data_i({boot_done,ddr_calib_complete,cpu_done,fb_dma_busy,dma_line_pulse,ddr_cmd_en,ddr_rd_data_valid,cpu_rd_data_valid,dma_rd_data_valid,ddr_wr_data_rdy,ddr_cmd_ready,\u_cpu/state[5] ,\u_cpu/state[4] ,\u_cpu/state[3] ,\u_cpu/state[2] ,\u_cpu/state[1] ,\u_cpu/state[0] ,\program_counter[27] ,\program_counter[26] ,\program_counter[25] ,\program_counter[24] ,\program_counter[23] ,\program_counter[22] ,\program_counter[21] ,\program_counter[20] ,\program_counter[19] ,\program_counter[18] ,\program_counter[17] ,\program_counter[16] ,\program_counter[15] ,\program_counter[14] ,\program_counter[13] ,\program_counter[12] ,\program_counter[11] ,\program_counter[10] ,\program_counter[9] ,\program_counter[8] ,\program_counter[7] ,\program_counter[6] ,\program_counter[5] ,\program_counter[4] ,\icache_inst/cpu_valid ,\u_cpu/icache_req ,icache_fill_en,\u_cpu/dcache_req ,\u_cpu/dcache_fill_en ,current_owner,\own_fifo[3] ,\own_fifo[2] ,\own_fifo[1] ,\own_fifo[0] ,uart_wr_en,uart_write_done,TX,\b_state[3] ,\b_state[2] ,\b_state[1] ,\b_state[0] }),
    .clk_i(ddr_user_clk)
);

endmodule
