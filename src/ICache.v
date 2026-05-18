// =============================================================================
// ICache — Direct-Mapped 4KB Instruction Cache
// FIX 4: 205 satır + modulo fold yerine 256 satır power-of-2. Fold thrash kalkar.
// =============================================================================
// 256 satır × 128 bit (4 instrüksiyon = 1 DDR3 burst per line)
// Index  : addr[11:4]  → 8 bit → 256 satır
// Tag    : addr[31:12] → 20 bit
// Offset : addr[3:2]   → 2 bit  → hangi instrüksiyon
// Hit    → 2 saat (BSRAM read latency)
// Miss   → DDR3 fetch + cache doldur
// =============================================================================
module ICache (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] cpu_addr,
    input  wire        cpu_req,
    output reg  [31:0] cpu_data,
    output reg         cpu_valid,
    output wire        cache_hit,
    input  wire [31:0]  fill_addr,
    input  wire [127:0] fill_data,
    input  wire         fill_en
);

// Cache belleği (Gowin BSRAM)
(* ram_style = "block" *) reg [127:0] data_mem [0:255];
(* ram_style = "block" *) reg [31:0]  tag_mem  [0:255];

// FIX 4: Doğrudan index, fold yok
wire [7:0]  idx     = cpu_addr[11:4];
wire [19:0] req_tag = cpu_addr[31:12];

reg [127:0] read_line;
reg [31:0]  tag_out;
reg [19:0]  req_tag_reg;
reg [1:0]   word_sel;
reg         cache_hit_reg;

always @(posedge clk) begin
    if (cpu_req) begin
        read_line     <= data_mem[idx];
        tag_out       <= tag_mem[idx];
        req_tag_reg   <= req_tag;
        word_sel      <= cpu_addr[3:2];
        cache_hit_reg <= 0;
        cpu_valid     <= 0;
    end else begin
        cache_hit_reg <= tag_out[20] & (tag_out[19:0] == req_tag_reg);
        cpu_valid     <= cache_hit_reg;
        case (word_sel)
            2'd0: cpu_data <= read_line[31:0];
            2'd1: cpu_data <= read_line[63:32];
            2'd2: cpu_data <= read_line[95:64];
            2'd3: cpu_data <= read_line[127:96];
        endcase
    end
end

assign cache_hit = cache_hit_reg;

always @(posedge clk) begin
    if (fill_en) begin
        data_mem[fill_addr[11:4]] <= fill_data;
        tag_mem [fill_addr[11:4]] <= {11'd0, 1'b1, fill_addr[31:12]};
    end
end

integer ci;
initial begin
    for (ci = 0; ci < 256; ci = ci + 1) begin
        tag_mem[ci]  = 32'd0;
        data_mem[ci] = 128'd0;
    end
end

endmodule