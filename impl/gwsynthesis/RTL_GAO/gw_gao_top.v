module gw_gao(
    \ddr_rd_data[127] ,
    \ddr_rd_data[126] ,
    \ddr_rd_data[125] ,
    \ddr_rd_data[124] ,
    \ddr_rd_data[123] ,
    \ddr_rd_data[122] ,
    \ddr_rd_data[121] ,
    \ddr_rd_data[120] ,
    \ddr_rd_data[119] ,
    \ddr_rd_data[118] ,
    \ddr_rd_data[117] ,
    \ddr_rd_data[116] ,
    \ddr_rd_data[115] ,
    \ddr_rd_data[114] ,
    \ddr_rd_data[113] ,
    \ddr_rd_data[112] ,
    \ddr_rd_data[111] ,
    \ddr_rd_data[110] ,
    \ddr_rd_data[109] ,
    \ddr_rd_data[108] ,
    \ddr_rd_data[107] ,
    \ddr_rd_data[106] ,
    \ddr_rd_data[105] ,
    \ddr_rd_data[104] ,
    \ddr_rd_data[103] ,
    \ddr_rd_data[102] ,
    \ddr_rd_data[101] ,
    \ddr_rd_data[100] ,
    \ddr_rd_data[99] ,
    \ddr_rd_data[98] ,
    \ddr_rd_data[97] ,
    \ddr_rd_data[96] ,
    \ddr_rd_data[95] ,
    \ddr_rd_data[94] ,
    \ddr_rd_data[93] ,
    \ddr_rd_data[92] ,
    \ddr_rd_data[91] ,
    \ddr_rd_data[90] ,
    \ddr_rd_data[89] ,
    \ddr_rd_data[88] ,
    \ddr_rd_data[87] ,
    \ddr_rd_data[86] ,
    \ddr_rd_data[85] ,
    \ddr_rd_data[84] ,
    \ddr_rd_data[83] ,
    \ddr_rd_data[82] ,
    \ddr_rd_data[81] ,
    \ddr_rd_data[80] ,
    \ddr_rd_data[79] ,
    \ddr_rd_data[78] ,
    \ddr_rd_data[77] ,
    \ddr_rd_data[76] ,
    \ddr_rd_data[75] ,
    \ddr_rd_data[74] ,
    \ddr_rd_data[73] ,
    \ddr_rd_data[72] ,
    \ddr_rd_data[71] ,
    \ddr_rd_data[70] ,
    \ddr_rd_data[69] ,
    \ddr_rd_data[68] ,
    \ddr_rd_data[67] ,
    \ddr_rd_data[66] ,
    \ddr_rd_data[65] ,
    \ddr_rd_data[64] ,
    ddr_rd_data_valid,
    \rq_is_data[3] ,
    \rq_is_data[2] ,
    \rq_is_data[1] ,
    \rq_is_data[0] ,
    \state[5] ,
    \state[4] ,
    \state[3] ,
    \state[2] ,
    \state[1] ,
    \state[0] ,
    \user_addr[26] ,
    \user_addr[25] ,
    \user_addr[24] ,
    \user_addr[23] ,
    \user_addr[22] ,
    \user_addr[21] ,
    \user_addr[20] ,
    \user_addr[19] ,
    \user_addr[18] ,
    \user_addr[17] ,
    \user_addr[16] ,
    \user_addr[15] ,
    \user_addr[14] ,
    \user_addr[13] ,
    \user_addr[12] ,
    \user_addr[11] ,
    \user_addr[10] ,
    \user_addr[9] ,
    \user_addr[8] ,
    \user_addr[7] ,
    \user_addr[6] ,
    \user_addr[5] ,
    \user_addr[4] ,
    \user_addr[3] ,
    \user_addr[2] ,
    \user_addr[1] ,
    \user_addr[0] ,
    \ddr_wr_data[127] ,
    \ddr_wr_data[126] ,
    \ddr_wr_data[125] ,
    \ddr_wr_data[124] ,
    \ddr_wr_data[123] ,
    \ddr_wr_data[122] ,
    \ddr_wr_data[121] ,
    \ddr_wr_data[120] ,
    \ddr_wr_data[119] ,
    \ddr_wr_data[118] ,
    \ddr_wr_data[117] ,
    \ddr_wr_data[116] ,
    \ddr_wr_data[115] ,
    \ddr_wr_data[114] ,
    \ddr_wr_data[113] ,
    \ddr_wr_data[112] ,
    \ddr_wr_data[111] ,
    \ddr_wr_data[110] ,
    \ddr_wr_data[109] ,
    \ddr_wr_data[108] ,
    \ddr_wr_data[107] ,
    \ddr_wr_data[106] ,
    \ddr_wr_data[105] ,
    \ddr_wr_data[104] ,
    \ddr_wr_data[103] ,
    \ddr_wr_data[102] ,
    \ddr_wr_data[101] ,
    \ddr_wr_data[100] ,
    \ddr_wr_data[99] ,
    \ddr_wr_data[98] ,
    \ddr_wr_data[97] ,
    \ddr_wr_data[96] ,
    \ddr_wr_data[95] ,
    \ddr_wr_data[94] ,
    \ddr_wr_data[93] ,
    \ddr_wr_data[92] ,
    \ddr_wr_data[91] ,
    \ddr_wr_data[90] ,
    \ddr_wr_data[89] ,
    \ddr_wr_data[88] ,
    \ddr_wr_data[87] ,
    \ddr_wr_data[86] ,
    \ddr_wr_data[85] ,
    \ddr_wr_data[84] ,
    \ddr_wr_data[83] ,
    \ddr_wr_data[82] ,
    \ddr_wr_data[81] ,
    \ddr_wr_data[80] ,
    \ddr_wr_data[79] ,
    \ddr_wr_data[78] ,
    \ddr_wr_data[77] ,
    \ddr_wr_data[76] ,
    \ddr_wr_data[75] ,
    \ddr_wr_data[74] ,
    \ddr_wr_data[73] ,
    \ddr_wr_data[72] ,
    \ddr_wr_data[71] ,
    \ddr_wr_data[70] ,
    \ddr_wr_data[69] ,
    \ddr_wr_data[68] ,
    \ddr_wr_data[67] ,
    \ddr_wr_data[66] ,
    \ddr_wr_data[65] ,
    \ddr_wr_data[64] ,
    \ddr_wr_data_mask[15] ,
    \ddr_wr_data_mask[14] ,
    \ddr_wr_data_mask[13] ,
    \ddr_wr_data_mask[12] ,
    \ddr_wr_data_mask[11] ,
    \ddr_wr_data_mask[10] ,
    \ddr_wr_data_mask[9] ,
    \ddr_wr_data_mask[8] ,
    \ddr_wr_data_mask[7] ,
    \ddr_wr_data_mask[6] ,
    \ddr_wr_data_mask[5] ,
    \ddr_wr_data_mask[4] ,
    \ddr_wr_data_mask[3] ,
    \ddr_wr_data_mask[2] ,
    \ddr_wr_data_mask[1] ,
    \ddr_wr_data_mask[0] ,
    ddr_wr_data_en,
    sys_rst_n,
    ddr_user_clk,
    tms_pad_i,
    tck_pad_i,
    tdi_pad_i,
    tdo_pad_o
);

