/*
 * Copyright (c) 2026 Gerardo Laguna-Sanchez
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none


module tt_um_galaguna_NanoSys_fit (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    //signals:
    wire mode; 
    wire exec;
    wire [2:0] out_ctrl;
    wire loc_NRst; 
    wire loc_clk;
    wire spi_sck, spi_mosi, spi_cs, spi_miso;
    wire int0, int1, int2;
    
    wire [7:0] out8b;
    wire [3:0] out4b;
    

    //instantiations:
    
    Nano_mcsys_4Tiny my_NanoSys
    (
    .CLK(loc_clk), .NRST(loc_NRst),
    .RUN(exec), .MODE(mode),.OUT_CTRL(out_ctrl),
    .OUT8B(out8b), .OUT4B(out4b),
    .EINT0(int0),
    .EINT1(int1),
    .EINT2(int2),
    .SPI_CS(spi_cs), .SPI_MOSI(spi_mosi), .SPI_SCK(spi_sck),
    .SPI_MISO(spi_miso)
    );    
    
  // interconnection logic:
    assign loc_clk = clk; //1525.879 Hz
    assign loc_NRst = rst_n;

    assign out_ctrl = ui_in[2:0];
    assign spi_sck  = ui_in[3];
    assign spi_mosi = ui_in[4];
    assign spi_cs   = ui_in[5];
    assign exec     = ui_in[6];
    assign mode     = ui_in[7];
    assign int0     = uio_in[4];
    assign int1     = uio_in[5];
    assign int2     = uio_in[6];

  //output logic:
    assign uo_out = out8b;
    assign uio_oe  = 8'b10001111;
    assign uio_out[3:0] = out4b;
    assign uio_out[6:4] = 3'b000;
    assign uio_out[7] = spi_miso;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, uio_in[0], uio_in[1], uio_in[2], uio_in[3], uio_in[7], 1'b0};

endmodule
