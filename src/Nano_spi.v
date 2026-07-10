//=============================
// Nano_spi.v
//=============================
//
// El hardware sintetizado fue probado con el reloj del sistema 
// de 100MHz y funciono bien.
// La velocidad maxima generada para la senal SCK fue de 12.5 MHz, alimentando
// las senales de reloj con el reloj del sistema, sin division de frecuencia. 
// La expresion para calcular la velocidad de SCK es la siguiente:
// f_sck= clk/8
//
//=============================================================================
// *Codigo para el componente slave_spi4nano*
// Version validada con OpenLane e iVerilog/cocotb
//=============================================================================
// Author: Gerardo Laguna
// UAM lerma
// Mexico
// 15/12/2025
//=============================================================================

module slave_spi4nano
   (
    input wire CLK, RST,
    input wire CS, MOSI, SCK,
    output wire MISO,
    input wire [7:0] cin_prg,
    output wire [7:0] cout_prg,
    output wire [11:0] cadd_prg,
    output wire  cwe_prg,
    input wire [15:0] din_prg,
    output wire [15:0] dout_prg,
    output wire [10:0] dadd_prg,
    output wire  dwe_prg, prog_clk
   );

   // symbolic state declaration
   localparam [4:0]
      idle1 = 5'h00,
      wait_low_i = 5'h01, 
      wait_high_i = 5'h02, 
      do_state = 5'h03, 
      ini_read_rom = 5'h04, 
      read_rom_clk = 5'h05, 
      read_rom = 5'h06,
      ini_read_ram = 5'h07, 
      read_ram_clk = 5'h08, 
      read_ram = 5'h09,
      ini_write_rom = 5'h0A, 
      write_rom_clk = 5'h0B, 
      write_rom = 5'h0C,
      ini_write_ram = 5'h0D, 
      write_ram_clk = 5'h0E, 
      write_ram = 5'h0F,     
      end1 = 5'h10, 
      end2 = 5'h11, 
      idle2 = 5'h12, 
      wait_low_o = 5'h13, 
      wait_high_o = 5'h14;

   // signal declaration
   reg [4:0] state_reg, state_next;
   reg [31:0] SRi_reg, SRi_next;
   reg [31:0] SRo_reg, SRo_next;
   reg [5:0] Cnt_reg, Cnt_next;
   reg MISO_buf_reg,MISO_buf_next;
   reg [11:0] cadd_buf_reg, cadd_buf_next;
   reg [7:0] cout_buf_reg, cout_buf_next;
   reg [10:0] dadd_buf_reg, dadd_buf_next;
   reg [15:0] dout_buf_reg, dout_buf_next;
   reg cwe_buf_reg, cwe_buf_next;
   reg dwe_buf_reg, dwe_buf_next;
   reg pclk_buf_reg, pclk_buf_next;
   

   // body
   // FSMD state & data registers
   always @(posedge CLK, posedge RST)
      if (RST)
         begin
         	state_reg <= idle1;
         	SRi_reg <= 0;
         	SRo_reg <= 0;
         	Cnt_reg <= 0;
         	MISO_buf_reg <= 1'b0;
         	cadd_buf_reg <= 0;
         	cout_buf_reg <= 0;
         	dadd_buf_reg <= 0;
         	dout_buf_reg <= 0;
         	cwe_buf_reg <= 1'b0;
         	dwe_buf_reg <= 1'b0;
         	pclk_buf_reg <= 1'b0;
         end
      else
         begin
         	state_reg <= state_next;
         	SRi_reg <= SRi_next;
         	SRo_reg <= SRo_next;
         	Cnt_reg <= Cnt_next;
         	MISO_buf_reg <= MISO_buf_next; 
         	cadd_buf_reg <= cadd_buf_next;
         	cout_buf_reg <= cout_buf_next;
         	dadd_buf_reg <= dadd_buf_next;
         	dout_buf_reg <= dout_buf_next;
         	cwe_buf_reg <= cwe_buf_next;
         	dwe_buf_reg <= dwe_buf_next;
         	pclk_buf_reg <= pclk_buf_next;
         end

   // FSMD next-state logic
   always @*
   begin
      SRi_next = SRi_reg;
      SRo_next = SRo_reg;
      Cnt_next = Cnt_reg;
      MISO_buf_next = MISO_buf_reg;
      cadd_buf_next = cadd_buf_reg;
      cout_buf_next = cout_buf_reg;
      dadd_buf_next = dadd_buf_reg;
      dout_buf_next = dout_buf_reg;

      case (state_reg)
         idle1 :
          begin	
            if (~CS) 
               state_next = wait_low_i;
            else
               state_next = idle1;
            
            SRi_next = 0;
            Cnt_next = 0;
          end
          
         wait_low_i :
          begin	
            if (~CS)
               if (~SCK)
                  begin
                  	MISO_buf_next = SRo_reg[31]; 
                  	SRo_next = {SRo_reg[30 : 0] , 1'b0};
                  	state_next = wait_high_i;
                  end                  
               else
                  state_next = wait_low_i;
               
            else
               state_next = idle1;
           
          end

         wait_high_i :
          begin	
            if (~CS)
               if (SCK)
                begin
                  SRi_next = {SRi_reg[30 : 0],  MOSI};
                  
                  if (Cnt_reg == 31)
                     state_next = do_state;
                  else
                    begin
                     Cnt_next = Cnt_reg+1;
                     state_next = wait_low_i;
                    end
                end
               else
                  state_next = wait_high_i;
               
            else
               state_next = idle1;
            
          end

         do_state :
          begin	
            if (SRi_reg[31])
               if (SRi_reg[30]) 
                begin
                  dadd_buf_next = SRi_reg[26 : 16];
                  state_next = ini_read_ram;
                end
               else
                begin
                  cadd_buf_next = SRi_reg[27 : 16];
                  state_next = ini_read_rom;
                end
            else
             begin
               if (SRi_reg[30]) 
                begin
                  dadd_buf_next = SRi_reg[26 : 16];
                  dout_buf_next =  SRi_reg[15 : 0];
                  state_next = ini_write_ram;
                end
               else
                begin
                  cadd_buf_next = SRi_reg[27 : 16];
                  cout_buf_next =  SRi_reg[7 : 0];
                  state_next = ini_write_rom;
                end
               SRo_next = SRi_reg;
             end
          end
         
         ini_read_rom :
            state_next = read_rom_clk;
            
         read_rom_clk :
            state_next = read_rom;
            
         read_rom :
          begin	         
            SRo_next = {SRi_reg[31 : 16], 8'b00000000, cin_prg};
            state_next = end2;
          end
           
         ini_read_ram :
            state_next = read_ram_clk;
            
         read_ram_clk :
            state_next = read_ram;
            
         read_ram :
          begin	         
            SRo_next = {SRi_reg[31 : 16], din_prg};
            state_next = end2;
          end
           
         ini_write_rom :
            state_next = write_rom_clk;
            
         write_rom_clk :
            state_next = write_rom;
            
         write_rom :
          begin	         
            SRo_next = SRi_reg;
            state_next = end1;
          end
           
         ini_write_ram :
            state_next = write_ram_clk;
            
         write_ram_clk :
            state_next = write_ram;
            
         write_ram :
          begin	         
            SRo_next = SRi_reg;
            state_next = end1;
          end
           
         end1 :
            if (CS)
               state_next = idle1;
            else
               state_next = end1;             
            
         end2 :
            if (CS)
               state_next = idle2;
            else
               state_next = end2;
                        
         idle2 :
          begin	
            if (~CS)
               state_next = wait_low_o;
            else
               state_next = idle2;
             
            Cnt_next = 0;
          end
           
         wait_low_o :
            if (~CS)
               if (~SCK)
                begin
                    MISO_buf_next = SRo_reg[31]; 
                    SRo_next = {SRo_reg[30 : 0], 1'b0};
                    state_next = wait_high_o;
		        end               
               else
                    state_next = wait_low_o;
               
            else
               state_next = idle1;
                       
         wait_high_o :
            if (~CS)
               if (SCK)                  
                  if (Cnt_reg == 31)
                     state_next = end1;
                  else
                   begin
                     Cnt_next = Cnt_reg+1;
                     state_next = wait_low_o;
                   end
               else
                  state_next = wait_high_o;
               
            else
               state_next = idle1;
            
      endcase
   end

   // look-ahead output logic
   always @*
   begin
      pclk_buf_next = 1'b0;
      cwe_buf_next = 1'b0;
      dwe_buf_next = 1'b0;

      case (state_next)
         read_rom_clk :
            pclk_buf_next = 1'b1;         
         read_ram_clk :
            pclk_buf_next = 1'b1;
         ini_write_rom :
            cwe_buf_next = 1'b1;         
         write_rom_clk :
          begin
            cwe_buf_next = 1'b1;
            pclk_buf_next = 1'b1;
          end
         write_rom :
            cwe_buf_next = 1'b1;         
         ini_write_ram :
            dwe_buf_next = 1'b1;         
         write_ram_clk :
          begin
            dwe_buf_next = 1'b1;
            pclk_buf_next = 1'b1;
          end
         write_ram :
            dwe_buf_next = 1'b1;         

      endcase
   end

   //outputs
   assign MISO = MISO_buf_reg;
   assign cout_prg = cout_buf_reg;
   assign cadd_prg = cadd_buf_reg;
   assign dout_prg = dout_buf_reg;
   assign dadd_prg = dadd_buf_reg;
   assign cwe_prg = cwe_buf_reg;
   assign dwe_prg = dwe_buf_reg;
   assign prog_clk = pclk_buf_reg; 

 endmodule
