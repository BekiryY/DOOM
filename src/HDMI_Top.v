// HDMI_Top.v
// Wraps VGA_Controller and connects to Gowin DVI TX IP.
// No manual TMDS encoding needed — IP handles everything.
// Clocks from Main.v:
//   pix_clk      = 25.2 MHz  (vga_clk, from clkdiv5)
//   tmds_clk     = 126 MHz   (hdmi_serial_clk, from rpll_126, 5x pixel clock)

module HDMI_Top (
    input  wire        pix_clk,        // 25.2 MHz pixel clock
    input  wire        tmds_clk,       // 126 MHz serial clock (5x pix_clk)
    input  wire        sys_rst_n,

    // VRAM interface (pass-through to VGA_Controller)
    output wire [13:0] vram_read_addr,
    output wire        vram_read_en,
    input  wire [31:0] vram_read_data,

    // V-sync for IO register 0x4040_0000
    output wire        vsync_out,

    // HDMI differential outputs
    output wire        tmds_clk_p,
    output wire        tmds_clk_n,
    output wire [2:0]  tmds_data_p,
    output wire [2:0]  tmds_data_n
);

// -------------------------------------------------------
// VGA Controller (unchanged)
// -------------------------------------------------------
wire h_sync, v_sync;
wire [2:0] red_3;
wire [2:0] green_3;
wire [1:0] blue_2;

assign vsync_out = v_sync;

VGA_Controller u_vga (
    .sys_clk        (pix_clk),
    .sys_rst_n      (sys_rst_n),
    .vram_read_addr (vram_read_addr),
    .vram_read_en   (vram_read_en),
    .vram_read_data (vram_read_data),
    .h_sync_i       (h_sync),
    .v_sync_i       (v_sync),
    .RED            (red_3),
    .GREEN          (green_3),
    .BLUE           (blue_2)
);

// -------------------------------------------------------
// RGB332 -> RGB888 expansion
// -------------------------------------------------------
wire [7:0] red_8   = {red_3,   red_3,   red_3[2:1]};
wire [7:0] green_8 = {green_3, green_3, green_3[2:1]};
wire [7:0] blue_8  = {blue_2,  blue_2,  blue_2,  blue_2};

// -------------------------------------------------------
// Active video (data enable) signal for DVI TX IP
// -------------------------------------------------------
localparam H_ACTIVE = 640;
localparam H_TOTAL  = 800;
localparam V_ACTIVE = 480;
localparam V_TOTAL  = 525;

reg [9:0] h_cnt = 0;
reg [9:0] v_cnt = 0;

always @(posedge pix_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        h_cnt <= 0;
        v_cnt <= 0;
    end else begin
        if (h_cnt == H_TOTAL - 1) begin
            h_cnt <= 0;
            v_cnt <= (v_cnt == V_TOTAL - 1) ? 10'd0 : v_cnt + 10'd1;
        end else begin
            h_cnt <= h_cnt + 10'd1;
        end
    end
end

wire de = (h_cnt < H_ACTIVE) && (v_cnt < V_ACTIVE);

// -------------------------------------------------------
// Gowin DVI TX IP
// -------------------------------------------------------
DVI_TX_Top u_dvi_tx (
    .I_rst_n       (sys_rst_n),
    .I_serial_clk  (tmds_clk),    // 126 MHz
    .I_rgb_clk     (pix_clk),     // 25.2 MHz
    .I_rgb_vs      (v_sync),
    .I_rgb_hs      (h_sync),
    .I_rgb_de      (de),
    .I_rgb_r       (red_8),
    .I_rgb_g       (green_8),
    .I_rgb_b       (blue_8),
    .O_tmds_clk_p  (tmds_clk_p),
    .O_tmds_clk_n  (tmds_clk_n),
    .O_tmds_data_p (tmds_data_p),
    .O_tmds_data_n (tmds_data_n)
);

endmodule