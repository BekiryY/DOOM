
// =============================================================================
// ICache — Direct-Mapped 4KB Instruction Cache
// =============================================================================
// 256 satır × 128 bit (4 instrüksiyon = 1 DDR3 burst per line)
// Index  : addr[11:4]  → 8 bit → 256 satır
// Tag    : addr[31:12] → 20 bit
// Offset : addr[3:2]   → 2 bit  → hangi instrüksiyon
// Hit    → 2 saat (BSRAM read latency)
// Miss   → DDR3 fetch (mevcut mekanizma) + cache doldur
// =============================================================================
module ICache (
    input  wire        clk,
    input  wire        rst_n,
    // CPU fetch isteği
    input  wire [31:0] cpu_addr,
    input  wire        cpu_req,
    // CPU'ya cevap
    output reg  [31:0] cpu_data,
    output reg         cpu_valid,
    output wire        cache_hit,   // kombinasyonel
    // DDR3 miss → cache doldur
    input  wire [31:0]  fill_addr,
    input  wire [127:0] fill_data,
    input  wire         fill_en
);

// ---------------------------------------------------------------------------
// Cache belleği (Gowin BSRAM olarak sentezlenir)
// ---------------------------------------------------------------------------
reg [127:0] data_mem [0:255];
reg [20:0]  tag_mem  [0:255];   // [20]=valid, [19:0]=tag

// ---------------------------------------------------------------------------
// Kombinasyonel hit tespiti
// ---------------------------------------------------------------------------
wire [7:0]  idx      = cpu_addr[11:4];
wire [19:0] req_tag  = cpu_addr[31:12];
wire        hit_v    = tag_mem[idx][20];
wire [19:0] hit_tag  = tag_mem[idx][19:0];

assign cache_hit = hit_v & (hit_tag == req_tag);

// ---------------------------------------------------------------------------
// Hit: BSRAM okuma (1 saat gecikme)
// ---------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cpu_data  <= 32'd0;
        cpu_valid <= 1'b0;
    end else begin
        cpu_valid <= 1'b0;
        if (cpu_req & cache_hit) begin
            case (cpu_addr[3:2])
                2'd0: cpu_data <= data_mem[idx][31:0];
                2'd1: cpu_data <= data_mem[idx][63:32];
                2'd2: cpu_data <= data_mem[idx][95:64];
                2'd3: cpu_data <= data_mem[idx][127:96];
            endcase
            cpu_valid <= 1'b1;
        end
    end
end

// ---------------------------------------------------------------------------
// Fill: DDR3'ten gelen 128-bit burst cache'e yaz
// ---------------------------------------------------------------------------
always @(posedge clk) begin
    if (fill_en) begin
        data_mem[fill_addr[11:4]] <= fill_data;
        tag_mem [fill_addr[11:4]] <= {1'b1, fill_addr[31:12]};
    end
end

// ---------------------------------------------------------------------------
// Reset: valid bitleri temizle (initial block — Gowin destekler)
// ---------------------------------------------------------------------------
integer ci;
initial begin
    for (ci = 0; ci < 256; ci = ci + 1) begin
        tag_mem[ci]  = 21'd0;
        data_mem[ci] = 128'd0;
    end
end

endmodule
