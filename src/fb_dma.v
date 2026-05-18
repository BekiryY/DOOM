// =============================================================================
// fb_dma.v  —  DDR Framebuffer Scan-Line DMA
// FIX 5: FB_BASE_UA artık dışarıdan gelen input (double-buffer için).
// =============================================================================
module fb_dma (
    input  wire        clk,
    input  wire        rst_n,

    output reg  [2:0]  ddr_cmd,
    output reg         ddr_cmd_en,
    output reg  [26:0] ddr_addr,
    input  wire        ddr_cmd_ready,

    input  wire [127:0] rd_data,
    input  wire         rd_data_valid,

    output reg  [7:0]  lb_wr_addr,
    output reg  [31:0] lb_wr_data,
    output reg         lb_wr_en,

    output reg         lb_rd_bank,

    input  wire        line_pulse,
    input  wire [8:0]  line_num,

    output wire        dma_busy,

    // FIX 5: Aktif FB tabanı (user_addr, 8-byte birimleri)
    // 0x040_0000 = byte 0x0200_0000 (FB_A)
    // 0x049_6000 = byte 0x024B_0000 (FB_B) — yazılım swap edebilir
    input  wire [26:0] fb_base_ua
);

localparam [6:0] UA_PER_ROW = 7'd40;
localparam [4:0] BURSTS_PER_LINE = 5'd20;

localparam S_IDLE      = 2'd0;
localparam S_CMD       = 2'd1;
localparam S_WAIT_DATA = 2'd2;
localparam S_STORE     = 2'd3;

reg [1:0]   state      = S_IDLE;
reg [4:0]   burst_cnt  = 0;
reg [1:0]   word_cnt   = 0;
reg         wr_bank    = 0;
reg [127:0] burst_latch = 0;

// FIX 5: fb_base_ua input'tan
wire [26:0] burst_addr = fb_base_ua
                       + {18'd0, line_num[8:0]} * UA_PER_ROW
                       + {22'd0, burst_cnt, 1'b0};

assign dma_busy = (state != S_IDLE);

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
        ddr_cmd_en <= 0;
        lb_wr_en   <= 0;

        case (state)
            S_IDLE: begin
                if (line_pulse) begin
                    burst_cnt <= 0;
                    state     <= S_CMD;
                end
            end

            S_CMD: begin
                if (ddr_cmd_ready) begin
                    ddr_cmd    <= 3'b001;
                    ddr_addr   <= burst_addr;
                    ddr_cmd_en <= 1;
                    state      <= S_WAIT_DATA;
                end
            end

            S_WAIT_DATA: begin
                if (rd_data_valid) begin
                    burst_latch <= rd_data;
                    word_cnt    <= 0;
                    state       <= S_STORE;
                end
            end

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
                        lb_rd_bank <= wr_bank;
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