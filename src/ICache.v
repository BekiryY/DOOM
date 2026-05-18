// =============================================================================
// ICache.v — Direct-Mapped 4KB Instruction Cache for DOOM FPGA
// =============================================================================
//
// Tasarım:
//   256 satır × 128 bit (4 instrüksiyon per line, 1 DDR3 burst)
//   Index  : addr[11:4]  → 8 bit → 256 satır
//   Tag    : addr[31:12] → 20 bit
//   Offset : addr[3:2]   → 2 bit  → hangi instrüksiyon
//
// Hit  → 2 saat (BSRAM read latency)
// Miss → DDR3 fetch (mevcut mekanizma) + cache doldur
//
// BSRAM kullanımı: ~3 blok (data + tag)
// =============================================================================
module ICache (
    input  wire        clk,
    input  wire        rst_n,

    // CPU'dan gelen fetch isteği
    input  wire [31:0] cpu_addr,    // instrüksiyon adresi
    input  wire        cpu_req,     // 1 = fetch isteği var

    // CPU'ya dönen cevap
    output reg  [31:0] cpu_data,    // instrüksiyon
    output reg         cpu_valid,   // 1 = geçerli data
    output wire        cache_hit,   // 1 = hit (kombinasyonel)

    // DDR3 miss sonrası cache doldurma
    input  wire [31:0]  fill_addr,   // doldurulacak adres
    input  wire [127:0] fill_data,   // DDR3'ten gelen 4×32-bit burst
    input  wire         fill_en      // 1 = yaz
);

// ---------------------------------------------------------------------------
// 1. Cache belleği (Gowin BRAM olarak sentezlenir)
// ---------------------------------------------------------------------------
// Data BRAM: 256 × 128 bit
reg [127:0] data_mem [0:255];

// Tag BRAM: 256 × 21 bit (20-bit tag + 1-bit valid)
reg [20:0]  tag_mem  [0:255];

// ---------------------------------------------------------------------------
// 2. Kombinasyonel hit tespiti
// ---------------------------------------------------------------------------
wire [7:0]  idx     = cpu_addr[11:4];
wire [19:0] tag     = cpu_addr[31:12];
wire [1:0]  word_sel= cpu_addr[3:2];

wire        tag_valid   = tag_mem[idx][20];
wire [19:0] stored_tag  = tag_mem[idx][19:0];

assign cache_hit = cpu_req & tag_valid & (stored_tag == tag);

// ---------------------------------------------------------------------------
// 3. Hit: Data servis
// ---------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cpu_data  <= 32'd0;
        cpu_valid <= 1'b0;
    end else begin
        cpu_valid <= 1'b0;

        if (cpu_req & cache_hit) begin
            // 1 saat gecikme ile instrüksiyonu sun
            case (word_sel)
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
// 4. Miss → Fill (DDR3'ten gelen 128-bit burst cache'e yazılır)
// ---------------------------------------------------------------------------
always @(posedge clk) begin
    if (fill_en) begin
        data_mem[fill_addr[11:4]] <= fill_data;
        tag_mem [fill_addr[11:4]] <= {1'b1, fill_addr[31:12]};
    end
end

// ---------------------------------------------------------------------------
// 5. Reset: valid bitleri temizle
// ---------------------------------------------------------------------------
integer i;
initial begin
    for (i = 0; i < 256; i = i + 1) begin
        tag_mem[i]  = 21'd0;  // valid=0
        data_mem[i] = 128'd0;
    end
end

endmodule
