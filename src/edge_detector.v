//=============================================================================
// Entidad para deteccion de flancos ascendentes
//=============================================================================
// Author: Gerardo A. Laguna S.
// Universidad Autonoma Metropolitana
// Unidad Lerma
// 31.oct.2025
//=============================================================================

module edge_detector
   (
    input wire clk, rst, x, clr,
    output reg  y
   );

   // symbolic state declaration
   localparam
      idle  = 1'b0,
      edge_detected  = 1'b1;

   // signal declaration
   reg state_reg, state_next;

   // body
   // FSMD state & data registers
   always @(posedge clk, posedge rst)
      if (rst)
            state_reg <= idle;
      else
            state_reg <= state_next;

   // FSMD next-state logic
   always @*
   begin
      y = 1'b0;

      case (state_reg)
         idle:
               if (x)
                  state_next = edge_detected;
               else
                  state_next = idle;

         edge_detected:
            begin
               if (clr)
                  state_next = idle;
               else
                  state_next = edge_detected;
       	
       	  y = 1'b1;

            end
      endcase
   end


endmodule
