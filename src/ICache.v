// =============================================================================
// ICache — Direct-Mapped 8KB Instruction Cache (doubled from 4KB)
// =============================================================================
// 512 rows × 128 bit (4 instructions = 1 DDR3 burst per line)
// Index  : addr[12:4]  → 9 bit → 512 rows (no folding, clean power-of-2)
// Tag    : addr[31:13] → 19 bit  stored in tag_mem[18:0], valid = tag_mem[19]
// Offset : addr[3:2]   → 2 bit  → which of the 4 instructions
// Hit    → 2 cycles (BSRAM read latency)
// Miss   → DDR3 fetch + cache fill
// =============================================================================
module ICache (
    input  wire        clk,
    input  wire        rst_n,
    // CPU fetch request
    input  wire [31:0] cpu_addr,
    input  wire        cpu_req,
    // CPU response
    output reg  [31:0] cpu_data,
    output reg         cpu_valid,
    output wire        cache_hit,   // combinatorial
    // DDR3 miss → cache fill
    input  wire [31:0]  fill_addr,
    input  wire [127:0] fill_data,
    input  wire         fill_en
);

// ---------------------------------------------------------------------------
// Cache memory (synthesised as Gowin BSRAM)
// 512 × 128-bit data + 512 × 32-bit tag  ≈ 10 BSRAM tiles on GW2A-18
// ---------------------------------------------------------------------------
(* ram_style = "block" *) reg [127:0] data_mem [0:511];
(* ram_style = "block" *) reg [31:0]  tag_mem  [0:511]; // [19]=valid, [18:0]=tag

// ---------------------------------------------------------------------------
// Combinatorial hit detection
// ---------------------------------------------------------------------------
wire [8:0]  idx     = cpu_addr[12:4];   // 9-bit direct-mapped index
wire [18:0] req_tag = cpu_addr[31:13];  // 19-bit tag

reg [127:0] read_line;
reg [31:0]  tag_out;
reg [18:0]  req_tag_reg;
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
        // BSRAM output settles 1 cycle after read; check on the next cycle
        cache_hit_reg <= tag_out[19] & (tag_out[18:0] == req_tag_reg);
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

// ---------------------------------------------------------------------------
// Fill: write the 128-bit DDR burst into the cache line
// ---------------------------------------------------------------------------
always @(posedge clk) begin
    if (fill_en) begin
        data_mem[fill_addr[12:4]] <= fill_data;
        tag_mem [fill_addr[12:4]] <= {12'd0, 1'b1, fill_addr[31:13]};
    end
end

// ---------------------------------------------------------------------------
// Power-on initialise valid bits to 0
// ---------------------------------------------------------------------------
integer ci;
initial begin
    for (ci = 0; ci < 512; ci = ci + 1) begin
        tag_mem[ci]  = 32'd0;
        data_mem[ci] = 128'd0;
    end
end

endmodule
