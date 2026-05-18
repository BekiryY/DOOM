module Main_Computer(
    input sys_clk,
    input sys_rst_n,
    input MISO,
    input PS2_DATA_I,
    input PS2_CLK_I,
    output PS2_DATA_DEBUG,
    output PS2_CLK_DEBUG,
    input RX,
    output TX,
    output wire MOSI,
    output wire SPI_CS,
    output wire SPI_CLK,
    output wire debug_cs,
    output wire debug_clk,
    output wire debug_mosi,
    output wire debug_miso,

    output [13:0] ddr_addr,
    output [2:0]  ddr_bank,
    output        ddr_cs,
    output        ddr_ras,
    output        ddr_cas,
    output        ddr_we,
    output        ddr_ck,
    output        ddr_ck_n,
    output        ddr_cke,
    output        ddr_odt,
    output        ddr_reset_n,
    output [1:0]  ddr_dm,
    inout  [15:0] ddr_dq,
    inout  [1:0]  ddr_dqs,
    inout  [1:0]  ddr_dqs_n,

    output wire        tmds_clk_p,
    output wire        tmds_clk_n,
    output wire [2:0]  tmds_data_p,
    output wire [2:0]  tmds_data_n
);

assign debug_cs = SPI_CS;
assign debug_clk = SPI_CLK;
assign debug_mosi = MOSI;
assign debug_miso = MISO;

assign PS2_DATA_DEBUG = ~PS2_DATA_I;
assign PS2_CLK_DEBUG = ~PS2_CLK_I;

// ==============================================================================
// 1. ARBITER (3-way: fb_dma > cpu > boot)
// ==============================================================================
wire [2:0]   ddr_cmd;
wire         ddr_cmd_en;
wire [26:0]  user_addr;
wire [127:0] ddr_wr_data;
wire         ddr_wr_data_en;
wire         ddr_wr_data_end;
wire [15:0]  ddr_wr_data_mask;
wire [7:0]   uart_data;
wire         uart_wr_en;

reg boot_done = 0;
wire cpu_done;

wire [2:0]   cpu_ddr_cmd;
wire         cpu_ddr_cmd_en;
wire [26:0]  cpu_user_addr;
wire [127:0] cpu_ddr_wr_data;
wire         cpu_ddr_wr_data_en;
wire         cpu_ddr_wr_data_end;
wire [15:0]  cpu_ddr_wr_data_mask;
wire [7:0]   cpu_uart_data;
wire         cpu_uart_wr_en;

// FIX 5: CPU'dan FB swap istekleri
wire [31:0]  cpu_fb_swap_data;
wire         cpu_fb_swap_en;

wire [2:0]  fb_ddr_cmd;
wire        fb_ddr_cmd_en;
wire [26:0] fb_ddr_addr;
wire        fb_dma_busy;

wire cpu_active = (boot_done == 1 && cpu_done == 0);

assign ddr_cmd          = fb_dma_busy    ? fb_ddr_cmd          :
                          cpu_active     ? cpu_ddr_cmd          : boot_ddr_cmd;
assign ddr_cmd_en       = fb_dma_busy    ? fb_ddr_cmd_en        :
                          cpu_active     ? cpu_ddr_cmd_en       : boot_ddr_cmd_en;
assign user_addr        = fb_dma_busy    ? fb_ddr_addr          :
                          cpu_active     ? cpu_user_addr        : boot_user_addr;
assign ddr_wr_data      = cpu_active     ? cpu_ddr_wr_data      : boot_ddr_wr_data;
assign ddr_wr_data_en   = cpu_active     ? cpu_ddr_wr_data_en   : boot_ddr_wr_data_en;
assign ddr_wr_data_end  = cpu_active     ? cpu_ddr_wr_data_end  : boot_ddr_wr_data_end;
assign ddr_wr_data_mask = cpu_active     ? cpu_ddr_wr_data_mask : boot_ddr_wr_data_mask;
assign uart_data        = cpu_active     ? cpu_uart_data        : boot_uart_data;
assign uart_wr_en       = cpu_active     ? cpu_uart_wr_en       : boot_uart_wr_en;

