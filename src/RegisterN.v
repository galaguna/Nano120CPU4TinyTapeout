//==========================================================
// Universidad Atonoma Metropolitana, Unidad Lerma
//==========================================================
// RegisterN.v
// Programador: Gerardo Laguna
// 21 de octubre 2025
//==========================================================
// Registro de N bits
//==========================================================

module RegisterN
   #(parameter N=8)
   (
    input wire clk, reset,
    input wire [N-1:0] d,
    output reg [N-1:0] q
   );

   // body
   // register
   always @(posedge clk, posedge reset)
      if (reset)
         q <= {N{1'b0}}; 
      else
         q <= d;

endmodule