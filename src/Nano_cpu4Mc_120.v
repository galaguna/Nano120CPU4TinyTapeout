//=============================
// Nano_cpu4Mc_120.v
//=============================
// Entidad para CPU Nano validada con flujo OpenLane
//=============================================================================
// Codigo V4Mc con conjunto de 120 instrucciones codificadas de conformidad con
// la lista objetivo (target 120)
// *Version validada con OpenLane e iVerilog/cocotb*
//=============================================================================
// Author: Gerardo Laguna
// UAM lerma
// Mexico
// 9/julio/2026
//=============================================================================

module Nano_cpu
   (
    input wire clk, reset,
    input wire run,
    output wire [7:0] state, flags,
    output wire [11:0] code_add,
    input wire [7:0] code,
    output wire [10:0] data_add,
    input wire [15:0] din,
    output wire [15:0] dout,
    output wire  data_we,
    output wire [7:0] stk_add,
    input wire [15:0] sin,
    output wire [15:0] sout,
    output wire  stk_we, 
    output wire [7:0] io_add,
    input wire [7:0] io_i,
    output wire [7:0] io_o,
    output wire  io_we, 
    input wire int0,int1,int2,
    output wire [31:0] r_out
   );

   // Size constants:
   localparam [4:0]
      CODE_ADD_SIZE = 12,
      CODE_SIZE = 8,
      DATA_ADD_SIZE= 11;
      
   localparam [15:0]
      INT0_VEC_ADD = 			16'h0FFD,
      INT1_VEC_ADD = 			16'h0FFA,
      INT2_VEC_ADD = 			16'h0FF7; 

   // symbolic state declaration
   localparam [7:0]
      stop = 			8'h00,
      start = 			8'h01, 
      fetch_decode = 	8'h02, 
      load_ha_jmp = 	8'h03, 
      load_la_jmp = 	8'h04, 
  	load_ip = 		8'h05,
   	jz16_exe = 		8'h06,
   	jz32_exe = 		8'h07,
   	jn16_exe = 		8'h08,
   	jn32_exe = 		8'h09,
   	jo16_exe = 		8'h0A,
   	jo32_exe = 		8'h0B,
   	jco16_exe = 		8'h0C,
   	jco32_exe = 		8'h0D,
   	load_ha_call  = 	8'h0E,
   	load_la_call  = 	8'h0F,
   	push_ip = 		8'h10,
   	pop_ip_ini  = 	8'h11,
   	pop_ip  = 		8'h12,
   	ini_reti = 		8'h13,
   	pusha_exe = 	8'h14,
   	pushb_exe = 	8'h15,
   	dec_spx = 		8'h16,
   	point_spx = 		8'h17,
   	popa_exe = 		8'h18,
   	popb_exe = 		8'h19,
   	load_khx = 		8'h1A,
   	load_klx = 		8'h1B,
   	store_ka = 		8'h1C,
   	store_kb = 		8'h1D,
   	load_usp = 		8'h1E,
   	load_hi_movxm= 8'h1F,
   	load_li_movxm = 8'h20,
   	load_dp_movxm=8'h21,
   	movam_exe = 	8'h22,
   	movbm_exe = 	8'h23,
   	movrlm_exe = 	8'h24,
   	movrhm_exe = 	8'h25,
   	load_hi_movmx=8'h26,
   	load_li_movmx= 	8'h27,
   	load_dp_movmx=8'h28,
   	movma_exe = 	8'h29,
   	movmb_exe = 	8'h2A,
   	load_hi_movi  = 	8'h2B,
   	load_li_movi  = 	8'h2C,
   	load_dp_movi = 	8'h2D,
   	load_ix = 		8'h2E,
   	movia_exe = 	8'h2F,
   	movib_exe = 	8'h30,
   	movaipp_exe  = 	8'h31,
   	movbipp_exe  = 	8'h32,
   	movrlipp_exe  = 	8'h33,
   	movrhipp_exe = 	8'h34,
   	ix_inc  = 		8'h35,
   	ix_sto  = 		8'h36,
   	movippa_exe = 	8'h37,
   	movippb_exe = 	8'h38,
   	ix_dec_a = 		8'h39,
   	movmmia_exe = 	8'h3A,
   	ix_dec_b = 		8'h3B,
   	movmmib_exe = 	8'h3C,
   	ix_dest = 		8'h3D,
   	movas_exe = 	8'h3E,
   	movbs_exe = 	8'h3F,
   	movrls_exe = 	8'h40,
   	movrhs_exe = 	8'h41,
   	movsa_exe = 	8'h42,
   	movsb_exe = 	8'h43,
   	add_result  = 	8'h44,
   	cmp_result  = 	8'h45,
   	xmul_exe = 		8'h46,
   	sxacc_exe = 		8'h47,
   	log_result = 		8'h48,
   	store_ki = 		8'h49,
   	store_kj = 		8'h4A,
   	store_kn = 		8'h4B,
   	store_km = 		8'h4C,
   	pushi_exe = 		8'h4D,
   	pushj_exe = 		8'h4E,
   	pushn_exe = 	8'h4F,
   	pushm_exe = 	8'h50,
   	popi_exe = 		8'h51,
   	popj_exe = 		8'h52,
   	popn_exe = 		8'h53,
   	popm_exe = 	8'h54,
   	load_xpp = 		8'h55,
   	load_xmm = 	8'h56,
   	movxrm = 		8'h57,
   	load_y = 		8'h58,
   	cmp_xy = 		8'h59,
   	jnz16_exe = 		8'h5A,
   	jnz32_exe = 		8'h5B,
   	jp16_exe = 		8'h5C,
   	jp32_exe = 		8'h5D,
   	jno16_exe = 	8'h5E,
   	jno32_exe = 	8'h5F,
   	jnco16_exe = 	8'h60,
   	jnco32_exe = 	8'h61,
   	load_ioadd = 	8'h62,
   	outa_exe = 		8'h63,
   	ina_exe = 		8'h64,
   	load_iok = 		8'h65,
   	ld_ioadd4k = 	8'h66,
   	outk_exe = 		8'h67,
   	ini_iss = 		8'h68,
   	in_intx_F = 		8'h69,
   	set_int0_F = 		8'h6A,
   	set_int1_F = 		8'h6B,
   	set_int2_F = 		8'h6C,
   	ld_iss_vec = 		8'h6D,
   	push_ip_int = 	8'h6E,
   	push_rl = 		8'h6F,
   	push_rh = 		8'h70,
   	push_f = 		8'h71,
   	pop_f = 			8'h72,
   	pop_rh_ini = 	8'h73,
   	pop_rh = 		8'h74,
   	pop_rl_ini = 		8'h75,
   	pop_rl_nres = 	8'h76;

   // symbolic opcode declaration
   localparam [7:0]
   	nop_code  = 		8'h00, //No op.
   	jmp_code  = 		8'h01, //Inconditional jump
   	jz16_code = 			8'h02, //Jump if zero for 16 bits word
   	jn16_code = 		8'h03, //Jump if negative for 16 bits word
   	jo16_code = 		8'h04, //Jump if aritmetic overflow for 16 bits word
   	jco16_code = 		8'h05, //Jump if catastrofic aritmetic overflow for 16 bits word
   	jz32_code = 			8'h06, //Jump if zero for 32 bits word
   	jn32_code = 		8'h07, //Jump if negative for 32 bits word
   	jo32_code = 		8'h08, //Jump if aritmetic overflow for 32 bits word
   	jco32_code = 		8'h09, //Jump if catastrofic aritmetic overflow for 32 bits word
   	jnz16_code = 		8'h0A, //Jump if nonzero for 16 bits word
   	jp16_code = 		8'h0B, //Jump if positive for 16 bits word
   	jno16_code = 		8'h0C, //Jump if not aritmetic overflow for 16 bits word
   	jnco16_code = 		8'h0D, //Jump if not catastrofic aritmetic overflow for 16 bits word
   	jnz32_code = 		8'h0E, //Jump if nonzero for 32 bits word
   	jp32_code = 		8'h0F, //Jump if positive for 32 bits word
   	jno32_code = 		8'h10, //Jump if not aritmetic overflow for 32 bits word
   	jnco32_code = 		8'h11, //Jump if not catastrofic aritmetic overflow for 32 bits word
   	call_code = 			8'h12, //Call
   	ret_code  = 			8'h13, //Return from call
   	reti_code  = 			8'h14, //Return from interrupt
   	pusha_code = 		8'h15, //Push A
   	pushb_code = 		8'h16, //Push B
   	pushi_code = 		8'h17, //Push I
   	pushj_code = 		8'h18, //Push J
   	pushn_code = 		8'h19, //Push N
   	pushm_code = 		8'h1A, //Push M
   	popa_code = 		8'h1B, //Pop A
   	popb_code = 		8'h1C, //Pop B
   	popi_code = 			8'h1D, //Pop I
   	popj_code = 		8'h1E, //Pop J
   	popn_code = 		8'h1F, //Pop N
   	popm_code = 		8'h20, //Pop M
   	movba_code = 		8'h21, //MOV B, A
   	movira_code = 		8'h22, //MOV I, A
   	movjra_code = 		8'h23, //MOV J, A
   	movrla_code = 		8'h24, //MOV RL, A
   	movrha_code = 		8'h25, //MOV RH, A
   	movab_code = 		8'h26, //MOV A, B
   	movrlb_code = 		8'h27, //MOV RL, B
   	movrhb_code = 		8'h28, //MOV RH, B
   	movracc_code = 		8'h29, //MOV R, ACC
   	movaaccl_code = 	8'h2A, //MOV A, ACCL
   	movbaccl_code = 	8'h2B, //MOV B, ACCL
   	movaacch_code = 	8'h2C, //MOV A, ACCH
   	movbacch_code = 	8'h2D, //MOV B, ACCH
   	movaccla_code = 	8'h2E, //MOV ACCL, A
   	movacclb_code = 	8'h2F, //MOV ACCL, B
   	movaccha_code = 	8'h30, //MOV ACCH, A
   	movacchb_code = 	8'h31, //MOV ACCH, B
   	stospa_code = 		8'h32, //STO SP, A (i.e. MOV SP, A)
   	stospb_code = 		8'h33, //STO SP, B (i.e. MOV SP, B)
   	stouspa_code = 		8'h34, //STO USP, A (i.e. MOV USP, A)
   	stouspb_code = 		8'h35, //STO USP, B (i.e. MOV USP, B)
   	ldusp_code = 		8'h36, //LOAD USP, SP  (i.e. MOV SP, USP)
   	lduspa_code = 		8'h37, //LOAD USP, AL (i.e. MOV AL, USP)
   	lduspb_code = 		8'h38, //LOAD USP, BL (i.e. MOV BL, USP)
   	lduspr_code = 		8'h39, //LOAD USP, RL (i.e. MOV R(7:0), USP)  
   	lduspk_code = 		8'h3A, //LOAD USP, k (i.e. MOV k, USP)
   	movka_code = 		8'h3B, //MOV k, A
   	movkb_code = 		8'h3C, //MOV k, B
   	movki_code = 		8'h3D, //MOV k, I
   	movkj_code = 		8'h3E, //MOV k, J
    	movkn_code = 		8'h3F, //MOV k, N
   	movkm_code = 		8'h40, //MOV k, M
   	movam_code = 		8'h41, //MOV A, RAM[ix]
   	movbm_code = 		8'h42, //MOV B, RAM[ix]
   	movrlm_code = 		8'h43, //MOV RL, RAM[ix]
   	movrhm_code = 		8'h44, //MOV RH, RAM[ix]
   	movma_code = 		8'h45, //MOV RAM[ix], A
   	movmb_code = 		8'h46, //MOV RAM[ix], B
   	movai_code = 		8'h47, //MOV A, RAM[ix]->
   	movbi_code = 		8'h48, //MOV B, RAM[ix]->
   	movrli_code = 		8'h49, //MOV RL, RAM[ix]->
   	movrhi_code = 		8'h4A, //MOV RH, RAM[ix]->
   	movia_code = 		8'h4B, //MOV RAM[ix]->, A
   	movib_code = 		8'h4C, //MOV RAM[ix]->, B
   	movaipp_code = 		8'h4D, //MOV A, RAM[ix++]->
   	movbipp_code = 		8'h4E, //MOV B, RAM[ix++]->
   	movrlipp_code = 		8'h4F, //MOV RL, RAM[ix++]->
   	movrhipp_code = 	8'h50, //MOV RH, RAM[ix++]->
   	movippa_code = 		8'h51, //MOV RAM[ix++]->, A
   	movippb_code = 		8'h52, //MOV RAM[ix++]->, B
   	movmmia_code = 	8'h53, //MOV RAM[--ix]->, A
   	movmmib_code = 	8'h54, //MOV RAM[--ix]->, B
   	movas_code = 		8'h55, //MOV A, STACK[usp]
   	movbs_code = 		8'h56, //MOV B, STACK[usp]
   	movrls_code = 		8'h57, //MOV RL, STACK[usp]
   	movrhs_code = 		8'h58, //MOV RH, STACK[usp]
   	movsa_code = 		8'h59, //MOV STACK[usp], A
   	movsb_code = 		8'h5A, //MOV STACK[usp], B
   	uadd_code = 		8'h5B, //A, B de 16 bits, sin signo, y R de 32 bits: R = UADD A,B 
   	sadd_code = 		8'h5C, //A, B de 16 bits, con signo, y R de 32 bits: R = SADD A,B 
   	ac_code   = 			8'h5D, //ACC y R de 32 bits: ACC = ADD ACC,R 
   	umul_code = 		8'h5E, //A, B de 16 bits, sin signo, y R de 32 bits: R = UMUL A,B 
   	smul_code = 		8'h5F, //A, B de 16 bits, con signo, y R de 32 bits: R = SMUL A,B 
   	umac_code = 		8'h60, //A, B de 16 bits, sin signo, y R de 32 bits: R = UMUL A,B; ACC = ADD ACC,R 
   	smac_code = 		8'h61, //A, B de 16 bits, con signo, y R de 32 bits: R = SMUL A,B; ACC = ADD ACC,R 
   	sracc_code = 		8'h62, // R = right shift ACC in A positions 
   	sraacc_code = 		8'h63, // R = arithmetic right shift ACC in A positions 
   	slacc_code = 		8'h64, // R = left shift ACC in A positions 
   	nota_code = 			8'h65, //A de 16 bits: RL = not A 
   	notb_code = 		8'h66, //A de 16 bits: RL = not B
   	and_code  = 			8'h67, //A, B y R de 16 bits: RL = A AND B 
   	or_code   = 			8'h68, //A, B y R de 16 bits: RL = A OR B
   	xor_code  = 			8'h69, //A, B y R de 16 bits: RL = A XOR B
   	incusp_code = 		8'h6A, //INC USP   
   	incir_code = 			8'h6B, //INC I   
   	incjr_code = 			8'h6C, //INC J   
   	decusp_code = 		8'h6D, //DEC USP   
   	decir_code = 		8'h6E, //DEC I   
   	decjr_code = 		8'h6F, //DEC J   
	cmpin_code = 		8'h70, //CMP I,N  (Compare I with N, i.e. R=I-N)
	cmpjm_code = 		8'h71, //CMP J,M  (Compare J with M, i.e. R=J-M)
	incmpm_code = 		8'h72, //INCMP M[i],M[i+1]  (Increment M[i] and compare with M[i+1], i.e. M[i]= M[i]+1; R=M[i]-M[i+1])
	decmpm_code = 		8'h73, //DECMP M[i],M[i+1]  (Decrement M[i] and compare with M[i+1], i.e. M[i]= M[i]-1; R=M[i]-M[i+1])  	
   	outa_code = 			8'h74, //MOV AL, Port[ix]
   	ina_code = 			8'h75, //MOV Port[ix], AL 
   	outk_code = 			8'h76, //MOV k, Port[ix]
	stop_code = 			8'hFF; //Stop instruction

   //-------------------------------------------------------------------------------
   // signal declaration
   //-------------------------------------------------------------------------------
   // Control path register
   reg [7:0] state_reg, state_next;

   // Data path registers
   reg [11:0] IP_reg, IP_next;
   reg [10:0] DP_reg, DP_next;
   reg [10:0] DPB_reg, DPB_next;
   reg [10:0] UDP_reg, UDP_next;
   reg [7:0] SP_reg, SP_next;
   reg [7:0] USP_reg, USP_next;
   reg [7:0] PP_reg, PP_next;
   reg [7:0] instruction_reg, instruction_next;
   reg [7:0] H_reg, H_next;
   reg [7:0] L_reg, L_next;
   reg [15:0] A_reg, A_next;
   reg [15:0] B_reg, B_next;
   reg [15:0] X_reg, X_next;
   reg [15:0] Y_reg, Y_next;
   reg [31:0] R_reg, R_next;
   reg [31:0] ACC_reg, ACC_next;
   reg [32:0] WR33_reg, WR33_next;
   reg [32:0] SR1_reg, SR1_next;
   reg [32:0] SR2_reg, SR2_next;
   reg [7:0] F_reg, F_next;
   reg [5:0] CNT_reg, CNT_next;
   reg [15:0] I_reg, I_next;
   reg [15:0] J_reg, J_next;
   reg [15:0] N_reg, N_next;
   reg [15:0] M_reg, M_next;
   reg ISF_reg, ISF_next;
   reg FDI_reg, FDI_next;

   // Registers for control signals
   reg ramwe_reg, ramwe_next;
   reg stkwe_reg, stkwe_next;
   reg iowe_reg, iowe_next;

   // Temporal bus
   wire [11:0] IP_bak;

   // body
   // FSMD state & data registers
   always @(posedge clk, posedge reset)
      if (reset)
         begin
         	state_reg <= stop;
         	IP_reg <= 0;
         	DP_reg <= 0;
         	DPB_reg <= 0;
         	UDP_reg <= 0;
         	SP_reg <= 0;
         	USP_reg <= 0;
         	PP_reg <= 0;
         	instruction_reg <= 0;
         	H_reg <= 0;
         	L_reg <= 0;
         	A_reg <= 0;
         	B_reg <= 0;
         	X_reg <= 0;
         	Y_reg <= 0;
         	R_reg <= 0;
         	ACC_reg <= 0;
         	SR1_reg <= 0;
         	SR2_reg <= 0;
         	WR33_reg <= 0;
         	F_reg <= 0;
         	CNT_reg <= 0;
         	I_reg <= 0;
         	J_reg <= 0;
         	N_reg <= 0;
         	M_reg <= 0;
         	ISF_reg <= 1'b0;
         	FDI_reg <= 1'b0;
         	ramwe_reg <= 1'b0;
         	stkwe_reg <= 1'b0;
         	iowe_reg <= 1'b0;
         end
      else
         begin
         	state_reg <= state_next;
         	IP_reg <= IP_next;
         	DP_reg <= DP_next;
         	DPB_reg <= DPB_next;
         	UDP_reg <= UDP_next;
         	SP_reg <= SP_next;
         	USP_reg <= USP_next;
         	PP_reg <= PP_next;
         	instruction_reg <= instruction_next;
         	H_reg <= H_next;
         	L_reg <= L_next;
         	A_reg <= A_next;
         	B_reg <= B_next;
         	X_reg <= X_next;
         	Y_reg <= Y_next;
         	R_reg <= R_next;
         	ACC_reg <= ACC_next;
         	SR1_reg <= SR1_next;
         	SR2_reg <= SR2_next;
         	WR33_reg <= WR33_next;
         	F_reg <= F_next;         
         	CNT_reg <= CNT_next;         
         	I_reg <= I_next;
         	J_reg <= J_next;
         	N_reg <= N_next;
         	M_reg <= M_next;
         	ISF_reg <= ISF_next;
         	FDI_reg <= FDI_next;
         	ramwe_reg <= ramwe_next;
         	stkwe_reg <= stkwe_next;
         	iowe_reg <= iowe_next;
         end

   // FSMD next-state logic
   always @*
   begin
      IP_next = IP_reg;
      DP_next = DP_reg;
      DPB_next = DPB_reg;
      UDP_next = UDP_reg;
      SP_next = SP_reg;
      USP_next = USP_reg;
      PP_next = PP_reg;
      instruction_next = instruction_reg;
      H_next = H_reg;
      L_next = L_reg;
      A_next = A_reg;
      B_next = B_reg;
      X_next = X_reg;
      Y_next = Y_reg;
      R_next = R_reg;
      ACC_next = ACC_reg;
      SR1_next = SR1_reg;
      SR2_next = SR2_reg;
      WR33_next = WR33_reg;
      F_next = F_reg;
      CNT_next = CNT_reg;
      I_next = I_reg;
      J_next = J_reg;
      N_next = N_reg;
      M_next = M_reg;
      ISF_next = ISF_reg;
      FDI_next = FDI_reg;

      case (state_reg)
         stop :
            if (run)
               state_next = start;
            else
            		if (int0 | int1 | int2)
               		state_next = ini_iss;
            		else
               		state_next = stop;
         start :
          begin	
            IP_next = 0;
            SP_next = 0;
            state_next = fetch_decode;
          end	
         fetch_decode :
          begin	
            instruction_next = code;
            IP_next = IP_reg + 1;
            
            	if  ((~ISF_reg)&(int0 | int1 | int2))
            		begin
            			FDI_next = 1'b1;
               		state_next = ini_iss;
			end
            	else
              case (code)
                nop_code :
                    state_next = fetch_decode;
                jmp_code :
                    state_next = load_ha_jmp;
                jz16_code :
                    state_next = jz16_exe;
                jz32_code :
                    state_next = jz32_exe;
                jn16_code :
                    state_next = jn16_exe;
                jn32_code :
                    state_next = jn32_exe;
                jo16_code :
                    state_next = jo16_exe;
                jo32_code :
                    state_next = jo32_exe;
                jco16_code :
                    state_next = jco16_exe;
                jco32_code :
                    state_next = jco32_exe;
                jnz16_code :
                    state_next = jnz16_exe;
                jnz32_code :
                    state_next = jnz32_exe;
                jp16_code :
                    state_next = jp16_exe;
                jp32_code :
                    state_next = jp32_exe;
                jno16_code :
                    state_next = jno16_exe;
                jno32_code :
                    state_next = jno32_exe;
                jnco16_code :
                    state_next = jnco16_exe;
                jnco32_code :
                    state_next = jnco32_exe;
                call_code :
                    state_next = load_ha_call;
                ret_code :
                    state_next = pop_ip_ini;
                reti_code :
                    state_next = ini_reti;
                pusha_code :
                    state_next = pusha_exe;
                pushb_code :
                    state_next = pushb_exe;
                popa_code :
                    state_next = dec_spx;
                popb_code :
                    state_next = dec_spx;
                movab_code :
		 begin
                    B_next = A_reg;
                    state_next = fetch_decode;
		 end
                movba_code :
		 begin
                    A_next = B_reg;
                    state_next = fetch_decode;
		 end
                movira_code :
		 begin
                    A_next = I_reg;
                    state_next = fetch_decode;
		 end
                incir_code :
		 begin
                    I_next = I_reg+1;
                    state_next = fetch_decode;
		 end
                incjr_code :
		 begin
                    J_next = J_reg+1;
                    state_next = fetch_decode;
		 end
                decir_code :
		 begin
                    I_next = I_reg-1;
                    state_next = fetch_decode;
		 end
                decjr_code :
		 begin
                    J_next = J_reg-1;
                    state_next = fetch_decode;
		 end
                pushi_code :
                    state_next = pushi_exe;
                pushj_code :
                    state_next = pushj_exe;
                pushn_code :
                    state_next = pushn_exe;
                pushm_code :
                    state_next = pushm_exe;
                popi_code :
                    state_next = dec_spx;
                popj_code :
                    state_next = dec_spx;
                popn_code :
                    state_next = dec_spx;
                popm_code :
                    state_next = dec_spx;
                movjra_code :
		 begin
                    A_next = J_reg;
                    state_next = fetch_decode;
		 end
                movrla_code :
		 begin
                    A_next = R_reg[15:0];
                    state_next = fetch_decode;
		 end
                movrha_code :
		 begin
                    A_next = R_reg[31:16];
                    state_next = fetch_decode;
		 end
                movrlb_code :
		 begin
                    B_next = R_reg[15:0];
                    state_next = fetch_decode;
		 end
                movrhb_code :
		 begin
                    B_next = R_reg[31:16];
                    state_next = fetch_decode;
		 end
                movracc_code :
		 begin
                    ACC_next = R_reg;
                    state_next = fetch_decode;
		 end
                movaaccl_code :
		 begin
                    ACC_next[15:0] = A_reg;
                    ACC_next[31:16] = ACC_reg[31:16];
                    state_next = fetch_decode;
		 end
                movbaccl_code :
		 begin
                    ACC_next[15:0] = B_reg;
                    ACC_next[31:16] = ACC_reg[31:16];
                    state_next = fetch_decode;
		 end
                movaacch_code :
		 begin
                    ACC_next[31:16] = A_reg;
                    ACC_next[15:0] = ACC_reg[15:0];
                    state_next = fetch_decode;
		 end
                movbacch_code :
		 begin
                    ACC_next[31:16] = B_reg;
                    ACC_next[15:0] = ACC_reg[15:0];
                    state_next = fetch_decode;
		 end
                movaccla_code :
		 begin
                    A_next = ACC_reg[15:0];
                    state_next = fetch_decode;
		 end
                movacclb_code :
		 begin
                    B_next = ACC_reg[15:0];
                    state_next = fetch_decode;
		 end
                movaccha_code :
		 begin
                    A_next = ACC_reg[31:16];
                    state_next = fetch_decode;
		 end
                movacchb_code :
		 begin
                    B_next = ACC_reg[31:16];
                    state_next = fetch_decode;
		 end
                stospa_code :
		 begin
                    A_next = {8'b00000000, SP_reg};
                    state_next = fetch_decode;
		 end
                stospb_code :
		 begin
                    B_next = {8'b00000000, SP_reg};
                    state_next = fetch_decode;
		 end
                stouspa_code :
		 begin
                    A_next = {8'b00000000, USP_reg};
                    state_next = fetch_decode;
		 end
                stouspb_code :
		 begin
                    B_next = {8'b00000000, USP_reg};
                    state_next = fetch_decode;
		 end
                ldusp_code :
		 begin
                    USP_next = SP_reg;
                    state_next = fetch_decode;
		 end
                lduspa_code :
		 begin
                    USP_next = A_reg[7:0];
                    state_next = fetch_decode;
		 end
                lduspb_code :
		 begin
                    USP_next = B_reg[7:0];
                    state_next = fetch_decode;
		 end
                lduspr_code :
		 begin
                    USP_next = R_reg[7:0];
                    state_next = fetch_decode;
		 end
                incusp_code :
		 begin
                    USP_next = USP_reg + 1;
                    state_next = fetch_decode;                
		 end
                decusp_code :
		 begin
                    USP_next = USP_reg - 1;
                    state_next = fetch_decode;                
		 end
                movka_code :
                    state_next = load_khx;
                movkb_code :
                    state_next = load_khx;
                movki_code :
                    state_next = load_khx;
                movkj_code :
                    state_next = load_khx;
                movkn_code :
                    state_next = load_khx;
                movkm_code :
                    state_next = load_khx;
                lduspk_code :
                    state_next = load_usp;     
                movam_code :           
                    state_next = load_hi_movxm;
                movbm_code :           
                    state_next = load_hi_movxm;
                movrlm_code :           
                    state_next = load_hi_movxm;
                movrhm_code :           
                    state_next = load_hi_movxm;
                movma_code :           
                    state_next = load_hi_movmx;
                movmb_code :           
                    state_next = load_hi_movmx;
                incmpm_code :           
                    state_next = load_hi_movmx;
                decmpm_code :           
                    state_next = load_hi_movmx;
                movai_code :
                    state_next = load_hi_movi;
                movbi_code :
                    state_next = load_hi_movi;
                movrli_code :
                    state_next = load_hi_movi;
                movrhi_code :
                    state_next = load_hi_movi;
                movia_code :
                    state_next = load_hi_movi;
                movib_code : 
                    state_next = load_hi_movi;
                movaipp_code :
                    state_next = load_hi_movi;
                movbipp_code :
                    state_next = load_hi_movi;
                movrlipp_code :
                    state_next = load_hi_movi;
                movrhipp_code :
                    state_next = load_hi_movi;
                movippa_code :
                    state_next = load_hi_movi;
                movippb_code :
                    state_next = load_hi_movi;
                movmmia_code :
                    state_next = load_hi_movi;
                movmmib_code :
                    state_next = load_hi_movi;
                movas_code :
                    state_next = movas_exe;
                movbs_code :
                    state_next = movbs_exe;
                movrls_code :
                    state_next = movrls_exe;
                movrhs_code :
                    state_next = movrhs_exe;
                movsa_code :
                    state_next = movsa_exe;
                movsb_code :
                    state_next = movsb_exe;
                uadd_code :
		 begin
                    WR33_next = {17'b00000000000000000,A_reg}+{17'b00000000000000000,B_reg};
                    state_next = add_result;
		 end
                sadd_code :
		 begin
                    if (~A_reg[15] && ~B_reg[15])
                        WR33_next = {17'b00000000000000000,A_reg}+{17'b00000000000000000,B_reg};
                    else
			if (~A_reg[15] && B_reg[15])
                        	WR33_next = {17'b00000000000000000,A_reg}+{17'b11111111111111111,B_reg};
                    	else
				if (A_reg[15] && ~B_reg[15])
                        		WR33_next = {17'b11111111111111111,A_reg}+{17'b00000000000000000,B_reg};
                    		else
                        		WR33_next = {17'b11111111111111111,A_reg}+{17'b11111111111111111,B_reg};
                    state_next = add_result;
		 end
                ac_code :
		 begin
                    WR33_next = {1'b0,R_reg}+{1'b0,ACC_reg};
                    state_next = add_result;
		 end
                umul_code :
		 begin
                    WR33_next = 0;
                    CNT_next = 0;
                    SR1_next = {17'b00000000000000000,A_reg};
                    SR2_next = {17'b00000000000000000,B_reg};
                    state_next = xmul_exe;
		 end
                smul_code :
		 begin
                    WR33_next = 0;
                    CNT_next = 0;
                    if (~A_reg[15])
                             SR1_next = {17'b00000000000000000,A_reg};
                    else
                             SR1_next = {17'b11111111111111111,A_reg};
                    if (~B_reg[15])
                             SR2_next = {17'b00000000000000000,B_reg};
                    else
                             SR2_next = {17'b11111111111111111,B_reg};
                    state_next = xmul_exe;
		 end
                umac_code :
		 begin
                    WR33_next = 0;
                    CNT_next = 0;
                    SR1_next = {17'b00000000000000000,A_reg};
                    SR2_next = {17'b00000000000000000,B_reg};
                    state_next = xmul_exe;
		 end
                smac_code :
		 begin
                    WR33_next = 0;
                    CNT_next = 0;
                    if (~A_reg[15])
                        SR1_next = {17'b00000000000000000,A_reg};
                    else
                        SR1_next = {17'b11111111111111111,A_reg};
                    if (~B_reg[15])
                        SR2_next = {17'b00000000000000000,B_reg};
                    else
                        SR2_next = {17'b11111111111111111,B_reg};
                    state_next = xmul_exe;
		 end
                sracc_code :
		 begin
                    WR33_next = {1'b0, ACC_reg};
                    CNT_next = A_reg[5:0];
                    state_next = sxacc_exe;
		 end
                sraacc_code :
		 begin
                    WR33_next = {1'b0, ACC_reg};
                    CNT_next = A_reg[5:0];
                    state_next = sxacc_exe;
		 end
                slacc_code :
		 begin
                    WR33_next = {1'b0, ACC_reg};
                    CNT_next = A_reg[5:0];
                    state_next = sxacc_exe;
		 end
                nota_code :
		 begin
                    WR33_next = {17'b00000000000000000, ~A_reg};
                    state_next = log_result;
		 end
                notb_code :
		 begin
                    WR33_next = {17'b00000000000000000, ~B_reg};
                    state_next = log_result;
		 end
                and_code :
		 begin
                    WR33_next = {17'b00000000000000000, (A_reg & B_reg)};
                    state_next = log_result;
		 end
                or_code :
		 begin
                    WR33_next = {17'b00000000000000000, (A_reg | B_reg)};
                    state_next = log_result;
		 end
                xor_code :
		 begin
                    WR33_next = {17'b00000000000000000, (A_reg ^ B_reg)};
                    state_next = log_result;
		 end
                cmpin_code :
		 begin
                    WR33_next = {17'b00000000000000000,I_reg}-{17'b00000000000000000,N_reg};
                    state_next = cmp_result;
		 end
                cmpjm_code :
		 begin
                    WR33_next = {17'b00000000000000000,J_reg}-{17'b00000000000000000,M_reg};
                    state_next = cmp_result;
		 end
                outa_code :           
                    state_next = load_ioadd;
                ina_code :           
                    state_next = load_ioadd;
                outk_code :           
                    state_next = load_iok;
                default :
                    state_next = stop;
              endcase
          end	

         load_ha_jmp : 
          begin	
            IP_next = IP_reg + 1;
            H_next = code;
            state_next = load_la_jmp;
          end	
         load_la_jmp :
          begin	
            L_next = code;
            state_next = load_ip;
          end	
         load_ip :
          begin	
            IP_next = {H_reg[CODE_ADD_SIZE-CODE_SIZE-1:0], L_reg};
            state_next = fetch_decode;
          end	
         jz16_exe :
               if (F_reg[0])
                   state_next = load_ha_jmp;
               else
		begin
                  IP_next = IP_reg + 2;
                  state_next = fetch_decode;
		end
         jz32_exe :
               if (F_reg[4])
                   state_next = load_ha_jmp;
               else
		begin
                   IP_next = IP_reg + 2;
                   state_next = fetch_decode;
		end
         jn16_exe :
               if (F_reg[1])
                   state_next = load_ha_jmp;
               else
		begin
                   IP_next = IP_reg + 2;
                   state_next = fetch_decode;
		end
         jn32_exe :
               if (F_reg[5])
                    state_next = load_ha_jmp;
               else
		begin
                    IP_next = IP_reg + 2;
                    state_next = fetch_decode;
		end
         jo16_exe :
               if (F_reg[2])
                    state_next = load_ha_jmp;
               else
		begin
                    IP_next = IP_reg + 2;
                    state_next = fetch_decode;
		end
         jo32_exe :
               if (F_reg[6])
                    state_next = load_ha_jmp;
               else
		begin
                    IP_next = IP_reg + 2;
                    state_next = fetch_decode;
		end
         jco16_exe :
               if (F_reg[3])
                    state_next = load_ha_jmp;
               else
		begin
                    IP_next = IP_reg + 2;
                    state_next = fetch_decode;
		end
         jco32_exe :
               if (F_reg[7])
                    state_next = load_ha_jmp;
               else
		begin
                    IP_next = IP_reg + 2;
                    state_next = fetch_decode;
		end
         jnz16_exe :
               if (~F_reg[0])
                   state_next = load_ha_jmp;
               else
		begin
                  IP_next = IP_reg + 2;
                  state_next = fetch_decode;
		end
         jnz32_exe :
               if (~F_reg[4])
                   state_next = load_ha_jmp;
               else
		begin
                   IP_next = IP_reg + 2;
                   state_next = fetch_decode;
		end
         jp16_exe :
               if (~F_reg[1])
                   state_next = load_ha_jmp;
               else
		begin
                   IP_next = IP_reg + 2;
                   state_next = fetch_decode;
		end
         jp32_exe :
               if (~F_reg[5])
                    state_next = load_ha_jmp;
               else
		begin
                    IP_next = IP_reg + 2;
                    state_next = fetch_decode;
		end
         jno16_exe :
               if (~F_reg[2])
                    state_next = load_ha_jmp;
               else
		begin
                    IP_next = IP_reg + 2;
                    state_next = fetch_decode;
		end
         jno32_exe :
               if (~F_reg[6])
                    state_next = load_ha_jmp;
               else
		begin
                    IP_next = IP_reg + 2;
                    state_next = fetch_decode;
		end
         jnco16_exe :
               if (~F_reg[3])
                    state_next = load_ha_jmp;
               else
		begin
                    IP_next = IP_reg + 2;
                    state_next = fetch_decode;
		end
         jnco32_exe :
               if (~F_reg[7])
                    state_next = load_ha_jmp;
               else
		begin
                    IP_next = IP_reg + 2;
                    state_next = fetch_decode;
		end
         load_ha_call : 
          begin	
               IP_next = IP_reg + 1;
               H_next = code;
               state_next = load_la_call;
          end	
         load_la_call :
          begin	
               IP_next = IP_reg + 1;
               L_next = code;
               state_next = push_ip;
          end	
         push_ip :
          begin	
               SP_next = SP_reg + 1;
               state_next = load_ip;
          end	
         pop_ip_ini :
          begin	
               SP_next = SP_reg - 1;
               state_next = pop_ip;
          end	
         pop_ip :
          begin	
               IP_next =sin[11:0];
               state_next = fetch_decode;
          end	
         pusha_exe :
          begin	
               SP_next = SP_reg + 1;
               state_next = fetch_decode;
          end	
         pushb_exe :
          begin	
               SP_next = SP_reg + 1;
               state_next = fetch_decode;
          end	
         pushi_exe :
          begin	
               SP_next = SP_reg + 1;
               state_next = fetch_decode;
          end	
         pushj_exe :
          begin	
               SP_next = SP_reg + 1;
               state_next = fetch_decode;
          end	
         pushn_exe :
          begin	
               SP_next = SP_reg + 1;
               state_next = fetch_decode;
          end	
         pushm_exe :
          begin	
               SP_next = SP_reg + 1;
               state_next = fetch_decode;
          end	
         dec_spx :
          begin	
               SP_next = SP_reg - 1;
               state_next = point_spx;
          end	
         point_spx :
               case (instruction_reg)
                    popa_code :
                        state_next = popa_exe;
                    popb_code :
                        state_next = popb_exe;
                    popi_code :
                        state_next = popi_exe;
                    popj_code :
                        state_next = popj_exe;
                    popn_code :
                        state_next = popn_exe;
                    default :
                        state_next = popm_exe;
               endcase
         popa_exe :
          begin	
               A_next = sin;
               state_next = fetch_decode;
          end	
         popb_exe :
          begin	
               B_next = sin;
               state_next = fetch_decode;
          end	
         popi_exe :
          begin	
               I_next = sin;
               state_next = fetch_decode;
          end	
         popj_exe :
          begin	
               J_next = sin;
               state_next = fetch_decode;
          end	
         popn_exe :
          begin	
               N_next = sin;
               state_next = fetch_decode;
          end	
         popm_exe :
          begin	
               M_next = sin;
               state_next = fetch_decode;
          end	
         load_khx : 
          begin	
               IP_next = IP_reg + 1;
               H_next = code;
               state_next = load_klx;
          end	
         load_klx :
          begin	
               IP_next = IP_reg + 1;
               L_next = code;
               case (instruction_reg)
                    movka_code :
                        state_next = store_ka;
                    movkb_code :
                        state_next = store_kb;
                    movki_code :
                        state_next = store_ki;
                    movkj_code :
                        state_next = store_kj;
                    movkn_code :
                        state_next = store_kn;
                    default :
                        state_next = store_km;
               endcase
          end	
         store_ka :
          begin	
               A_next = {H_reg, L_reg};
               state_next = fetch_decode;
          end	
         store_kb :
          begin	
               B_next = {H_reg, L_reg};
               state_next = fetch_decode;
          end	
         store_ki :
          begin	
               I_next = {H_reg, L_reg};
               state_next = fetch_decode;
          end	
         store_kj :
          begin	
               J_next = {H_reg, L_reg};
               state_next = fetch_decode;
          end	
         store_kn :
          begin	
               N_next = {H_reg, L_reg};
               state_next = fetch_decode;
          end	
         store_km :
          begin	
               M_next = {H_reg, L_reg};
               state_next = fetch_decode;
          end	
         load_usp :
          begin	
               IP_next = IP_reg + 1;
               USP_next = code;
               state_next = fetch_decode;
          end	
         load_hi_movxm : 
          begin	
               IP_next = IP_reg + 1;
               H_next = code;
               state_next = load_li_movxm;
          end	
         load_li_movxm :
          begin	
               IP_next = IP_reg + 1;
               L_next = code;
               state_next = load_dp_movxm;
          end	
         load_dp_movxm :
          begin	
               DP_next = {H_reg[DATA_ADD_SIZE-CODE_SIZE-1:0], L_reg};
               case (instruction_reg)
                    movam_code :
                        state_next = movam_exe;
                    movbm_code :
                        state_next = movbm_exe;
                    movrlm_code :
                        state_next = movrlm_exe;
                    default :
                        state_next = movrhm_exe;
               endcase
          end	
         movam_exe :
               state_next = fetch_decode;
         movbm_exe :
               state_next = fetch_decode;
         movrlm_exe :
               state_next = fetch_decode;
         movrhm_exe :
               state_next = fetch_decode;
         load_hi_movmx : 
          begin	
               IP_next = IP_reg + 1;
               H_next = code;
               state_next = load_li_movmx;
          end	
         load_li_movmx :
          begin	
               IP_next = IP_reg + 1;
               L_next = code;
               state_next = load_dp_movmx;
          end	
         load_dp_movmx :
          begin	
               DP_next = {H_reg[DATA_ADD_SIZE-CODE_SIZE-1:0], L_reg};
               case (instruction_reg)
                    movma_code :
                        state_next = movma_exe;
                    movmb_code :
                        state_next = movmb_exe;
                    incmpm_code :
                        state_next = load_xpp;
                    default :
                        state_next = load_xmm;
               endcase
          end	
         movma_exe :
          begin	
              A_next = din;
              state_next = fetch_decode;
          end	
         movmb_exe :
          begin	
              B_next = din;
              state_next = fetch_decode;
          end	
         load_xpp :
		begin
                    X_next = din+1;
                    state_next = movxrm;
		end
         load_xmm :
		begin
                    X_next = din-1;
                    state_next = movxrm;
		end
         movxrm :
		begin
                    DP_next = DP_reg + 1;
                    state_next = load_y;
		end
         load_y :
		begin
              	    Y_next = din;
                    state_next = cmp_xy;
		end
         cmp_xy :
		begin
                    WR33_next = {17'b00000000000000000,X_reg}-{17'b00000000000000000,Y_reg};
                    state_next = cmp_result;
		end
         load_hi_movi : 
          begin	
              IP_next = IP_reg + 1;
              H_next = code;
              state_next = load_li_movi;
          end	
         load_li_movi :
          begin	
              IP_next = IP_reg + 1;
              L_next = code;
              state_next = load_dp_movi;
          end	
         load_dp_movi :
          begin	
              DP_next = {H_reg[DATA_ADD_SIZE-CODE_SIZE-1:0], L_reg};
              DPB_next = {H_reg[DATA_ADD_SIZE-CODE_SIZE-1:0], L_reg};
              state_next = load_ix;
          end	
         load_ix :
          begin	
              DP_next = din[DATA_ADD_SIZE-1:0];
              UDP_next = din[DATA_ADD_SIZE-1:0];
              case (instruction_reg)
                   movai_code :
                        state_next = movam_exe;
                   movbi_code :
                        state_next = movbm_exe;
                   movrli_code :
                        state_next = movrlm_exe;
                   movrhi_code :
                        state_next = movrhm_exe;
                   movia_code :
                        state_next = movia_exe;
                   movib_code :
                        state_next = movib_exe;
                   movaipp_code :
                        state_next = movaipp_exe;
                   movbipp_code :
                        state_next = movbipp_exe;
                   movrlipp_code :
                        state_next = movrlipp_exe;
                   movrhipp_code :
                        state_next = movrhipp_exe;
                   movippa_code :
                        state_next = movippa_exe;
                   movippb_code :
                        state_next = movippb_exe;
                   movmmia_code :
                         state_next = ix_dec_a;
                   default :
                         state_next = ix_dec_b;
              endcase
          end	
         movia_exe :
          begin	
              A_next = din;
              state_next = fetch_decode;
          end	
         movib_exe :
          begin	
              B_next = din;
              state_next = fetch_decode;
          end	
         movaipp_exe :
              state_next = ix_inc;
         movbipp_exe :
              state_next = ix_inc;
         movrlipp_exe :
              state_next = ix_inc;
         movrhipp_exe :
              state_next = ix_inc;
         ix_inc :
          begin	
              UDP_next = UDP_reg + 1;
              DP_next = DPB_reg;
              state_next = ix_sto;
          end	
         ix_sto :      
              state_next = fetch_decode;
         movippa_exe :
          begin	
              A_next = din;
              state_next = ix_inc;
          end	
         movippb_exe :
          begin	
              B_next = din;
              state_next = ix_inc;
          end	
         ix_dec_a :
          begin	
              UDP_next = UDP_reg - 1;
              DP_next = DP_reg-1;
              state_next = movmmia_exe;
          end	
         movmmia_exe :
          begin	
              A_next = din;
              state_next = ix_dest;
          end	
         ix_dec_b :
          begin	
              UDP_next = UDP_reg - 1;
              DP_next = DP_reg-1;
              state_next = movmmib_exe;
          end	
         movmmib_exe :
          begin	
              B_next = din;
              state_next = ix_dest;
          end	
         ix_dest :
          begin	
              DP_next = DPB_reg;
              state_next = ix_sto;
          end	
         movas_exe :
              state_next = fetch_decode;
         movbs_exe :
              state_next = fetch_decode;
         movrls_exe :
              state_next = fetch_decode;
         movrhs_exe :
              state_next = fetch_decode;
         movsa_exe :
          begin	
              A_next = sin;
              state_next = fetch_decode;
          end	
         movsb_exe :
          begin	
              B_next = sin;
              state_next = fetch_decode;
          end	
         add_result :
          begin	
              if (WR33_reg[15:0]==16'h0000)
                F_next[0] = 1'b1;
              else
                F_next[0] = 1'b0;
              
              if(A_reg[15] && B_reg[15] && ~WR33_reg[15])
                F_next[3] = 1'b1; 
              else
		if (~A_reg[15] && ~B_reg[15] && WR33_reg[15])
                	F_next[3] = 1'b1;
              	else
                	F_next[3] = 1'b0;
                       
              F_next[1] = WR33_reg[15];
              F_next[2] = WR33_reg[16];
              
              if (WR33_reg[31:0]==32'h00000000)
                F_next[4] = 1'b1;
              else
                F_next[4] = 1'b0;
              
              if(A_reg[15] && B_reg[15] && ~WR33_reg[31])
                F_next[7] = 1'b1; 
              else
		if (~A_reg[15] && ~B_reg[15] && WR33_reg[31])
                	F_next[7] = 1'b1;
              	else
                	F_next[7] = 1'b0;
                       
              F_next[5] = WR33_reg[31];
              F_next[6] = WR33_reg[32];

              if ((instruction_reg==ac_code) || (instruction_reg==umac_code) || (instruction_reg==smac_code))
                    ACC_next = WR33_reg[31:0];
              else 
                    R_next = WR33_reg[31:0];
              
              state_next = fetch_decode;
          end	
         cmp_result :
          begin	
              if (WR33_reg[15:0]==16'h0000)
                F_next[0] = 1'b1;
              else
                F_next[0] = 1'b0;
              
              F_next[3] = 1'b0;
                       
              F_next[1] = WR33_reg[15];
              F_next[2] = WR33_reg[16];
              
              if (WR33_reg[31:0]==32'h00000000)
                F_next[4] = 1'b1;
              else
                F_next[4] = 1'b0;
              
              F_next[7] = 1'b0;
                       
              F_next[5] = WR33_reg[31];
              F_next[6] = WR33_reg[32];

              R_next = WR33_reg[31:0];
              
              state_next = fetch_decode;
          end	
         xmul_exe :
          begin	
              if (CNT_reg < 16)
	       begin	
                if (SR2_reg[0])
                    if ((instruction_reg==umul_code) || (instruction_reg==umac_code))
                        WR33_next = WR33_reg + SR1_reg;
                    else
                        if (CNT_reg == 15)
                            WR33_next = WR33_reg + ~SR1_reg + 1;
                        else
                            WR33_next = WR33_reg + SR1_reg;
                    
                CNT_next = CNT_reg + 1;
                SR1_next = {SR1_reg[31:0], 1'b0}; 
                SR2_next = {1'b0, SR2_reg[32:1]}; 
                state_next = xmul_exe;
	       end	
              else
	       begin	
                if (WR33_reg[15:0]==16'h0000)
                    F_next[0] = 1'b1;
                else
                    F_next[0] = 1'b0;
              
                if(A_reg[15] && B_reg[15] && WR33_reg[15])
                    F_next[3] = 1'b1; 
                else
			if (~A_reg[15] && ~B_reg[15] && WR33_reg[15])
                    		F_next[3] = 1'b1;
                	else
                    		F_next[3] = 1'b0;
                       
                F_next[1] = WR33_reg[15];
                F_next[2] = WR33_reg[16];
              
                if (WR33_reg[31:0]==32'h00000000)
                    F_next[4] = 1'b1;
                else
                    F_next[4] = 1'b0;
              
                if(A_reg[15] && B_reg[15] && WR33_reg[31])
                    F_next[7] = 1'b1; 
                else
			if (~A_reg[15] && ~B_reg[15] && WR33_reg[31])
                    		F_next[7] = 1'b1;
                	else
                    		F_next[7] = 1'b0;
                       
                F_next[5] = WR33_reg[31];
                F_next[6] = WR33_reg[32];

                if ((instruction_reg==umac_code) || (instruction_reg==smac_code))
		 begin
                    WR33_next = WR33_reg+{1'b0,ACC_reg};
                    state_next = add_result;
		 end
                else
		 begin
                    R_next = WR33_reg[31:0];
                    state_next = fetch_decode;
		 end
	       end	
          end	
         sxacc_exe :
          begin	
              if (CNT_reg == 0)
	       begin
                if (WR33_reg[15:0]==16'h0000)
                  F_next[0] = 1'b1;
                else
                  F_next[0] = 1'b0;
      
                F_next[3] = 1'b0;
               
                F_next[1] = WR33_reg[15];
                F_next[2] = WR33_reg[16];
      
                if (WR33_reg[31:0]==32'h00000000)
                  F_next[4] = 1'b1;
                else
                  F_next[4] = 1'b0;
      
                F_next[7] = 1'b0;
               
                F_next[5] = WR33_reg[31];
                F_next[6] = WR33_reg[32];

                R_next = WR33_reg[31:0];
                state_next = fetch_decode;
	       end
              else
	       begin
                if ((instruction_reg == sracc_code) || (instruction_reg == sraacc_code))
                    if (instruction_reg == sracc_code)
                        WR33_next = {1'b0, WR33_reg[32:1]};
                    else
                        if (WR33_reg[31])
                            WR33_next = {2'b11, WR33_reg[31:1]};
                        else
                            WR33_next = {1'b0, WR33_reg[32:1]};
                  else
                    WR33_next = {WR33_reg[31:0], 1'b0};
              
                  CNT_next = CNT_reg - 1;
                  state_next = sxacc_exe;
	       end
          end	
         log_result :
          begin	
              if (WR33_reg[15:0]==16'h0000)
	       begin
                F_next[0] = 1'b1;
                F_next[4] = 1'b1;
	       end
              else
	       begin
                F_next[0] = 1'b0;
                F_next[4] = 1'b0;
	       end
       
              F_next[3] = 1'b0;       
              F_next[1] = 1'b0;
              F_next[2] = 1'b0;
       
              F_next[7] = 1'b0;       
              F_next[5] = 1'b0;
              F_next[6] = 1'b0;
         
              R_next = WR33_reg[31:0];
              state_next = fetch_decode;         
          end	
         load_ioadd : 
          begin	
               IP_next = IP_reg + 1;
               PP_next = code;
               case (instruction_reg)
                    outa_code :
                        state_next = outa_exe;
                    default :
                        state_next = ina_exe;
               endcase
          end	
         outa_exe :
               state_next = fetch_decode;
         ina_exe :
          begin	
              A_next = {8'b00000000, io_i};
              state_next = fetch_decode;
          end	
         load_iok : 
          begin	
               IP_next = IP_reg + 1;
               H_next = code;
               state_next = ld_ioadd4k;
          end	
         ld_ioadd4k : 
          begin	
               IP_next = IP_reg + 1;
               PP_next = code;
               state_next = outk_exe;
          end	
         outk_exe :
               state_next = fetch_decode;
         ini_iss : 
          begin	
               PP_next = 8'h01;
               ISF_next = 1'b1;       
               state_next = in_intx_F;
          end	
         in_intx_F : 
          begin	
                 L_next = io_i;
		    if (int0)
               		state_next = set_int0_F;
                    else
                        if (int1)
               			state_next = set_int1_F;
                        else
               			state_next = set_int2_F;
          end	
         set_int0_F :
               state_next = ld_iss_vec;
         set_int1_F :
               state_next = ld_iss_vec;
         set_int2_F :
               state_next = ld_iss_vec;
         ld_iss_vec :
	    begin
               if (int0)
		begin
              		H_next = INT0_VEC_ADD[15 : 8];
              		L_next = INT0_VEC_ADD[7 : 0];
		end
               else
                     if (int1)
		       begin
              		H_next = INT1_VEC_ADD[15 : 8];
              		L_next = INT1_VEC_ADD[7 : 0];
		       end
                     else
		       begin
              		H_next = INT2_VEC_ADD[15 : 8];
              		L_next = INT2_VEC_ADD[7 : 0];
		       end
                                                                               
               if (FDI_reg)
                     state_next = push_ip_int;
               else
                     state_next = load_ip;
                   
	    end
         push_ip_int :
          begin	
               SP_next = SP_reg + 1;
               state_next = push_rl;
          end	
         push_rl :
          begin	
               SP_next = SP_reg + 1;
               state_next = push_rh;
          end	
         push_rh :
          begin	
               SP_next = SP_reg + 1;
               state_next = push_f;
          end	
         push_f :
          begin	
               SP_next = SP_reg + 1;
               state_next = load_ip;
          end	
        ini_reti :
         begin    
	       ISF_next = 1'b0;	
                    
             if (FDI_reg)
		  begin
		     	FDI_next = 1'b0;
		     	SP_next = SP_reg-1;
                   state_next = pop_f;
		  end
            else
                     state_next = stop;
          end    
         pop_f :
          begin	
               F_next = sin[7:0];
               state_next = pop_rh_ini;
          end	
         pop_rh_ini :
          begin	
               SP_next = SP_reg - 1;
               state_next = pop_rh;
          end	
         pop_rh :
          begin	
               H_next =sin[15:8];
               L_next =sin[7:0];
               state_next = pop_rl_ini;
          end	
         pop_rl_ini :
          begin	
               SP_next = SP_reg - 1;
               state_next = pop_rl_nres;
          end	
         pop_rl_nres :
          begin	
               R_next ={H_reg, L_reg, sin};
               state_next = pop_ip_ini;
          end	
         default :
              state_next =stop;
      endcase

   end

   // look-ahead output logic
   always @*
   begin
      ramwe_next = 1'b0;
      stkwe_next = 1'b0;
      iowe_next = 1'b0;

      case (state_next)
        push_ip :
           stkwe_next = 1'b1;
        pusha_exe :
           stkwe_next = 1'b1;
        pushb_exe :
           stkwe_next = 1'b1;
        pushi_exe :
           stkwe_next = 1'b1;
        pushj_exe :
           stkwe_next = 1'b1;
        pushn_exe :
           stkwe_next = 1'b1;
        pushm_exe :
           stkwe_next = 1'b1;
        movam_exe :
           ramwe_next = 1'b1;
        movbm_exe :
           ramwe_next = 1'b1;
        movxrm :
           ramwe_next = 1'b1;
        movrhm_exe :
           ramwe_next = 1'b1;
        movaipp_exe :
           ramwe_next = 1'b1;
        movbipp_exe :
          ramwe_next = 1'b1;
        movrlipp_exe :
           ramwe_next = 1'b1;
        movrhipp_exe :
           ramwe_next = 1'b1;
        ix_sto :
           ramwe_next = 1'b1;
        movas_exe :
           stkwe_next = 1'b1;
        movbs_exe :
           stkwe_next = 1'b1;
        movrls_exe :
           stkwe_next = 1'b1;
        movrhs_exe :
           stkwe_next = 1'b1;      
        outa_exe :
           iowe_next = 1'b1;
        outk_exe :
           iowe_next = 1'b1;
        set_int0_F :
           iowe_next = 1'b1;
        set_int1_F :
           iowe_next = 1'b1;
        set_int2_F :
           iowe_next = 1'b1;
        push_ip_int :
           stkwe_next = 1'b1;
        push_rl :
           stkwe_next = 1'b1;
        push_rh :
           stkwe_next = 1'b1;
        push_f :
           stkwe_next = 1'b1;
	endcase
   end

   //interconnection:
   assign IP_bak = IP_reg-1;
   
   //outputs
   assign state = state_reg;
   assign flags = F_reg;
   assign code_add = IP_reg;
   assign data_add = DP_reg;
   assign data_we = ramwe_reg;
   assign stk_we = stkwe_reg;
   assign io_add = PP_reg;
   assign io_we = iowe_reg;
   assign r_out = R_reg;

   //Moore outputs:
assign dout =  (state_reg==movam_exe)||(state_reg==movaipp_exe) ? A_reg  : ((state_reg==movbm_exe)||(state_reg==movbipp_exe) ? B_reg : ((state_reg==movrlm_exe)||(state_reg==movrlipp_exe) ? R_reg[15:0] : ((state_reg==movrhm_exe)||(state_reg==movrhipp_exe) ? R_reg[31:16] : ((state_reg==ix_sto) ? {5'b00000,UDP_reg} : ((state_reg==movxrm) ? X_reg : 16'h0000)))));
assign sout =  (state_reg==push_ip) ? {4'b0000,IP_reg} : ((state_reg==pusha_exe)||(state_reg==movas_exe) ? A_reg : ((state_reg==pushb_exe)||(state_reg==movbs_exe) ? B_reg : ((state_reg==movrls_exe) ? R_reg[15:0] : ((state_reg==movrhs_exe) ? R_reg[31:16] : ((state_reg==pushi_exe)? I_reg:((state_reg==pushj_exe)? J_reg:((state_reg==pushn_exe)? N_reg:((state_reg==pushm_exe)? M_reg:((state_reg==push_ip_int)? {4'b0000,IP_bak}: ((state_reg==push_rl)? R_reg[15:0] : ((state_reg==push_rh)? R_reg[31:16]:((state_reg==push_f)? {8'h00,F_reg}: 16'h0000))))))))))));
assign stk_add =  (state_reg==movas_exe)||(state_reg==movbs_exe)||(state_reg==movrls_exe)||(state_reg==movrhs_exe)||(state_reg==movsa_exe)||(state_reg==movsb_exe) ? USP_reg : SP_reg;
assign io_o =  (state_reg==outa_exe) ? A_reg[7:0]  : ((state_reg==outk_exe) ? H_reg : ((state_reg==set_int0_F)? (L_reg | 8'h01):((state_reg==set_int1_F)? (L_reg | 8'h02):((state_reg==set_int2_F)? (L_reg | 8'h04): 8'h00))));
 endmodule
