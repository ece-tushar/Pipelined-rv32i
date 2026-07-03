module pipe_IF_ID #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32
    )(
       input logic Clk, Rst, Flush, WEn,

       input logic [ADDR_WIDTH-1:0] PC_in,
       input logic [DATA_WIDTH-1:0] IM_in,

       output logic [ADDR_WIDTH-1:0] PC_out,
       output logic [DATA_WIDTH-1:0] IM_out
       );

   struct packed {
        logic [ADDR_WIDTH-1:0] PC;
        logic [DATA_WIDTH-1:0] IM;
   } IF_ID;

   always_ff @(posedge Clk) begin
        if (Rst) begin
            IF_ID <= '0;
        end
        else if (Flush) begin
            IF_ID.IM  <= 32'h0000_0013;   // Canonical NOP
            IF_ID.PC  <= '0;
        end
        else if (WEn) begin
            IF_ID.PC  <= PC_in;
            IF_ID.IM  <= IM_in;
        end
        // else - hold previous data
   end

   assign PC_out  = IF_ID.PC;
   assign IM_out  = IF_ID.IM;

endmodule

module pipe_ID_EX #(
    parameter ADDR_WIDTH     = 8,
    parameter REG_ADDR_WIDTH = 5,
    parameter CTRL_WORD_WIDTH = 17,
    parameter DATA_WIDTH     = 32
    )( input logic Clk,Rst,Flush,
    
       input logic [ADDR_WIDTH-1:0] PC_in,
       input logic [DATA_WIDTH-1:0] Rs1_in,
       input logic [DATA_WIDTH-1:0] Rs2_in,
       input logic [DATA_WIDTH-1:0] Imm_in,
       input logic [DATA_WIDTH-1:0] IM_in,
        
       output logic [ADDR_WIDTH-1:0] PC_out,
       output logic [DATA_WIDTH-1:0] Rs1_out,
       output logic [DATA_WIDTH-1:0] Rs2_out,
       output logic [DATA_WIDTH-1:0] Imm_out,
       output logic [DATA_WIDTH-1:0] IM_out
       );
       
   struct packed {
        logic [ADDR_WIDTH-1:0] PC;
        logic [DATA_WIDTH-1:0] RS1;
        logic [DATA_WIDTH-1:0] RS2;
        logic [DATA_WIDTH-1:0] IMM;
        logic [DATA_WIDTH-1:0] IM;
        } ID_EX;
   
       always_ff @(posedge Clk) begin
            if (Rst) begin
                ID_EX <= '0;
            end
        
            else if (Flush) begin
                ID_EX.PC <= '0;
                ID_EX.RS1 <= '0;
                ID_EX.RS2 <= '0;
                ID_EX.IMM <= '0;
                ID_EX.IM  <= 32'h0000_0013;   // Canonical NOP
            end
        
            else begin
                ID_EX.PC <= PC_in;
                ID_EX.RS1 <= Rs1_in;
                ID_EX.RS2 <= Rs2_in;
                ID_EX.IMM <= Imm_in;
                ID_EX.IM  <= IM_in;
            end
        end

assign PC_out = ID_EX.PC; 
assign Rs1_out = ID_EX.RS1;             
assign Rs2_out = ID_EX.RS2;             
assign Imm_out = ID_EX.IMM;             
assign IM_out = ID_EX.IM;             
      
endmodule



module pipe_EX_MEM #(
    parameter ADDR_WIDTH     = 8,
    parameter REG_ADDR_WIDTH = 5,
    parameter CTRL_WORD_WIDTH = 9,
    parameter DATA_WIDTH     = 32
    )( input logic Clk,Rst,Flush,
    
       input logic [ADDR_WIDTH-1:0] PC_in,
       input logic [DATA_WIDTH-1:0] Rs2_in,
       input logic [DATA_WIDTH-1:0] ALU_in,
       input logic [DATA_WIDTH-1:0] IM_in,
        
       output logic [ADDR_WIDTH-1:0] PC_out,
       output logic [DATA_WIDTH-1:0] Rs2_out,
       output logic [DATA_WIDTH-1:0] ALU_out,
       output logic [DATA_WIDTH-1:0] IM_out
       );
       
   struct packed {
        logic [ADDR_WIDTH-1:0] PC;
        logic [DATA_WIDTH-1:0] RS2;
        logic [DATA_WIDTH-1:0] ALU;
        logic [DATA_WIDTH-1:0] IM;
        } EX_MEM;
   
       always_ff @(posedge Clk) begin
            if (Rst) begin
                EX_MEM <= '0;
            end
        
            else if (Flush) begin
                EX_MEM.PC <= '0;
                EX_MEM.RS2 <= '0;
                EX_MEM.ALU <= '0;
                EX_MEM.IM  <= 32'h0000_0013;   // Canonical NOP
            end
        
            else begin
                EX_MEM.PC <= PC_in;
                EX_MEM.RS2 <= Rs2_in;
                EX_MEM.ALU <= ALU_in;
                EX_MEM.IM  <= IM_in;
            end
        end


assign PC_out = EX_MEM.PC; 
assign Rs2_out = EX_MEM.RS2;             
assign ALU_out = EX_MEM.ALU;             
assign IM_out = EX_MEM.IM;             
      
endmodule


module pipe_MEM_WB #(
    parameter ADDR_WIDTH     = 8,
    parameter REG_ADDR_WIDTH = 5,
    parameter CTRL_WORD_WIDTH = 3,
    parameter DATA_WIDTH     = 32
    )( input logic Clk,Rst,Flush,
    
       input logic [ADDR_WIDTH-1:0] PC_in,
       input logic [DATA_WIDTH-1:0] ALU_in,
       input logic [DATA_WIDTH-1:0] DM_in,
       input logic [DATA_WIDTH-1:0] IM_in,
        
       output logic [ADDR_WIDTH-1:0] PC_out,
       output logic [DATA_WIDTH-1:0] ALU_out,
       output logic [DATA_WIDTH-1:0] DM_out,
       output logic [DATA_WIDTH-1:0] IM_out
       );
       
   struct packed {
        logic [ADDR_WIDTH-1:0] PC;
        logic [DATA_WIDTH-1:0] DM;
        logic [DATA_WIDTH-1:0] ALU;
        logic [DATA_WIDTH-1:0] IM;
        } MEM_WB;
   
       always_ff @(posedge Clk) begin
            if (Rst) begin
                MEM_WB <= '0;
            end
        
            else if (Flush) begin
                MEM_WB.PC <= '0;
                MEM_WB.DM  <= '0;
                MEM_WB.ALU <= '0;
                MEM_WB.IM  <= 32'h0000_0013;   // Canonical NOP
            end
        
            else begin
                MEM_WB.PC <= PC_in;
                MEM_WB.DM  <= DM_in;
                MEM_WB.ALU <= ALU_in;
                MEM_WB.IM  <= IM_in;
            end
        end

assign PC_out = MEM_WB.PC; 
assign DM_out = MEM_WB.DM;             
assign ALU_out = MEM_WB.ALU;             
assign IM_out = MEM_WB.IM;             
      
endmodule
