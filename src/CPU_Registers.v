module CPU_Registers( // BRAM (Gowin SDPB x2, one per read port)
    input clk,

    // Read Port 1
    input  [4:0]  read1_addr,
    output [31:0] read1_data,

    // Read Port 2
    input  [4:0]  read2_addr,
    output [31:0] read2_data,

    // Write Port (shared by both BRAM instances)
    input  [4:0]  write_addr,
    input  [31:0] write_data,
    input         write_enable
);

    // Gate writes so x0 (address 0) is never overwritten.
    // Both BRAM blocks are initialised to 0, so reads from address 0
    // will always return 0 without any extra mux logic.
    wire write_en_gated = write_enable && (write_addr != 5'd0);

    // ---------------------------------------------------------------
    // Read Port 1  (BRAM instance A)
    // ---------------------------------------------------------------
    Gowin_SDPB regfile_port1 (
        .clka   (clk),            // write clock
        .cea    (write_en_gated), // write enable
        .reseta (1'b0),
        .ada    (write_addr),     // write address  [4:0]
        .din    (write_data),     // write data    [31:0]

        .clkb   (clk),            // read clock
        .ceb    (1'b1),           // always-enabled read
        .resetb (1'b0),
        .oce    (1'b1),
        .adb    (read1_addr),     // read address  [4:0]
        .dout   (read1_data)      // read data    [31:0]
    );

    // ---------------------------------------------------------------
    // Read Port 2  (BRAM instance B)
    // Write port B is left empty (tied off — second write port unused)
    // ---------------------------------------------------------------
    Gowin_SDPB regfile_port2 (
        .clka   (clk),            // write clock
        .cea    (write_en_gated), // write enable
        .reseta (1'b0),
        .ada    (write_addr),     // write address  [4:0]
        .din    (write_data),     // write data    [31:0]

        .clkb   (clk),            // read clock
        .ceb    (1'b1),           // always-enabled read
        .resetb (1'b0),
        .oce    (1'b1),
        .adb    (read2_addr),     // read address  [4:0]
        .dout   (read2_data)      // read data    [31:0]
    );

endmodule
