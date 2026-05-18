// VGA_Controller — reads from a 160×32-bit ping-pong line buffer
// (2-clock BSRAM read latency, runs in vga_clk = 25.2 MHz domain)
//
// Line buffer interface:
//   lb_rd_addr[7]     = bank select (driven from Main via lb_rd_bank)
//   lb_rd_addr[6:0]   = word within line (0..79, one word = 4 pixels)
// Output: 32-bit word (RGB332 × 4 pixels), available 2 cycles after addr.
//
// Pipeline compensation: sub_pixel is delayed 2 cycles so it aligns
// with the word data when it emerges from the BSRAM.
module VGA_Controller (
    input  wire sys_clk,      // 25.2 MHz pixel clock
    input  wire sys_rst_n,

    // Line buffer read port (replaces flat VRAM)
    output reg  [7:0]  lb_rd_addr,   // [7]=bank, [6:0]=word in line
    output reg         lb_rd_en,
    input  wire [31:0] lb_rd_data,   // 2-cycle latency from BSRAM

    // Which bank to read (driven by fb_dma, in ddr_user_clk; stable per line)
    input  wire        lb_rd_bank,

    // Sync / color outputs
    output wire h_sync_i,
    output wire v_sync_i,
    output reg  [2:0]  RED,
    output reg  [2:0]  GREEN,
    output reg  [1:0]  BLUE,

    // Scan-line CDC: pulse + line number to fb_dma (in vga_clk domain)
    output reg         line_pulse_vga,   // 1-cycle pulse when entering blanking
    output reg  [8:0]  line_num_vga      // DOOM line number to prefetch next
);

// ---------------------------------------------------------------------------
// 640×480 @ 60 Hz timings (25 MHz clock)
// ---------------------------------------------------------------------------
parameter H_ACTIVE = 640;
parameter H_FRONT  = 16;
parameter H_SYNC   = 96;
parameter H_BACK   = 48;
parameter H_TOTAL  = 800;

parameter V_ACTIVE = 480;
parameter V_FRONT  = 10;
parameter V_SYNC   = 2;
parameter V_BACK   = 33;
parameter V_TOTAL  = 525;

reg [9:0] h_cnt = 0;
reg [9:0] v_cnt = 0;

assign h_sync_i = ~(h_cnt >= (H_ACTIVE + H_FRONT) && h_cnt < (H_ACTIVE + H_FRONT + H_SYNC));
assign v_sync_i = ~(v_cnt >= (V_ACTIVE + V_FRONT) && v_cnt < (V_ACTIVE + V_FRONT + V_SYNC));

// ---------------------------------------------------------------------------
// Active-video window: 320×200 centered in 640×480 (2× scale)
// Vertical: rows 40..439  Horizontal: 0..639
// ---------------------------------------------------------------------------
wire image_active = (h_cnt < 640) && (v_cnt >= 40) && (v_cnt < 440);

// Pixel coordinates inside the 320×200 DOOM framebuffer
wire [8:0] pixel_x  = h_cnt[9:1];          // 0..319
wire [9:0] v_offset = v_cnt - 10'd40;
wire [7:0] pixel_y  = v_offset[8:1];        // 0..199

// Word index in line buffer (one 32-bit word holds 4 pixels)
wire [6:0] word_in_line = pixel_x[8:2];     // 0..79
// Which of the 4 pixels inside that word
wire [1:0] sub_pixel     = pixel_x[1:0];

// ---------------------------------------------------------------------------
// Issue line buffer read address EVERY active pixel clock.
// With 2-cycle BSRAM latency the data for cycle t arrives at cycle t+2.
// We compensate by pipelining sub_pixel and image_active by 2 cycles so
// they match the data when it arrives.
// ---------------------------------------------------------------------------
reg [1:0] sub_pixel_d1  = 0, sub_pixel_d2  = 0;
reg       img_active_d1 = 0, img_active_d2 = 0;

// ---------------------------------------------------------------------------
// h_cnt / v_cnt counter + scan-line trigger generation
// ---------------------------------------------------------------------------
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        h_cnt          <= 0;
        v_cnt          <= 0;
        line_pulse_vga <= 0;
        line_num_vga   <= 0;
        lb_rd_en       <= 0;
        lb_rd_addr     <= 0;
        sub_pixel_d1   <= 0; sub_pixel_d2 <= 0;
        img_active_d1  <= 0; img_active_d2 <= 0;
        RED <= 0; GREEN <= 0; BLUE <= 0;
    end else begin
        // ── Counter update ────────────────────────────────────────────────
        if (h_cnt == H_TOTAL - 1) begin
            h_cnt <= 10'd0;
            if (v_cnt == V_TOTAL - 1) v_cnt <= 10'd0;
            else                      v_cnt <= v_cnt + 10'd1;
        end else begin
            h_cnt <= h_cnt + 10'd1;
        end

        // ── Scan-line prefetch pulse ──────────────────────────────────────
        // Fire when we enter horizontal blanking (h_cnt == H_ACTIVE)
        // for each active DOOM line. Ask DMA to fetch the CURRENT DOOM line
        // (it will be ready before VGA gets there on the next v_cnt pair).
        line_pulse_vga <= 0;
        if (h_cnt == H_ACTIVE - 1 && v_cnt >= 40 && v_cnt < 440) begin
            line_pulse_vga <= 1;
            // line_num = which DOOM row is about to be displayed next
            // v_cnt at this point is the last pixel of current display row;
            // next row starts at v_cnt+1. Doom row = (v_cnt-40+1)/2 clamped.
            line_num_vga <= v_offset[8:1] < 8'd199
                            ? {1'b0, v_offset[8:1] + 8'd1}
                            : 9'd0;
        end

        // ── Line buffer read address (presented to BSRAM this cycle) ─────
        lb_rd_en   <= image_active;
        lb_rd_addr <= {lb_rd_bank, word_in_line};

        // ── 2-cycle pipeline for sub_pixel and image_active ──────────────
        sub_pixel_d1  <= sub_pixel;
        sub_pixel_d2  <= sub_pixel_d1;
        img_active_d1 <= image_active;
        img_active_d2 <= img_active_d1;

        // ── Pixel output: data is valid 2 cycles after address issued ─────
        if (img_active_d2) begin
            case (sub_pixel_d2)
                2'd0: begin RED <= lb_rd_data[7:5];   GREEN <= lb_rd_data[4:2];   BLUE <= lb_rd_data[1:0];   end
                2'd1: begin RED <= lb_rd_data[15:13];  GREEN <= lb_rd_data[12:10]; BLUE <= lb_rd_data[9:8];   end
                2'd2: begin RED <= lb_rd_data[23:21];  GREEN <= lb_rd_data[20:18]; BLUE <= lb_rd_data[17:16]; end
                2'd3: begin RED <= lb_rd_data[31:29];  GREEN <= lb_rd_data[28:26]; BLUE <= lb_rd_data[25:24]; end
            endcase
        end else begin
            RED <= 0; GREEN <= 0; BLUE <= 0;
        end
    end
end

endmodule