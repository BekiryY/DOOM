// =============================================================================
// fb_dma.v  —  DDR Framebuffer Scan-Line DMA
// =============================================================================
// Runs in ddr_user_clk (100 MHz) domain.
// Triggered once per VGA scan line (via a CDC pulse from vga_clk).
// Fetches 320 bytes  = 20 × 128-bit DDR bursts for line `next_line_num`.
// Writes into a 160 × 32-bit dual-port line-buffer BRAM (bank 0 or 1).
//
// Framebuffer layout in DDR (CPU byte address space):
//   FB_BASE + row*320 + col  (1 byte/pixel, RGB332)
//   FB_BASE = 0x0200_0000
//   user_addr = (byte_addr) >> 1   (DDR controller unit = 8 bytes, addr >> ??)
//   Actually your DDR user_addr is in units of 8 bytes:
//     byte_addr = user_addr * 8  → user_addr = byte_addr / 8
//   One 128-bit burst = 16 bytes  → addr_increment = 2 user_addr units
//   Row start user_addr = (0x0200_0000 + row*320) / 8 = 0x040_0000 + row*40
// =============================================================================
module fb_dma (
    input  wire        clk,           // ddr_user_clk
    input  wire        rst_n,

    // ── DDR read-only bus ──────────────────────────────────────────────────
    output reg  [2:0]  ddr_cmd,       // 3'b001 = READ
    output reg         ddr_cmd_en,
    output reg  [26:0] ddr_addr,      // user_addr (8-byte units)
    input  wire        ddr_cmd_ready,

    // rd_data is pre-filtered: only our bursts arrive here (Main routes it)
    input  wire [127:0] rd_data,
    input  wire         rd_data_valid,

    // ── Line buffer write port (32-bit, runs in ddr_user_clk) ─────────────
    output reg  [7:0]  lb_wr_addr,    // [7]=bank, [6:0]=word in line (0..79)
    output reg  [31:0] lb_wr_data,
    output reg         lb_wr_en,

    // Which bank VGA should READ from (the bank we finished last)
    output reg         lb_rd_bank,

    // ── VGA CDC pulse: one pulse per scan-line start (from vga_clk domain)
    // Synchronised to ddr_user_clk by Main before arriving here.
    input  wire        line_pulse,    // 1-cycle pulse each new VGA active line
    input  wire [8:0]  line_num,      // 0..199 (which DOOM line to prefetch)

    // DMA is actively using DDR bus (used by arbiter)
    output wire        dma_busy
);

// ---------------------------------------------------------------------------
// FB base address in DDR user_addr units (8 bytes each)
//   CPU byte 0x0200_0000 / 8 = 0x040_0000
// ---------------------------------------------------------------------------
localparam [26:0] FB_BASE_UA = 27'h040_0000;
// Bytes per row = 320. user_addr per row = 320/8 = 40
localparam [6:0] UA_PER_ROW = 7'd40;
// Bursts per row = 320/16 = 20
localparam [4:0] BURSTS_PER_LINE = 5'd20;

// ---------------------------------------------------------------------------
// State machine
// ---------------------------------------------------------------------------
localparam S_IDLE      = 2'd0;
localparam S_CMD       = 2'd1;  // issue one DDR READ command
localparam S_WAIT_DATA = 2'd2;  // wait for rd_data_valid
localparam S_STORE     = 2'd3;  // write 4 words from burst into line buffer

reg [1:0]  state      = S_IDLE;
reg [4:0]  burst_cnt  = 0;      // 0..19 (which burst in this line)
reg [1:0]  word_cnt   = 0;      // 0..3  (which 32-bit word in burst)
reg        wr_bank    = 0;      // bank currently being written
reg [127:0] burst_latch = 0;

// ---------------------------------------------------------------------------
// user_addr for burst N of line L:
//   base + L*40 + N*2   (each 128-bit burst = 16 bytes = 2 user_addr units)
// ---------------------------------------------------------------------------
wire [26:0] burst_addr = FB_BASE_UA
                       + {18'd0, line_num[8:0]} * UA_PER_ROW
                       + {22'd0, burst_cnt, 1'b0};

assign dma_busy = (state != S_IDLE);

// ---------------------------------------------------------------------------
// FSM
// ---------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state       <= S_IDLE;
        burst_cnt   <= 0;
        word_cnt    <= 0;
        wr_bank     <= 0;
        lb_rd_bank  <= 0;
        ddr_cmd_en  <= 0;
        lb_wr_en    <= 0;
    end else begin
        // default pulse signals
        ddr_cmd_en <= 0;
        lb_wr_en   <= 0;

        case (state)
            // ----------------------------------------------------------------
            S_IDLE: begin
                if (line_pulse) begin
                    burst_cnt <= 0;
                    state     <= S_CMD;
                end
            end

            // ----------------------------------------------------------------
            S_CMD: begin
                if (ddr_cmd_ready) begin
                    ddr_cmd    <= 3'b001;   // READ
                    ddr_addr   <= burst_addr;
                    ddr_cmd_en <= 1;
                    state      <= S_WAIT_DATA;
                end
            end

            // ----------------------------------------------------------------
            S_WAIT_DATA: begin
                if (rd_data_valid) begin
                    burst_latch <= rd_data;
                    word_cnt    <= 0;
                    state       <= S_STORE;
                end
            end

            // ----------------------------------------------------------------
            // Write the 4 × 32-bit words from the 128-bit burst
            // word_cnt 0→[31:0], 1→[63:32], 2→[95:64], 3→[127:96]
            // lb_wr_addr = {wr_bank, burst_cnt[4:0]*4 + word_cnt}
            S_STORE: begin
                lb_wr_en   <= 1;
                lb_wr_addr <= {wr_bank, burst_cnt * 4 + {5'd0, word_cnt}};
                case (word_cnt)
                    2'd0: lb_wr_data <= burst_latch[31:0];
                    2'd1: lb_wr_data <= burst_latch[63:32];
                    2'd2: lb_wr_data <= burst_latch[95:64];
                    2'd3: lb_wr_data <= burst_latch[127:96];
                endcase
                word_cnt <= word_cnt + 2'd1;

                if (word_cnt == 2'd3) begin
                    if (burst_cnt == BURSTS_PER_LINE - 5'd1) begin
                        // All 20 bursts done → swap banks
                        lb_rd_bank <= wr_bank;    // VGA now reads the just-filled bank
                        wr_bank    <= ~wr_bank;
                        state      <= S_IDLE;
                    end else begin
                        burst_cnt <= burst_cnt + 5'd1;
                        state     <= S_CMD;
                    end
                end
            end

            default: state <= S_IDLE;
        endcase
    end
end

endmodule
