//////////////////////////////////////////////////////////////////////////////////
//=============================================================================
// Entidad Nano_mcsys_4Tiny_fit, que cabe en 8x2 tiles de Tiny Tapeout, 
// con CPU Nano, con memoria minima (32x16 RAM; 256x8 ROM; 16x16 Stack),
// comunicacion SPI y bloques perifericos para operar con interrupciones.
//  En esta version:
//  * La entrada de reset (NRST) es activa en bajo.
//  * Se emplean puertos de salida OUT8B y OUT4B para monitorizacion de registros de Status, Flags y R.
//  * Se agrega puerto de entrada OUT_CTRL para seleccionar lo que se presenta en
//    las salidas anteriores.
//  * El reloj del CPU se asume con una frecuencia f_CLK=1.5625MHz 
//  * La velocidad para la comunicacion SPI resulta en f_SCK=195.3125 kHz con f_CLK=1.5625MHz
//=============================================================================
// Version validada con OpenLane y salidas conformes en puertos OUT8B y OUT4B
//=============================================================================
// Author: Gerardo A. Laguna S.
// Universidad Autonoma Metropolitana
// Unidad Lerma
// 13.dic.2025
//=============================================================================
//////////////////////////////////////////////////////////////////////////////////


module Nano_mcsys_4Tiny
(
    input CLK,NRST,RUN,MODE,
    input [2:0] OUT_CTRL,
    output [7:0] OUT8B,
    output [3:0] OUT4B,
    input EINT0,EINT1,EINT2,
    input SPI_CS,        
    input SPI_MOSI,     
    output SPI_MISO,    
    input SPI_SCK     
    );
 
    //signals:
    wire run_sig;
    wire loc_rst;
    
    wire prog_clk;
    wire mem_clk;
    wire mxd_mem_clk;
    
    wire [15:0] spi2ram_dout;
    wire [15:0] cpu2ram_dout;

    wire [15:0] spi2ram_din;
    wire [15:0] cpu2ram_din;
    wire [15:0] mxd_ram_din;

    wire [10:0] spi2ram_add;
    wire [10:0] cpu2ram_add;
    wire [10:0] mxd_ram_add;
    
    wire spi2ram_we;
    wire cpu2ram_we;
    wire mxd_ram_we;
    
    wire [7:0] spi2rom_dout;
    wire [7:0] cpu2rom_dout;

    wire [7:0] spi2rom_din;
    wire [7:0] mxd_rom_din;

    wire [11:0] spi2rom_add;
    wire [11:0] cpu2rom_add;
    wire [11:0] mxd_rom_add;

    wire spi2rom_we;
    wire mxd_rom_we;
  
    wire [15:0] cpu2stk_dout;
    wire [15:0] cpu2stk_din;
    wire [7:0] cpu2stk_add;
    wire cpu2stk_we;

    wire [7:0] cpu2intctrl_dout;
    wire [7:0] cpu2intctrl_din;
    wire [7:0] cpu2intctrl_add;
    wire cpu2intctrl_we;
    wire cpu2intctrl_int0, cpu2intctrl_int1, cpu2intctrl_int2;

    wire edge0_wire,edge1_wire,edge2_wire; 
    wire ack0_wire,ack1_wire,ack2_wire;

    wire [7:0] state_byte;
    wire [7:0] flags_byte;
    wire [31:0] R_word;

    wire cs_top_rom;
    wire top_rom_we;
    wire bottom_rom_we;
    wire [7:0] top_rom_dout;
    wire [7:0] bottom_rom_dout;

    //instantiations:
    sync_ram #(.DATA_WIDTH(16), .ADD_WIDTH(5)) my_ram
    (.clk(mxd_mem_clk), .we(mxd_ram_we), .datain(mxd_ram_din), .address(mxd_ram_add[4:0]), .dataout(cpu2ram_dout));

    sync_ram #(.DATA_WIDTH(8), .ADD_WIDTH(7)) my_top_rom
    (.clk(mxd_mem_clk), .we(top_rom_we), .datain(mxd_rom_din), .address(mxd_rom_add[6:0]), .dataout(top_rom_dout));

    sync_ram #(.DATA_WIDTH(8), .ADD_WIDTH(7)) my_bottom_rom
    (.clk(mxd_mem_clk), .we(bottom_rom_we), .datain(mxd_rom_din), .address(mxd_rom_add[6:0]), .dataout(bottom_rom_dout));

    sync_ram #(.DATA_WIDTH(16), .ADD_WIDTH(4)) my_stack
    (.clk(mem_clk), .we(cpu2stk_we), .datain(cpu2stk_din), .address(cpu2stk_add[3:0]), .dataout(cpu2stk_dout));

    slave_spi4nano my_NanoSPI
    (
    .CLK(CLK), .RST(loc_rst),
    .CS(SPI_CS), .MOSI(SPI_MOSI), .SCK(SPI_SCK),
    .MISO(SPI_MISO),
    .cin_prg(spi2rom_dout),
    .cout_prg(spi2rom_din),
    .cadd_prg(spi2rom_add),
    .cwe_prg(spi2rom_we),
    .din_prg(spi2ram_dout),
    .dout_prg(spi2ram_din),
    .dadd_prg(spi2ram_add),
    .dwe_prg(spi2ram_we), .prog_clk(prog_clk)
    );    
    
    Nano_cpu my_cpu
   (
    .clk(CLK), .reset(loc_rst),
    .run(run_sig),
    .state(state_byte),
    .flags(flags_byte),
    .code_add(cpu2rom_add),
    .code(cpu2rom_dout),
    .data_add(cpu2ram_add),
    .din(cpu2ram_dout),
    .dout(cpu2ram_din),
    .data_we(cpu2ram_we),
    .stk_add(cpu2stk_add),
    .sin(cpu2stk_dout),
    .sout(cpu2stk_din),
    .stk_we(cpu2stk_we),
    .io_add(cpu2intctrl_add),
    .io_i(cpu2intctrl_dout),
    .io_o(cpu2intctrl_din),
    .io_we(cpu2intctrl_we),
    .int0(cpu2intctrl_int0),
    .int1(cpu2intctrl_int1),
    .int2(cpu2intctrl_int2),
    .r_out(R_word)
   );
      
    pulse_generator my_pulse
        (.clk(CLK), .reset(loc_rst), .trigger(RUN), .p(run_sig));

   int_ctrl my_intctrl
   (
    .clk(mem_clk), .rst(loc_rst),
    .add(cpu2intctrl_add),
    .data_i(cpu2intctrl_din),
    .data_o(cpu2intctrl_dout),
    .we(cpu2intctrl_we),
    .eint0(edge0_wire), .eint1(edge1_wire), .eint2(edge2_wire),
    .ack0(ack0_wire), .ack1(ack1_wire), .ack2(ack2_wire),
    .int0(cpu2intctrl_int0), .int1(cpu2intctrl_int1), .int2(cpu2intctrl_int2)    
    );

   edge_detector my_edge_det0
   (
    .clk(CLK), .rst(loc_rst), .x(EINT0), .clr(ack0_wire),
    .y(edge0_wire)
   );

   edge_detector my_edge_det1
   (
    .clk(CLK), .rst(loc_rst), .x(EINT1), .clr(ack1_wire),
    .y(edge1_wire)
   );

   edge_detector my_edge_det2
   (
    .clk(CLK), .rst(loc_rst), .x(EINT2), .clr(ack2_wire),
    .y(edge2_wire)
   );

  // interconnection logic:
    assign mem_clk = ~CLK;
    assign loc_rst = ~NRST;
    assign spi2ram_dout = cpu2ram_dout;
    assign spi2rom_dout = cpu2rom_dout;
  
  // multiplexors logic:
    assign mxd_ram_din = (MODE) ? cpu2ram_din : spi2ram_din;
    assign mxd_ram_add = (MODE) ? cpu2ram_add : spi2ram_add;
    assign mxd_ram_we = (MODE) ? cpu2ram_we :  spi2ram_we;
    assign mxd_rom_din =  (MODE) ? 8'b00000000 : spi2rom_din;
    assign mxd_rom_add = (MODE) ? cpu2rom_add : spi2rom_add;
    assign mxd_rom_we = (MODE) ? 1'b0 :  spi2rom_we;
    assign mxd_mem_clk = (MODE) ? mem_clk :  prog_clk;
  
   //8 to 1 multiplexor for OUT8B:
     assign OUT8B = (OUT_CTRL[2] ? (OUT_CTRL[1] ? (OUT_CTRL[0] ? R_word[31:24] : R_word[23:16]) : (OUT_CTRL[0] ? R_word[15:8] : R_word[7:0])) 
                              :
                             (OUT_CTRL[1] ? (OUT_CTRL[0] ? state_byte : state_byte) : (OUT_CTRL[0] ? state_byte : state_byte)));

   //8 to 1 multiplexor for OUT4B:
     assign OUT4B = (OUT_CTRL[2] ? (OUT_CTRL[1] ? (OUT_CTRL[0] ? flags_byte[7:4] : flags_byte[7:4]) : (OUT_CTRL[0] ? flags_byte[3:0] : flags_byte[3:0])) 
                              :
                             (OUT_CTRL[1] ? (OUT_CTRL[0] ? R_word[15:12] : R_word[11:8]) : (OUT_CTRL[0] ? R_word[7:4] : R_word[3:0])));
    

    //2 to 1 multiplexor for cpu2rom_dout:
     assign cpu2rom_dout = (cs_top_rom ? top_rom_dout : bottom_rom_dout);

    //CS logic:
     assign cs_top_rom = mxd_rom_add[11] & mxd_rom_add[10] & mxd_rom_add[9] & mxd_rom_add[8] & mxd_rom_add[7];
     assign top_rom_we =  mxd_rom_we & cs_top_rom;
     assign bottom_rom_we =  mxd_rom_we & ~ cs_top_rom;
endmodule
