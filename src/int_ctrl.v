//////////////////////////////////////////////////////////////////////////////////
//=============================================================================
// int_ctrl.v
//=============================================================================
// Codigo para controlar interrupciones de CPU Nano
// Version validada con OpenLane
//=============================================================================
// Author: Gerardo A. Laguna S.
// Universidad Autonoma Metropolitana
// Unidad Lerma
// 15.dic.2025
//=============================================================================
//////////////////////////////////////////////////////////////////////////////////


module int_ctrl
   (
    input clk, rst,
    input [7:0] add,
    input [7:0] data_i,
    output [7:0] data_o,
    input we,
    input eint0,eint1,eint2,
    output ack0,ack1,ack2,
    output int0,int1,int2    
    );
 
    //signals:
    wire cs0, cs1;
    wire clk0, clk1;
    wire [7:0] En_reg;
    wire [7:0] Flg_reg;
    wire int0_driv, int1_driv, int2_driv;

    
   
    //instantiations:
    RegisterN #(.N(8)) Reg0
      (.clk(clk0), .reset(rst), .d(data_i), .q(En_reg));
      
    RegisterN #(.N(8)) Reg1
      (.clk(clk1), .reset(rst), .d(data_i), .q(Flg_reg));


   // glue logic:
   
	assign cs0 = ~ add[0] & ~ add[1] & ~ add[2] & ~ add[3] & ~ add[4] & ~ add[5] & ~ add[6] & ~ add[7];
	assign cs1 = add[0] & ~ add[1] & ~ add[2] & ~ add[3] & ~ add[4] & ~ add[5] & ~ add[6] & ~ add[7];

	assign clk0 = cs0 & we & clk;
	assign clk1 = cs1 & we & clk;

	assign int0_driv = (eint0 & En_reg[0]) | Flg_reg[0];
	assign int1_driv = (eint1 & En_reg[1]) | Flg_reg[1];
	assign int2_driv = (eint2 & En_reg[2]) | Flg_reg[2];

   // output logic:
   
	assign data_o = (cs0) ? En_reg : ((cs1) ? {5'b00000, int2_driv, int1_driv, int0_driv} : 8'bz );

	assign int0 = int0_driv;
	assign int1 = int1_driv;
	assign int2 = int2_driv;

	assign ack0 = Flg_reg[0];
	assign ack1 = Flg_reg[1];
	assign ack2 = Flg_reg[2];

endmodule