// ==============================================================================
// FIX 5: Aktif framebuffer tabanı registri (yazılım kontrollü)
// IO 0x4050_0000'a yazma → byte adresini user_addr birimine çevirip latch
// Reset değeri: FB_A = 0x0200_0000 / 8 = 0x040_0000
// FB_B önerilen değer: 0x024B_0000 / 8 = 0x049_6000 (320*200=64000 byte ofset)
// ==============================================================================
reg [26:0] active_fb_ua = 27'h040_0000;

always @(posedge ddr_user_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        active_fb_ua <= 27'h040_0000;
    end else if (cpu_fb_swap_en) begin
        // byte adresi → user_addr (8-byte birimleri): shift right by 3
        active_fb_ua <= cpu_fb_swap_data[29:3];
    end
end

// DDR read-data ownership FIFO
reg [3:0] own_fifo  = 4'b0000;
reg [1:0] own_head  = 2'd0;
reg [1:0] own_tail  = 2'd0;

wire any_read_cmd = ddr_cmd_en && (ddr_cmd == 3'b001);
wire is_dma_cmd   = fb_dma_busy && fb_ddr_cmd_en && (fb_ddr_cmd == 3'b001);

always @(posedge ddr_user_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        own_fifo <= 4'b0;
        own_head <= 2'd0;
        own_tail <= 2'd0;
    end else begin
        if (any_read_cmd) begin
            own_fifo[own_head] <= is_dma_cmd ? 1'b1 : 1'b0;
            own_head <= own_head + 2'd1;
        end
        if (ddr_rd_data_valid) begin
            own_tail <= own_tail + 2'd1;
        end
    end
end

wire current_owner = own_fifo[own_tail];
wire cpu_rd_data_valid = ddr_rd_data_valid && (current_owner == 1'b0);
wire dma_rd_data_valid = ddr_rd_data_valid && (current_owner == 1'b1);

wire [31:0]  ps2_data;
wire [31:0]  ps2_key_event;
wire         ps2_key_ev_valid;

// ==============================================================================
// 2. DDR3
// ==============================================================================
wire ddr_memory_clk;
wire ddr_pll_lock;
wire ddr_user_clk;
wire ddr_logic_rst;
wire ddr_calib_complete;
wire ddr_cmd_ready;
wire ddr_wr_data_rdy;
wire [127:0] ddr_rd_data;
wire ddr_rd_data_valid;
wire ddr_rd_data_end;

wire        icache_hit;
wire [31:0] icache_data;
wire        icache_valid;
wire        icache_fill_en;
wire [31:0] icache_fill_addr;
wire [127:0] icache_fill_data;
wire        icache_req;
wire [31:0] program_counter;

ICache icache_inst (
    .clk       (ddr_user_clk),
    .rst_n     (sys_rst_n),
    .cpu_addr  (program_counter),
    .cpu_req   (icache_req),
    .cpu_data  (icache_data),
    .cpu_valid (icache_valid),
    .cache_hit (icache_hit),
    .fill_addr (icache_fill_addr),
    .fill_data (icache_fill_data),
    .fill_en   (icache_fill_en)
);

wire lock_270;
wire clk_270;

rpll_270 rpll_270_inst(
        .clkout(clk_270),
        .lock(lock_270),
        .clkin(sys_clk)
);

Gowin_rPLL r_clock(
    .clkout(ddr_memory_clk),
    .lock(ddr_pll_lock),
    .reset(~sys_rst_n),
    .clkin(clk_270)
);

DDR3_Memory_Interface_Top main_ram(
    .clk(sys_clk),
    .memory_clk(ddr_memory_clk),
    .pll_lock(ddr_pll_lock & lock_270),
    .rst_n(sys_rst_n),
    .clk_out(ddr_user_clk),
    .ddr_rst(ddr_logic_rst),
    .init_calib_complete(ddr_calib_complete),
    .app_burst_number(6'b000000),
    .cmd_ready(ddr_cmd_ready),
    .cmd(ddr_cmd),
    .cmd_en(ddr_cmd_en),
    .addr({1'b0, user_addr}),
    .wr_data_rdy(ddr_wr_data_rdy),
    .wr_data(ddr_wr_data),
    .wr_data_en(ddr_wr_data_en),
    .wr_data_end(ddr_wr_data_end),
    .wr_data_mask(ddr_wr_data_mask),
    .rd_data(ddr_rd_data),
    .rd_data_valid(ddr_rd_data_valid),
    .rd_data_end(ddr_rd_data_end),
    .sr_req(1'b0),
    .ref_req(1'b0),
    .sr_ack(),
    .ref_ack(),
    .burst(1'b0),
    .O_ddr_addr(ddr_addr),
    .O_ddr_ba(ddr_bank),
    .O_ddr_cs_n(ddr_cs),
    .O_ddr_ras_n(ddr_ras),
    .O_ddr_cas_n(ddr_cas),
    .O_ddr_we_n(ddr_we),
    .O_ddr_clk(ddr_ck),
    .O_ddr_clk_n(ddr_ck_n),
    .O_ddr_cke(ddr_cke),
    .O_ddr_odt(ddr_odt),
    .O_ddr_reset_n(ddr_reset_n),
    .O_ddr_dqm(ddr_dm),
    .IO_ddr_dq(ddr_dq),
    .IO_ddr_dqs(ddr_dqs),
    .IO_ddr_dqs_n(ddr_dqs_n)
);

// ==============================================================================
// 3. UART
// ==============================================================================
wire uart_write_done;
wire       uart_key_ready;
wire [7:0] uart_key_data;

UART_Controller #(
    .BAUD_RATE(1000000),
    .CLOCK_FREQ(100000000)
) debug_uart (
    .sys_clk(ddr_user_clk),
    .sys_rst_n(sys_rst_n),
    .write_enable(uart_wr_en),
    .data_to_send(uart_data),
    .RX(RX),
    .TX(TX),
    .write_done(uart_write_done),
    .read_done(uart_key_ready),
    .data_readed(uart_key_data)
);

// ==============================================================================
// 4. SPI
// ==============================================================================
reg spi_read_enable = 0;
reg [7:0] spi_cmd = 8'h03;
reg [23:0] spi_address = 24'h10_00_00;
reg [7:0] spi_total_bits = 160;
wire [127:0] spi_128bit_data;
wire spi_done;

SPI_Controller spi_inst (
    .sys_clk(ddr_user_clk),
    .sys_rst_n(sys_rst_n),
    .MISO(MISO),
    .read_enable(spi_read_enable),
    .command(spi_cmd),
    .address(spi_address),
    .total_bits(spi_total_bits),
    .data_readed(spi_128bit_data),
    .MOSI(MOSI),
    .CS(SPI_CS),
    .CLK(SPI_CLK),
    .done(spi_done)
);

// ==============================================================================
// 5. BOOTLOADER
// ==============================================================================
localparam B_BOOT_DELAY      = 4'd0;
localparam B_WAIT_CALIB      = 4'd1;
localparam B_UART_SEND       = 4'd2;
localparam B_UART_WAIT_DONE  = 4'd3;
localparam B_SPI_START       = 4'd4;
localparam B_SPI_WAIT        = 4'd5;
localparam B_DDR_WAIT        = 4'd6;
localparam B_DDR_WRITE       = 4'd7;
localparam B_CS_HOLD         = 4'd8;
localparam B_CHECK_PROGRESS  = 4'd9;
localparam B_HALT            = 4'd10;

reg [3:0]  b_state = B_BOOT_DELAY;
reg [3:0]  b_return_state = B_BOOT_DELAY;
reg [24:0] timer = 0;
reg [1:0]  boot_byte_idx = 0;
reg [31:0] boot_uart_msg = 0;
reg [17:0] progress_counter = 0;

reg [2:0]   boot_ddr_cmd = 0;
reg         boot_ddr_cmd_en = 0;
reg [26:0]  boot_user_addr = 0;
reg [127:0] boot_ddr_wr_data = 0;
reg         boot_ddr_wr_data_en = 0;
reg         boot_ddr_wr_data_end = 0;
reg [7:0]   boot_uart_data = 0;
reg         boot_uart_wr_en = 0;

wire [15:0] boot_ddr_wr_data_mask = 16'h0000;

always @(posedge ddr_user_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        b_state <= B_BOOT_DELAY;
        spi_read_enable <= 0;
        boot_uart_wr_en <= 0;
        spi_address <= 24'h10_00_00;
        boot_user_addr <= 27'd0;
        boot_ddr_cmd_en <= 0;
        boot_ddr_wr_data_en <= 0;
        boot_ddr_wr_data_end <= 0;
        timer <= 0;
        boot_byte_idx <= 0;
        progress_counter <= 0;
        boot_done <= 0;
    end else if (!boot_done) begin
        case (b_state)
            B_BOOT_DELAY: begin
                if (timer >= 1_000_000) begin
                    timer <= 0;
                    boot_uart_msg <= 32'hDE_AD_BE_EF;
                    b_return_state <= B_WAIT_CALIB;
                    b_state <= B_UART_SEND;
                end else begin
                    timer <= timer + 25'd1;
                end
            end

            B_WAIT_CALIB: begin
                if (ddr_calib_complete) begin
                    boot_uart_msg <= 32'h44_44_52_33;
                    b_return_state <= B_SPI_START;
                    b_state <= B_UART_SEND;
                end
            end

            B_UART_SEND: begin
                case (boot_byte_idx)
                    2'd0: boot_uart_data <= boot_uart_msg[31:24];
                    2'd1: boot_uart_data <= boot_uart_msg[23:16];
                    2'd2: boot_uart_data <= boot_uart_msg[15:8];
                    2'd3: boot_uart_data <= boot_uart_msg[7:0];
                endcase
                boot_uart_wr_en <= 1;
                b_state <= B_UART_WAIT_DONE;
            end

            B_UART_WAIT_DONE: begin
                if (uart_write_done) begin
                    boot_uart_wr_en <= 0;
                    if (boot_byte_idx == 3) begin
                        boot_byte_idx <= 0;
                        b_state <= b_return_state;
                    end else begin
                        boot_byte_idx <= boot_byte_idx + 2'd1;
                        b_state <= B_UART_SEND;
                    end
                end
            end

            B_SPI_START: begin
                spi_cmd <= 8'h03;
                spi_total_bits <= 160;
                spi_read_enable <= 1;
                b_state <= B_SPI_WAIT;
            end

            B_SPI_WAIT: begin
                if (spi_done) begin
                    spi_read_enable <= 0;
                    b_state <= B_DDR_WAIT;
                end
            end

            B_DDR_WAIT: begin
                if (ddr_cmd_ready && ddr_wr_data_rdy) begin
                    boot_ddr_cmd <= 3'b000;
                    boot_ddr_cmd_en <= 1;
                    boot_ddr_wr_data <= spi_128bit_data;
                    boot_ddr_wr_data_en <= 1;
                    boot_ddr_wr_data_end <= 1;
                    b_state <= B_DDR_WRITE;
                end
            end

            B_DDR_WRITE: begin
                boot_ddr_cmd_en <= 0;
                boot_ddr_wr_data_en <= 0;
                boot_ddr_wr_data_end <= 0;
                spi_address <= spi_address + 24'd16;
                boot_user_addr <= boot_user_addr + 27'd8;
                progress_counter <= progress_counter + 18'd16;
                timer <= 0;
                b_state <= B_CS_HOLD;
            end

            B_CS_HOLD: begin
                if (timer >= 50) begin
                    b_state <= B_CHECK_PROGRESS;
                end else begin
                    timer <= timer + 25'd1;
                end
            end

            B_CHECK_PROGRESS: begin
                if (spi_address >= 24'h80_00_00) begin
                    boot_uart_msg <= 32'h44_4F_4E_45;
                    b_return_state <= B_HALT;
                    b_state <= B_UART_SEND;
                end
                else if (progress_counter >= 102400) begin
                    progress_counter <= 0;
                    boot_uart_msg <= 32'h2B_2B_2B_2B;
                    b_return_state <= B_SPI_START;
                    b_state <= B_UART_SEND;
                end
                else begin
                    b_state <= B_SPI_START;
                end
            end

            B_HALT: begin
                boot_done <= 1;
                b_state <= B_HALT;
            end

            default: b_state <= B_BOOT_DELAY;
        endcase
    end
    else if (cpu_done && ps2_data[4] && ps2_data[7]) begin
        b_state <= B_BOOT_DELAY;
        spi_read_enable <= 0;
        boot_uart_wr_en <= 0;
        spi_address <= 24'h10_00_00;
        boot_user_addr <= 27'd0;
        boot_ddr_cmd_en <= 0;
        boot_ddr_wr_data_en <= 0;
        boot_ddr_wr_data_end <= 0;
        timer <= 0;
        boot_byte_idx <= 0;
        progress_counter <= 0;
        boot_done <= 0;
    end
end

// ==============================================================================
// Keyboard
// ==============================================================================
PS2_Controller keyboard (
    .sys_clk(ddr_user_clk),
    .sys_rst_n(sys_rst_n),
    .PS2_D_I(PS2_DATA_I),
    .PS2_CLK_I(PS2_CLK_I),
    .uart_key_ready(uart_key_ready),
    .uart_key_data(uart_key_data),
    .DOOM_KEYS(ps2_data),
    .KEY_EVENT(ps2_key_event),
    .KEY_EV_VALID(ps2_key_ev_valid)
);

// ==============================================================================
// HDMI
// ==============================================================================
wire hdmi_serial_clk;
wire vga_clk;
wire vga_lock;

Gowin_rPLL_VGA u_Gowin_rPLL_VGA (
    .clkin(sys_clk),
    .lock(vga_lock),
    .reset(~sys_rst_n),
    .clkout(hdmi_serial_clk)
);

CLKDIV u_clkdiv5 (
    .HCLKIN (hdmi_serial_clk),
    .CLKOUT (vga_clk),
    .RESETN (sys_rst_n),
    .CALIB  (1'b1)
);
defparam u_clkdiv5.DIV_MODE = "5";
defparam u_clkdiv5.GSREN    = "false";

wire hdmi_rst_n = sys_rst_n & vga_lock;

wire [7:0]  lb_rd_addr;
wire        lb_rd_en;
wire [31:0] lb_rd_data;
wire        lb_rd_bank;
wire        line_pulse_vga;
wire [8:0]  line_num_vga;
wire        hdmi_vsync;

HDMI_Top u_hdmi (
    .pix_clk        (vga_clk),
    .tmds_clk       (hdmi_serial_clk),
    .sys_rst_n      (hdmi_rst_n),
    .lb_rd_addr     (lb_rd_addr),
    .lb_rd_en       (lb_rd_en),
    .lb_rd_data     (lb_rd_data),
    .lb_rd_bank     (lb_rd_bank),
    .line_pulse_out (line_pulse_vga),
    .line_num_out   (line_num_vga),
    .vsync_out      (hdmi_vsync),
    .tmds_clk_p     (tmds_clk_p),
    .tmds_clk_n     (tmds_clk_n),
    .tmds_data_p    (tmds_data_p),
    .tmds_data_n    (tmds_data_n)
);

// CDC: line_pulse_vga (vga_clk) → ddr_user_clk
reg        lp_toggle_vga = 0;
reg [8:0]  ln_latch_vga  = 0;

always @(posedge vga_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        lp_toggle_vga <= 0;
        ln_latch_vga  <= 0;
    end else if (line_pulse_vga) begin
        lp_toggle_vga <= ~lp_toggle_vga;
        ln_latch_vga  <= line_num_vga;
    end
end

reg lp_sync1 = 0, lp_sync2 = 0, lp_sync3 = 0;
always @(posedge ddr_user_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) {lp_sync3, lp_sync2, lp_sync1} <= 3'b0;
    else            {lp_sync3, lp_sync2, lp_sync1} <= {lp_sync2, lp_sync1, lp_toggle_vga};
end
wire dma_line_pulse_raw = lp_sync2 ^ lp_sync3;
wire dma_line_pulse = dma_line_pulse_raw && boot_done;

reg [8:0] dma_line_num = 0;
always @(posedge ddr_user_clk) begin
    if (dma_line_pulse) dma_line_num <= ln_latch_vga;
end

// ==============================================================================
// Sistem Timer
// ==============================================================================
reg [31:0] ms_counter = 0;
reg [16:0] tick_counter = 0;

always @(posedge ddr_user_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        ms_counter <= 32'd0;
        tick_counter <= 17'd0;
    end else if (boot_done && !cpu_done) begin
        if (tick_counter >= 17'd99_999) begin
            tick_counter <= 17'd0;
            ms_counter <= ms_counter + 1;
        end else begin
            tick_counter <= tick_counter + 17'd1;
        end
    end
    else if (cpu_done && ps2_data[4] && ps2_data[7]) begin
        ms_counter <= 32'd0;
        tick_counter <= 17'd0;
    end
end

// ==============================================================================
// CPU
// ==============================================================================
cpu u_cpu (
    .clk                 (ddr_user_clk),
    .rst_n               (sys_rst_n),
    .boot_done           (boot_done),
    .cpu_done            (cpu_done),

    .ddr_cmd_ready       (ddr_cmd_ready && !fb_dma_busy),
    .ddr_rd_data_valid   (cpu_rd_data_valid),
    .ddr_rd_data         (ddr_rd_data),
    .ddr_wr_data_rdy     (ddr_wr_data_rdy),

    .cpu_ddr_cmd         (cpu_ddr_cmd),
    .cpu_ddr_cmd_en      (cpu_ddr_cmd_en),
    .cpu_user_addr       (cpu_user_addr),
    .cpu_ddr_wr_data     (cpu_ddr_wr_data),
    .cpu_ddr_wr_data_en  (cpu_ddr_wr_data_en),
    .cpu_ddr_wr_data_end (cpu_ddr_wr_data_end),
    .cpu_ddr_wr_data_mask(cpu_ddr_wr_data_mask),

    .uart_write_done     (uart_write_done),
    .cpu_uart_data       (cpu_uart_data),
    .cpu_uart_wr_en      (cpu_uart_wr_en),

    .program_counter     (program_counter),
    .icache_req          (icache_req),
    .icache_fill_en      (icache_fill_en),
    .icache_fill_addr    (icache_fill_addr),
    .icache_fill_data    (icache_fill_data),

    .icache_data         (icache_data),
    .icache_valid        (icache_valid),

    .ps2_data            (ps2_data),
    .ps2_key_event       (ps2_key_event),
    .ms_counter          (ms_counter),
    .hdmi_vsync          (hdmi_vsync),

    // FIX 5: FB swap çıkışları
    .cpu_fb_swap_data    (cpu_fb_swap_data),
    .cpu_fb_swap_en      (cpu_fb_swap_en)
);

// ==============================================================================
// LINE BUFFER
// ==============================================================================
(* ram_style = "block" *) reg [31:0] line_buf [0:159];

wire [7:0]  lb_wr_addr;
wire [31:0] lb_wr_data;
wire        lb_wr_en;

always @(posedge ddr_user_clk) begin
    if (lb_wr_en) line_buf[lb_wr_addr] <= lb_wr_data;
end

reg [7:0]  lb_rd_addr_r1 = 0;
reg [31:0] lb_rd_data_r  = 0;

always @(posedge vga_clk) begin
    if (lb_rd_en) begin
        lb_rd_addr_r1 <= lb_rd_addr;
    end
    lb_rd_data_r <= line_buf[lb_rd_addr_r1];
end

assign lb_rd_data = lb_rd_data_r;

// ==============================================================================
// FB_DMA  (FIX 5: fb_base_ua bağlı)
// ==============================================================================
fb_dma u_fb_dma (
    .clk            (ddr_user_clk),
    .rst_n          (sys_rst_n),
    .ddr_cmd        (fb_ddr_cmd),
    .ddr_cmd_en     (fb_ddr_cmd_en),
    .ddr_addr       (fb_ddr_addr),
    .ddr_cmd_ready  (ddr_cmd_ready),
    .rd_data        (ddr_rd_data),
    .rd_data_valid  (dma_rd_data_valid),
    .lb_wr_addr     (lb_wr_addr),
    .lb_wr_data     (lb_wr_data),
    .lb_wr_en       (lb_wr_en),
    .lb_rd_bank     (lb_rd_bank),
    .line_pulse     (dma_line_pulse),
    .line_num       (dma_line_num),
    .dma_busy       (fb_dma_busy),
    .fb_base_ua     (active_fb_ua)   // FIX 5
);

endmodule