input \ddr_rd_data[127] ;
input \ddr_rd_data[126] ;
input \ddr_rd_data[125] ;
input \ddr_rd_data[124] ;
input \ddr_rd_data[123] ;
input \ddr_rd_data[122] ;
input \ddr_rd_data[121] ;
input \ddr_rd_data[120] ;
input \ddr_rd_data[119] ;
input \ddr_rd_data[118] ;
input \ddr_rd_data[117] ;
input \ddr_rd_data[116] ;
input \ddr_rd_data[115] ;
input \ddr_rd_data[114] ;
input \ddr_rd_data[113] ;
input \ddr_rd_data[112] ;
input \ddr_rd_data[111] ;
input \ddr_rd_data[110] ;
input \ddr_rd_data[109] ;
input \ddr_rd_data[108] ;
input \ddr_rd_data[107] ;
input \ddr_rd_data[106] ;
input \ddr_rd_data[105] ;
input \ddr_rd_data[104] ;
input \ddr_rd_data[103] ;
input \ddr_rd_data[102] ;
input \ddr_rd_data[101] ;
input \ddr_rd_data[100] ;
input \ddr_rd_data[99] ;
input \ddr_rd_data[98] ;
input \ddr_rd_data[97] ;
input \ddr_rd_data[96] ;
input \ddr_rd_data[95] ;
input \ddr_rd_data[94] ;
input \ddr_rd_data[93] ;
input \ddr_rd_data[92] ;
input \ddr_rd_data[91] ;
input \ddr_rd_data[90] ;
input \ddr_rd_data[89] ;
input \ddr_rd_data[88] ;
input \ddr_rd_data[87] ;
input \ddr_rd_data[86] ;
input \ddr_rd_data[85] ;
input \ddr_rd_data[84] ;
input \ddr_rd_data[83] ;
input \ddr_rd_data[82] ;
input \ddr_rd_data[81] ;
input \ddr_rd_data[80] ;
input \ddr_rd_data[79] ;
input \ddr_rd_data[78] ;
input \ddr_rd_data[77] ;
input \ddr_rd_data[76] ;
input \ddr_rd_data[75] ;
input \ddr_rd_data[74] ;
input \ddr_rd_data[73] ;
input \ddr_rd_data[72] ;
input \ddr_rd_data[71] ;
input \ddr_rd_data[70] ;
input \ddr_rd_data[69] ;
input \ddr_rd_data[68] ;
input \ddr_rd_data[67] ;
input \ddr_rd_data[66] ;
input \ddr_rd_data[65] ;
input \ddr_rd_data[64] ;
input ddr_rd_data_valid;
input \rq_is_data[3] ;
input \rq_is_data[2] ;
input \rq_is_data[1] ;
input \rq_is_data[0] ;
input \state[5] ;
input \state[4] ;
input \state[3] ;
input \state[2] ;
input \state[1] ;
input \state[0] ;
input \user_addr[26] ;
input \user_addr[25] ;
input \user_addr[24] ;
input \user_addr[23] ;
input \user_addr[22] ;
input \user_addr[21] ;
input \user_addr[20] ;
input \user_addr[19] ;
input \user_addr[18] ;
input \user_addr[17] ;
input \user_addr[16] ;
input \user_addr[15] ;
input \user_addr[14] ;
input \user_addr[13] ;
input \user_addr[12] ;
input \user_addr[11] ;
input \user_addr[10] ;
input \user_addr[9] ;
input \user_addr[8] ;
input \user_addr[7] ;
input \user_addr[6] ;
input \user_addr[5] ;
input \user_addr[4] ;
input \user_addr[3] ;
input \user_addr[2] ;
input \user_addr[1] ;
input \user_addr[0] ;
input \ddr_wr_data[127] ;
input \ddr_wr_data[126] ;
input \ddr_wr_data[125] ;
input \ddr_wr_data[124] ;
input \ddr_wr_data[123] ;
input \ddr_wr_data[122] ;
input \ddr_wr_data[121] ;
input \ddr_wr_data[120] ;
input \ddr_wr_data[119] ;
input \ddr_wr_data[118] ;
input \ddr_wr_data[117] ;
input \ddr_wr_data[116] ;
input \ddr_wr_data[115] ;
input \ddr_wr_data[114] ;
input \ddr_wr_data[113] ;
input \ddr_wr_data[112] ;
input \ddr_wr_data[111] ;
input \ddr_wr_data[110] ;
input \ddr_wr_data[109] ;
input \ddr_wr_data[108] ;
input \ddr_wr_data[107] ;
input \ddr_wr_data[106] ;
input \ddr_wr_data[105] ;
input \ddr_wr_data[104] ;
input \ddr_wr_data[103] ;
input \ddr_wr_data[102] ;
input \ddr_wr_data[101] ;
input \ddr_wr_data[100] ;
input \ddr_wr_data[99] ;
input \ddr_wr_data[98] ;
input \ddr_wr_data[97] ;
input \ddr_wr_data[96] ;
input \ddr_wr_data[95] ;
input \ddr_wr_data[94] ;
input \ddr_wr_data[93] ;
input \ddr_wr_data[92] ;
input \ddr_wr_data[91] ;
input \ddr_wr_data[90] ;
input \ddr_wr_data[89] ;
input \ddr_wr_data[88] ;
input \ddr_wr_data[87] ;
input \ddr_wr_data[86] ;
input \ddr_wr_data[85] ;
input \ddr_wr_data[84] ;
input \ddr_wr_data[83] ;
input \ddr_wr_data[82] ;
input \ddr_wr_data[81] ;
input \ddr_wr_data[80] ;
input \ddr_wr_data[79] ;
input \ddr_wr_data[78] ;
input \ddr_wr_data[77] ;
input \ddr_wr_data[76] ;
input \ddr_wr_data[75] ;
input \ddr_wr_data[74] ;
input \ddr_wr_data[73] ;
input \ddr_wr_data[72] ;
input \ddr_wr_data[71] ;
input \ddr_wr_data[70] ;
input \ddr_wr_data[69] ;
input \ddr_wr_data[68] ;
input \ddr_wr_data[67] ;
input \ddr_wr_data[66] ;
input \ddr_wr_data[65] ;
input \ddr_wr_data[64] ;
input \ddr_wr_data_mask[15] ;
input \ddr_wr_data_mask[14] ;
input \ddr_wr_data_mask[13] ;
input \ddr_wr_data_mask[12] ;
input \ddr_wr_data_mask[11] ;
input \ddr_wr_data_mask[10] ;
input \ddr_wr_data_mask[9] ;
input \ddr_wr_data_mask[8] ;
input \ddr_wr_data_mask[7] ;
input \ddr_wr_data_mask[6] ;
input \ddr_wr_data_mask[5] ;
input \ddr_wr_data_mask[4] ;
input \ddr_wr_data_mask[3] ;
input \ddr_wr_data_mask[2] ;
input \ddr_wr_data_mask[1] ;
input \ddr_wr_data_mask[0] ;
input ddr_wr_data_en;
input sys_rst_n;
input ddr_user_clk;
input tms_pad_i;
input tck_pad_i;
input tdi_pad_i;
output tdo_pad_o;

