// =============================================================================
// PS2_Controller.v  — GoWin Tang Primer 20K  DOOM FPGA
// =============================================================================
// FIX 1: UART read_done bir çok saat yüksek kalıyordu (level, pulse değil).
//        Bu yüzden ilk byte (0x01 header) hem header hem bit_index olarak
//        yorumlanıyor, phantom DOWN tuşu üretiyordu. Edge detect ile pulse
//        yarat ve sadece 1 saat boyunca işle.
// =============================================================================
module PS2_Controller(
    input  wire        sys_clk,
    input  wire        sys_rst_n,
    input  wire        PS2_D_I,
    input  wire        PS2_CLK_I,
    input  wire        uart_key_ready,
    input  wire [7:0]  uart_key_data,
    output reg  [31:0] DOOM_KEYS    = 32'd0,
    output reg  [31:0] KEY_EVENT    = 32'd0,
    output reg         KEY_EV_VALID = 1'b0
);

// ── Level shift ────────────────────────────────────────────────────────────
wire ps2_d_raw   = ~PS2_D_I;
wire ps2_clk_raw = ~PS2_CLK_I;

// ── Debounce ───────────────────────────────────────────────────────────────
reg [4:0] clk_filt = 0, dat_filt = 0;
reg ps2_clk_c = 1, ps2_dat_c = 1;

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        clk_filt <= 0; dat_filt <= 0;
        ps2_clk_c <= 1; ps2_dat_c <= 1;
    end else begin
        if (ps2_clk_raw) begin
            if (clk_filt != 5'h1F) clk_filt <= clk_filt + 5'd1;
            else ps2_clk_c <= 1;
        end else begin
            if (clk_filt != 5'h00) clk_filt <= clk_filt - 5'd1;
            else ps2_clk_c <= 0;
        end
        if (ps2_d_raw) begin
            if (dat_filt != 5'h1F) dat_filt <= dat_filt + 5'd1;
            else ps2_dat_c <= 1;
        end else begin
            if (dat_filt != 5'h00) dat_filt <= dat_filt - 5'd1;
            else ps2_dat_c <= 0;
        end
    end
end

reg  ps2_clk_prev = 1;
wire clk_fall     = (~ps2_clk_c & ps2_clk_prev);

reg [17:0] timeout_cnt = 0;
wire       timed_out   = (timeout_cnt >= 18'd200_000);

reg [10:0] shift_reg  = 0;
reg [3:0]  bit_cnt    = 0;
reg [7:0]  ps2_byte   = 0;
reg        byte_rdy   = 0;

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        ps2_clk_prev <= 1; shift_reg <= 0; bit_cnt <= 0;
        ps2_byte <= 0; byte_rdy <= 0; timeout_cnt <= 0;
    end else begin
        ps2_clk_prev <= ps2_clk_c;
        byte_rdy     <= 0;

        if (bit_cnt > 0) begin
            timeout_cnt <= timeout_cnt + 18'd1;
            if (timed_out) begin bit_cnt <= 0; timeout_cnt <= 0; end
        end else begin
            timeout_cnt <= 0;
        end

        if (clk_fall) begin
            timeout_cnt <= 0;
            if (bit_cnt == 0) begin
                if (!ps2_dat_c) begin
                    shift_reg[0] <= 0;
                    bit_cnt <= 1;
                end
            end else begin
                shift_reg[bit_cnt] <= ps2_dat_c;
                if (bit_cnt == 10) begin
                    if (shift_reg[0] == 0 && ps2_dat_c == 1) begin
                        ps2_byte <= shift_reg[8:1];
                        byte_rdy <= 1;
                    end
                    bit_cnt <= 0;
                end else begin
                    bit_cnt <= bit_cnt + 4'd1;
                end
            end
        end
    end
end

localparam S_IDLE = 2'd0;
localparam S_EXT  = 2'd1;
localparam S_REL  = 2'd2;

reg [1:0] dec_st = S_IDLE;
reg       is_ext = 0;

// ── doomkey değerleri ──────────────────────────────────────────────────────
localparam [7:0] DK_UP    = 8'hAD;
localparam [7:0] DK_DOWN  = 8'hAF;
localparam [7:0] DK_LEFT  = 8'hAC;
localparam [7:0] DK_RIGHT = 8'hAE;
localparam [7:0] DK_FIRE  = 8'hA3;
localparam [7:0] DK_USE   = 8'hA2;
localparam [7:0] DK_SHIFT = 8'hB6;
localparam [7:0] DK_ESC   = 8'd27;
localparam [7:0] DK_ENTER = 8'd13;
localparam [7:0] DK_TAB   = 8'd9;
localparam [7:0] DK_ALT   = 8'hB8;
localparam [7:0] DK_F1    = 8'hBB;
localparam [7:0] DK_F2    = 8'hBC;
localparam [7:0] DK_F3    = 8'hBD;
localparam [7:0] DK_F4    = 8'hBE;
localparam [7:0] DK_F5    = 8'hBF;
localparam [7:0] DK_F6    = 8'hC0;
localparam [7:0] DK_F7    = 8'hC1;
localparam [7:0] DK_F8    = 8'hC2;
localparam [7:0] DK_F9    = 8'hC3;
localparam [7:0] DK_F10   = 8'hC4;
localparam [7:0] DK_PLUS  = 8'h3D;
localparam [7:0] DK_MINUS = 8'h2D;
localparam [7:0] DK_NONE  = 8'h00;

function [12:0] scan2doom;
    input       ext;
    input [7:0] sc;
    begin
        case ({ext, sc})
            {1'b0, 8'h1D}: scan2doom = {5'd0,  DK_UP};
            {1'b0, 8'h1B}: scan2doom = {5'd1,  DK_DOWN};
            {1'b0, 8'h1C}: scan2doom = {5'd2,  DK_LEFT};
            {1'b0, 8'h23}: scan2doom = {5'd3,  DK_RIGHT};
            {1'b0, 8'h14}: scan2doom = {5'd4,  DK_FIRE};
            {1'b0, 8'h29}: scan2doom = {5'd5,  DK_USE};
            {1'b0, 8'h12}: scan2doom = {5'd6,  DK_SHIFT};
            {1'b0, 8'h59}: scan2doom = {5'd6,  DK_SHIFT};
            {1'b0, 8'h76}: scan2doom = {5'd7,  DK_ESC};
            {1'b0, 8'h5A}: scan2doom = {5'd8,  DK_ENTER};
            {1'b0, 8'h0D}: scan2doom = {5'd9,  DK_TAB};
            {1'b0, 8'h11}: scan2doom = {5'd12, DK_ALT};
            {1'b0, 8'h05}: scan2doom = {5'd13, DK_F1};
            {1'b0, 8'h06}: scan2doom = {5'd14, DK_F2};
            {1'b0, 8'h04}: scan2doom = {5'd15, DK_F3};
            {1'b0, 8'h0C}: scan2doom = {5'd16, DK_F4};
            {1'b0, 8'h03}: scan2doom = {5'd17, DK_F5};
            {1'b0, 8'h0B}: scan2doom = {5'd18, DK_F6};
            {1'b0, 8'h83}: scan2doom = {5'd19, DK_F7};
            {1'b0, 8'h0A}: scan2doom = {5'd20, DK_F8};
            {1'b0, 8'h01}: scan2doom = {5'd21, DK_F9};
            {1'b0, 8'h09}: scan2doom = {5'd22, DK_F10};
            {1'b0, 8'h55}: scan2doom = {5'd23, DK_PLUS};
            {1'b0, 8'h4E}: scan2doom = {5'd24, DK_MINUS};
            {1'b1, 8'h75}: scan2doom = {5'd0,  DK_UP};
            {1'b1, 8'h72}: scan2doom = {5'd1,  DK_DOWN};
            {1'b1, 8'h6B}: scan2doom = {5'd2,  DK_LEFT};
            {1'b1, 8'h74}: scan2doom = {5'd3,  DK_RIGHT};
            {1'b1, 8'h14}: scan2doom = {5'd4,  DK_FIRE};
            {1'b1, 8'h11}: scan2doom = {5'd12, DK_ALT};
            {1'b1, 8'h5A}: scan2doom = {5'd8,  DK_ENTER};
            default:       scan2doom = {5'h1F, DK_NONE};
        endcase
    end
endfunction

function [7:0] bit2doomkey;
    input [4:0] bit_idx;
    begin
        case (bit_idx)
            5'd0:  bit2doomkey = 8'hAD;
            5'd1:  bit2doomkey = 8'hAF;
            5'd2:  bit2doomkey = 8'hAC;
            5'd3:  bit2doomkey = 8'hAE;
            5'd4:  bit2doomkey = 8'hA3;
            5'd5:  bit2doomkey = 8'hA2;
            5'd6:  bit2doomkey = 8'hB6;
            5'd7:  bit2doomkey = 8'd27;
            5'd8:  bit2doomkey = 8'd13;
            5'd9:  bit2doomkey = 8'hB8;
            5'd10: bit2doomkey = 8'hA0;
            5'd11: bit2doomkey = 8'hA1;
            5'd12: bit2doomkey = 8'd49;
            5'd13: bit2doomkey = 8'd50;
            5'd14: bit2doomkey = 8'd51;
            5'd15: bit2doomkey = 8'd52;
            5'd16: bit2doomkey = 8'd53;
            5'd17: bit2doomkey = 8'd54;
            5'd18: bit2doomkey = 8'd55;
            5'd19: bit2doomkey = 8'd9;
            5'd20: bit2doomkey = 8'hBB;
            5'd21: bit2doomkey = 8'hBC;
            5'd22: bit2doomkey = 8'hBD;
            5'd23: bit2doomkey = 8'hBF;
            5'd24: bit2doomkey = 8'hC0;
            5'd25: bit2doomkey = 8'hC1;
            5'd26: bit2doomkey = 8'hC2;
            5'd27: bit2doomkey = 8'hC3;
            5'd28: bit2doomkey = 8'hC4;
            5'd31: bit2doomkey = 8'h2D;
            default: bit2doomkey = 8'h00;
        endcase
    end
endfunction

// =============================================================================
// FIX 1: UART pulse — uart_key_ready level kalıyor, edge detect gerekli
// =============================================================================
reg uart_key_ready_d = 0;
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) uart_key_ready_d <= 0;
    else            uart_key_ready_d <= uart_key_ready;
end
wire uart_key_pulse = uart_key_ready & ~uart_key_ready_d;
// =============================================================================

reg uart_press_flag = 0;
reg uart_byte0_seen = 0;

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        dec_st          <= S_IDLE;
        is_ext          <= 0;
        DOOM_KEYS       <= 32'd0;
        KEY_EVENT       <= 32'd0;
        KEY_EV_VALID    <= 0;
        uart_press_flag <= 0;
        uart_byte0_seen <= 0;
    end else begin
        KEY_EV_VALID <= 0;

        // ── PS/2 Dekoderi ──────────────────────────────────────────────
        if (byte_rdy) begin
            case (dec_st)
                S_IDLE: begin
                    if (ps2_byte == 8'hE0) begin
                        is_ext <= 1;
                        dec_st <= S_EXT;
                    end else if (ps2_byte == 8'hF0) begin
                        is_ext <= 0;
                        dec_st <= S_REL;
                    end else begin
                        begin : press_n
                            reg [12:0] kd;
                            kd = scan2doom(1'b0, ps2_byte);
                            if (kd[12:8] != 5'h1F) begin
                                DOOM_KEYS[kd[12:8]] <= 1'b1;
                                KEY_EVENT           <= {1'b1, 23'd0, kd[7:0]};
                                KEY_EV_VALID        <= 1;
                            end
                        end
                        is_ext <= 0;
                        dec_st <= S_IDLE;
                    end
                end
                S_EXT: begin
                    if (ps2_byte == 8'hF0) begin
                        dec_st <= S_REL;
                    end else begin
                        begin : press_e
                            reg [12:0] kd;
                            kd = scan2doom(1'b1, ps2_byte);
                            if (kd[12:8] != 5'h1F) begin
                                DOOM_KEYS[kd[12:8]] <= 1'b1;
                                KEY_EVENT           <= {1'b1, 23'd0, kd[7:0]};
                                KEY_EV_VALID        <= 1;
                            end
                        end
                        is_ext <= 0;
                        dec_st <= S_IDLE;
                    end
                end
                S_REL: begin
                    begin : release_k
                        reg [12:0] kd;
                        kd = scan2doom(is_ext, ps2_byte);
                        if (kd[12:8] != 5'h1F) begin
                            DOOM_KEYS[kd[12:8]] <= 1'b0;
                            KEY_EVENT           <= {1'b0, 23'd0, kd[7:0]};
                            KEY_EV_VALID        <= 1;
                        end
                    end
                    is_ext <= 0;
                    dec_st <= S_IDLE;
                end
                default: begin
                    dec_st <= S_IDLE;
                    is_ext <= 0;
                end
            endcase
        end

        // ── UART Dekoderi (FIX 1: pulse kullan, level değil) ──────────
        if (uart_key_pulse) begin
            if (!uart_byte0_seen) begin
                if (uart_key_data == 8'h01 || uart_key_data == 8'h00) begin
                    uart_press_flag <= (uart_key_data == 8'h01);
                    uart_byte0_seen <= 1;
                end
            end else begin
                uart_byte0_seen <= 0;
                if (uart_key_data <= 8'd31) begin
                    DOOM_KEYS[uart_key_data[4:0]] <= uart_press_flag;
                    KEY_EVENT    <= {uart_press_flag, 23'd0,
                                     bit2doomkey(uart_key_data[4:0])};
                    KEY_EV_VALID <= 1;
                end
            end
        end

    end
end

endmodule