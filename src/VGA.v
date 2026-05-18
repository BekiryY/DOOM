// VGA_Controller — reads from a 160×32-bit ping-pong line buffer
// (2-clock BSRAM read latency, runs in vga_clk = 25.2 MHz domain)
//
// FIX 2: DMA her DOOM satırını 2 kez çekiyordu (her VGA satırında pulse).
//        v_offset[0] == 0 koşulu ile sadece çift satırlarda fetch et.
//        DDR bandwidth yarıya iner, CPU'ya bus zamanı kalır.
module VGA_Controller (
    input  wire sys_clk,
    input  wire sys_rst_n,

    output reg  [7:0]  lb_rd_addr,
    output reg         lb_rd_en,
    input  wire [31:0] lb_rd_data,

    input  wire        lb_rd_bank,

    output wire h_sync_i,
    output wire v_sync_i,
    output reg  [2:0]  RED,
    output reg  [2:0]  GREEN,
    output reg  [1:0]  BLUE,

    output reg         line_pulse_vga,
    output reg  [8:0]  line_num_vga
);

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

wire image_active = (h_cnt < 640) && (v_cnt >= 40) && (v_cnt < 440);

wire [8:0] pixel_x  = h_cnt[9:1];
wire [9:0] v_offset = v_cnt - 10'd40;
wire [7:0] pixel_y  = v_offset[8:1];

wire [6:0] word_in_line = pixel_x[8:2];
wire [1:0] sub_pixel     = pixel_x[1:0];

reg [1:0] sub_pixel_d1  = 0, sub_pixel_d2  = 0;
reg       img_active_d1 = 0, img_active_d2 = 0;

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
        if (h_cnt == H_TOTAL - 1) begin
            h_cnt <= 10'd0;
            if (v_cnt == V_TOTAL - 1) v_cnt <= 10'd0;
            else                      v_cnt <= v_cnt + 10'd1;
        end else begin
            h_cnt <= h_cnt + 10'd1;
        end

        // =====================================================================
        // FIX 2: Sadece çift VGA satırlarında prefetch (her DOOM satırı 1 kez)
        // =====================================================================
        line_pulse_vga <= 0;
        if (h_cnt == H_ACTIVE - 1 && v_cnt >= 40 && v_cnt < 440 && v_offset[0] == 1'b0) begin
            line_pulse_vga <= 1;
            line_num_vga <= v_offset[8:1] < 8'd199
                            ? {1'b0, v_offset[8:1] + 8'd1}
                            : 9'd0;
        end

        lb_rd_en   <= image_active;
        lb_rd_addr <= {lb_rd_bank, word_in_line};

        sub_pixel_d1  <= sub_pixel;
        sub_pixel_d2  <= sub_pixel_d1;
        img_active_d1 <= image_active;
        img_active_d2 <= img_active_d1;

        if (img_active_d2) begin
            case (sub_pixel_d2)
                2'd0: begin RED <= lb_rd_data[7:5];   GREEN <= lb_rd_data[4:2];   BLUE <= lb_rd_data[1:0];   end
                2'd1: begin RED <= lb_rd_data[15:13]; GREEN <= lb_rd_data[12:10]; BLUE <= lb_rd_data[9:8];   end
                2'd2: begin RED <= lb_rd_data[23:21]; GREEN <= lb_rd_data[20:18]; BLUE <= lb_rd_data[17:16]; end
                2'd3: begin RED <= lb_rd_data[31:29]; GREEN <= lb_rd_data[28:26]; BLUE <= lb_rd_data[25:24]; end
            endcase
        end else begin
            RED <= 0; GREEN <= 0; BLUE <= 0;
        end
    end
end

endmodule