wire \ddr_rd_data[127] ;
wire \ddr_rd_data[126] ;
wire \ddr_rd_data[125] ;
wire \ddr_rd_data[124] ;
wire \ddr_rd_data[123] ;
wire \ddr_rd_data[122] ;
wire \ddr_rd_data[121] ;
wire \ddr_rd_data[120] ;
wire \ddr_rd_data[119] ;
wire \ddr_rd_data[118] ;
wire \ddr_rd_data[117] ;
wire \ddr_rd_data[116] ;
wire \ddr_rd_data[115] ;
wire \ddr_rd_data[114] ;
wire \ddr_rd_data[113] ;
wire \ddr_rd_data[112] ;
wire \ddr_rd_data[111] ;
wire \ddr_rd_data[110] ;
wire \ddr_rd_data[109] ;
wire \ddr_rd_data[108] ;
wire \ddr_rd_data[107] ;
wire \ddr_rd_data[106] ;
wire \ddr_rd_data[105] ;
wire \ddr_rd_data[104] ;
wire \ddr_rd_data[103] ;
wire \ddr_rd_data[102] ;
wire \ddr_rd_data[101] ;
wire \ddr_rd_data[100] ;
wire \ddr_rd_data[99] ;
wire \ddr_rd_data[98] ;
wire \ddr_rd_data[97] ;
wire \ddr_rd_data[96] ;
wire \ddr_rd_data[95] ;
wire \ddr_rd_data[94] ;
wire \ddr_rd_data[93] ;
wire \ddr_rd_data[92] ;
wire \ddr_rd_data[91] ;
wire \ddr_rd_data[90] ;
wire \ddr_rd_data[89] ;
wire \ddr_rd_data[88] ;
wire \ddr_rd_data[87] ;
wire \ddr_rd_data[86] ;
wire \ddr_rd_data[85] ;
wire \ddr_rd_data[84] ;
wire \ddr_rd_data[83] ;
wire \ddr_rd_data[82] ;
wire \ddr_rd_data[81] ;
wire \ddr_rd_data[80] ;
wire \ddr_rd_data[79] ;
wire \ddr_rd_data[78] ;
wire \ddr_rd_data[77] ;
wire \ddr_rd_data[76] ;
wire \ddr_rd_data[75] ;
wire \ddr_rd_data[74] ;
wire \ddr_rd_data[73] ;
wire \ddr_rd_data[72] ;
wire \ddr_rd_data[71] ;
wire \ddr_rd_data[70] ;
wire \ddr_rd_data[69] ;
wire \ddr_rd_data[68] ;
wire \ddr_rd_data[67] ;
wire \ddr_rd_data[66] ;
wire \ddr_rd_data[65] ;
wire \ddr_rd_data[64] ;
wire ddr_rd_data_valid;
wire \rq_is_data[3] ;
wire \rq_is_data[2] ;
wire \rq_is_data[1] ;
wire \rq_is_data[0] ;
wire \state[5] ;
wire \state[4] ;
wire \state[3] ;
wire \state[2] ;
wire \state[1] ;
wire \state[0] ;
wire \user_addr[26] ;
wire \user_addr[25] ;
wire \user_addr[24] ;
wire \user_addr[23] ;
wire \user_addr[22] ;
wire \user_addr[21] ;
wire \user_addr[20] ;
wire \user_addr[19] ;
wire \user_addr[18] ;
wire \user_addr[17] ;
wire \user_addr[16] ;
wire \user_addr[15] ;
wire \user_addr[14] ;
wire \user_addr[13] ;
wire \user_addr[12] ;
wire \user_addr[11] ;
wire \user_addr[10] ;
wire \user_addr[9] ;
wire \user_addr[8] ;
wire \user_addr[7] ;
wire \user_addr[6] ;
wire \user_addr[5] ;
wire \user_addr[4] ;
wire \user_addr[3] ;
wire \user_addr[2] ;
wire \user_addr[1] ;
wire \user_addr[0] ;
wire \ddr_wr_data[127] ;
wire \ddr_wr_data[126] ;
wire \ddr_wr_data[125] ;
wire \ddr_wr_data[124] ;
wire \ddr_wr_data[123] ;
wire \ddr_wr_data[122] ;
wire \ddr_wr_data[121] ;
wire \ddr_wr_data[120] ;
wire \ddr_wr_data[119] ;
wire \ddr_wr_data[118] ;
wire \ddr_wr_data[117] ;
wire \ddr_wr_data[116] ;
wire \ddr_wr_data[115] ;
wire \ddr_wr_data[114] ;
wire \ddr_wr_data[113] ;
wire \ddr_wr_data[112] ;
wire \ddr_wr_data[111] ;
wire \ddr_wr_data[110] ;
wire \ddr_wr_data[109] ;
wire \ddr_wr_data[108] ;
wire \ddr_wr_data[107] ;
wire \ddr_wr_data[106] ;
wire \ddr_wr_data[105] ;
wire \ddr_wr_data[104] ;
wire \ddr_wr_data[103] ;
wire \ddr_wr_data[102] ;
wire \ddr_wr_data[101] ;
wire \ddr_wr_data[100] ;
wire \ddr_wr_data[99] ;
wire \ddr_wr_data[98] ;
wire \ddr_wr_data[97] ;
wire \ddr_wr_data[96] ;
wire \ddr_wr_data[95] ;
wire \ddr_wr_data[94] ;
wire \ddr_wr_data[93] ;
wire \ddr_wr_data[92] ;
wire \ddr_wr_data[91] ;
wire \ddr_wr_data[90] ;
wire \ddr_wr_data[89] ;
wire \ddr_wr_data[88] ;
wire \ddr_wr_data[87] ;
wire \ddr_wr_data[86] ;
wire \ddr_wr_data[85] ;
wire \ddr_wr_data[84] ;
wire \ddr_wr_data[83] ;
wire \ddr_wr_data[82] ;
wire \ddr_wr_data[81] ;
wire \ddr_wr_data[80] ;
wire \ddr_wr_data[79] ;
wire \ddr_wr_data[78] ;
wire \ddr_wr_data[77] ;
wire \ddr_wr_data[76] ;
wire \ddr_wr_data[75] ;
wire \ddr_wr_data[74] ;
wire \ddr_wr_data[73] ;
wire \ddr_wr_data[72] ;
wire \ddr_wr_data[71] ;
wire \ddr_wr_data[70] ;
wire \ddr_wr_data[69] ;
wire \ddr_wr_data[68] ;
wire \ddr_wr_data[67] ;
wire \ddr_wr_data[66] ;
wire \ddr_wr_data[65] ;
wire \ddr_wr_data[64] ;
wire \ddr_wr_data_mask[15] ;
wire \ddr_wr_data_mask[14] ;
wire \ddr_wr_data_mask[13] ;
wire \ddr_wr_data_mask[12] ;
wire \ddr_wr_data_mask[11] ;
wire \ddr_wr_data_mask[10] ;
wire \ddr_wr_data_mask[9] ;
wire \ddr_wr_data_mask[8] ;
wire \ddr_wr_data_mask[7] ;
wire \ddr_wr_data_mask[6] ;
wire \ddr_wr_data_mask[5] ;
wire \ddr_wr_data_mask[4] ;
wire \ddr_wr_data_mask[3] ;
wire \ddr_wr_data_mask[2] ;
wire \ddr_wr_data_mask[1] ;
wire \ddr_wr_data_mask[0] ;
wire ddr_wr_data_en;
wire sys_rst_n;
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
    .trig0_i(sys_rst_n),
    .trig1_i(ddr_rd_data_valid),
    .trig2_i(ddr_wr_data_en),
    .data_i({\ddr_rd_data[127] ,\ddr_rd_data[126] ,\ddr_rd_data[125] ,\ddr_rd_data[124] ,\ddr_rd_data[123] ,\ddr_rd_data[122] ,\ddr_rd_data[121] ,\ddr_rd_data[120] ,\ddr_rd_data[119] ,\ddr_rd_data[118] ,\ddr_rd_data[117] ,\ddr_rd_data[116] ,\ddr_rd_data[115] ,\ddr_rd_data[114] ,\ddr_rd_data[113] ,\ddr_rd_data[112] ,\ddr_rd_data[111] ,\ddr_rd_data[110] ,\ddr_rd_data[109] ,\ddr_rd_data[108] ,\ddr_rd_data[107] ,\ddr_rd_data[106] ,\ddr_rd_data[105] ,\ddr_rd_data[104] ,\ddr_rd_data[103] ,\ddr_rd_data[102] ,\ddr_rd_data[101] ,\ddr_rd_data[100] ,\ddr_rd_data[99] ,\ddr_rd_data[98] ,\ddr_rd_data[97] ,\ddr_rd_data[96] ,\ddr_rd_data[95] ,\ddr_rd_data[94] ,\ddr_rd_data[93] ,\ddr_rd_data[92] ,\ddr_rd_data[91] ,\ddr_rd_data[90] ,\ddr_rd_data[89] ,\ddr_rd_data[88] ,\ddr_rd_data[87] ,\ddr_rd_data[86] ,\ddr_rd_data[85] ,\ddr_rd_data[84] ,\ddr_rd_data[83] ,\ddr_rd_data[82] ,\ddr_rd_data[81] ,\ddr_rd_data[80] ,\ddr_rd_data[79] ,\ddr_rd_data[78] ,\ddr_rd_data[77] ,\ddr_rd_data[76] ,\ddr_rd_data[75] ,\ddr_rd_data[74] ,\ddr_rd_data[73] ,\ddr_rd_data[72] ,\ddr_rd_data[71] ,\ddr_rd_data[70] ,\ddr_rd_data[69] ,\ddr_rd_data[68] ,\ddr_rd_data[67] ,\ddr_rd_data[66] ,\ddr_rd_data[65] ,\ddr_rd_data[64] ,ddr_rd_data_valid,\rq_is_data[3] ,\rq_is_data[2] ,\rq_is_data[1] ,\rq_is_data[0] ,\state[5] ,\state[4] ,\state[3] ,\state[2] ,\state[1] ,\state[0] ,\user_addr[26] ,\user_addr[25] ,\user_addr[24] ,\user_addr[23] ,\user_addr[22] ,\user_addr[21] ,\user_addr[20] ,\user_addr[19] ,\user_addr[18] ,\user_addr[17] ,\user_addr[16] ,\user_addr[15] ,\user_addr[14] ,\user_addr[13] ,\user_addr[12] ,\user_addr[11] ,\user_addr[10] ,\user_addr[9] ,\user_addr[8] ,\user_addr[7] ,\user_addr[6] ,\user_addr[5] ,\user_addr[4] ,\user_addr[3] ,\user_addr[2] ,\user_addr[1] ,\user_addr[0] ,\ddr_wr_data[127] ,\ddr_wr_data[126] ,\ddr_wr_data[125] ,\ddr_wr_data[124] ,\ddr_wr_data[123] ,\ddr_wr_data[122] ,\ddr_wr_data[121] ,\ddr_wr_data[120] ,\ddr_wr_data[119] ,\ddr_wr_data[118] ,\ddr_wr_data[117] ,\ddr_wr_data[116] ,\ddr_wr_data[115] ,\ddr_wr_data[114] ,\ddr_wr_data[113] ,\ddr_wr_data[112] ,\ddr_wr_data[111] ,\ddr_wr_data[110] ,\ddr_wr_data[109] ,\ddr_wr_data[108] ,\ddr_wr_data[107] ,\ddr_wr_data[106] ,\ddr_wr_data[105] ,\ddr_wr_data[104] ,\ddr_wr_data[103] ,\ddr_wr_data[102] ,\ddr_wr_data[101] ,\ddr_wr_data[100] ,\ddr_wr_data[99] ,\ddr_wr_data[98] ,\ddr_wr_data[97] ,\ddr_wr_data[96] ,\ddr_wr_data[95] ,\ddr_wr_data[94] ,\ddr_wr_data[93] ,\ddr_wr_data[92] ,\ddr_wr_data[91] ,\ddr_wr_data[90] ,\ddr_wr_data[89] ,\ddr_wr_data[88] ,\ddr_wr_data[87] ,\ddr_wr_data[86] ,\ddr_wr_data[85] ,\ddr_wr_data[84] ,\ddr_wr_data[83] ,\ddr_wr_data[82] ,\ddr_wr_data[81] ,\ddr_wr_data[80] ,\ddr_wr_data[79] ,\ddr_wr_data[78] ,\ddr_wr_data[77] ,\ddr_wr_data[76] ,\ddr_wr_data[75] ,\ddr_wr_data[74] ,\ddr_wr_data[73] ,\ddr_wr_data[72] ,\ddr_wr_data[71] ,\ddr_wr_data[70] ,\ddr_wr_data[69] ,\ddr_wr_data[68] ,\ddr_wr_data[67] ,\ddr_wr_data[66] ,\ddr_wr_data[65] ,\ddr_wr_data[64] ,\ddr_wr_data_mask[15] ,\ddr_wr_data_mask[14] ,\ddr_wr_data_mask[13] ,\ddr_wr_data_mask[12] ,\ddr_wr_data_mask[11] ,\ddr_wr_data_mask[10] ,\ddr_wr_data_mask[9] ,\ddr_wr_data_mask[8] ,\ddr_wr_data_mask[7] ,\ddr_wr_data_mask[6] ,\ddr_wr_data_mask[5] ,\ddr_wr_data_mask[4] ,\ddr_wr_data_mask[3] ,\ddr_wr_data_mask[2] ,\ddr_wr_data_mask[1] ,\ddr_wr_data_mask[0] ,ddr_wr_data_en}),
    .clk_i(ddr_user_clk)
);

endmodule
