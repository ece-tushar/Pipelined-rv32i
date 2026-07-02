module pipe_IF_ID #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32
    )( input logic Clk,Rst,Flush,
    
       input logic [ADDR_WIDTH-1:0] PC_in,
       input logic [ADDR_WIDTH-1:0] PC4_in,
       input logic [DATA_WIDTH-1:0] IM_in,
       
       output logic [ADDR_WIDTH-1:0] PC_out,
       output logic [ADDR_WIDTH-1:0] PC4_out,
       output logic [DATA_WIDTH-1:0] IM_out
       );
       
   struct packed {
        logic [ADDR_WIDTH-1:0] PC;
        logic [ADDR_WIDTH-1:0] PC4;
        logic [DATA_WIDTH-1:0] IM;
        } IF_ID;
   
   always_ff @ (posedge Clk) begin
        if (Rst) begin
            IF_ID <= '0;
            end
        else if (Flush) begin
            IF_ID.IM  <= 32'h0000_0013; // NOP
            IF_ID.PC  <= 0;
            IF_ID.PC4 <= 0;
            end
        else begin
            IF_ID.PC  <= PC_in;
            IF_ID.PC4 <= PC4_in;
            IF_ID.IM  <= IM_in;
            end
   end

assign PC_out = IF_ID.PC; 
assign PC4_out = IF_ID.PC4; 
assign IM_out = IF_ID.IM; 
            
      
endmodule

module pipe_ID_EX #(
    parameter ADDR_WIDTH     = 8,
    parameter REG_ADDR_WIDTH = 5,
    parameter CTRL_WORD_WIDTH = 17,
    parameter DATA_WIDTH     = 32
    )( input logic Clk,Rst,Flush,
    
       input logic [ADDR_WIDTH-1:0] PC4_in,
       input logic [REG_ADDR_WIDTH-1:0] Rd_addr_in,
       input logic [DATA_WIDTH-1:0] Rs1_in,
       input logic [DATA_WIDTH-1:0] Rs2_in,
       input logic [DATA_WIDTH-1:0] Imm_in,
       input logic [DATA_WIDTH-1:0] IM_in,
        
       output logic [ADDR_WIDTH-1:0] PC4_out,
       output logic [REG_ADDR_WIDTH-1:0] Rd_addr_out,
       output logic [DATA_WIDTH-1:0] Rs1_out,
       output logic [DATA_WIDTH-1:0] Rs2_out,
       output logic [DATA_WIDTH-1:0] Imm_out,
       output logic [DATA_WIDTH-1:0] IM_out
       );
       
   struct packed {
        logic [ADDR_WIDTH-1:0] PC4;
        logic [REG_ADDR_WIDTH-1:0] RD;
        logic [DATA_WIDTH-1:0] RS1;
        logic [DATA_WIDTH-1:0] RS2;
        logic [DATA_WIDTH-1:0] IMM;
        logic [DATA_WIDTH-1:0] IM;
        } ID_EX;
   
   always_ff @ (posedge Clk) begin
        if (Rst || Flush) begin
            ID_EX <= '0;
            end

        else begin
            ID_EX.PC4   <= PC4_in;
            ID_EX.RD    <= Rd_addr_in;
            ID_EX.RS1   <= Rs1_in;
            ID_EX.RS2   <= Rs2_in;
            ID_EX.IMM   <= Imm_in;
            ID_EX.IM  <= IM_in;
            end
   end

assign PC4_out = ID_EX.PC4; 
assign Rd_addr_out = ID_EX.RD;             
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
    
       input logic [ADDR_WIDTH-1:0] PC4_in,
       input logic [REG_ADDR_WIDTH-1:0] Rd_addr_in,
       input logic [DATA_WIDTH-1:0] Rs2_in,
       input logic [DATA_WIDTH-1:0] ALU_in,
       input logic [DATA_WIDTH-1:0] IM_in,
        
       output logic [ADDR_WIDTH-1:0] PC4_out,
       output logic [REG_ADDR_WIDTH-1:0] Rd_addr_out,
       output logic [DATA_WIDTH-1:0] Rs2_out,
       output logic [DATA_WIDTH-1:0] ALU_out,
       output logic [DATA_WIDTH-1:0] IM_out
       );
       
   struct packed {
        logic [ADDR_WIDTH-1:0] PC4;
        logic [REG_ADDR_WIDTH-1:0] RD;
        logic [DATA_WIDTH-1:0] RS2;
        logic [DATA_WIDTH-1:0] ALU;
        logic [DATA_WIDTH-1:0] IM;
        } EX_MEM;
   
   always_ff @ (posedge Clk) begin
        if (Rst || Flush) begin
            EX_MEM <= '0;
            end

        else begin
            EX_MEM.PC4   <= PC4_in;
            EX_MEM.RD    <= Rd_addr_in;
            EX_MEM.RS2    <= Rs2_in;
            EX_MEM.ALU   <= ALU_in;
            EX_MEM.IM  <= IM_in;
            end
   end

assign PC4_out = EX_MEM.PC4; 
assign Rd_addr_out = EX_MEM.RD;             
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
    
       input logic [ADDR_WIDTH-1:0] PC4_in,
       input logic [REG_ADDR_WIDTH-1:0] Rd_addr_in,
       input logic [DATA_WIDTH-1:0] ALU_in,
       input logic [DATA_WIDTH-1:0] DM_in,
       input logic [DATA_WIDTH-1:0] IM_in,
        
       output logic [ADDR_WIDTH-1:0] PC4_out,
       output logic [REG_ADDR_WIDTH-1:0] Rd_addr_out,
       output logic [DATA_WIDTH-1:0] ALU_out,
       output logic [DATA_WIDTH-1:0] DM_out,
       output logic [DATA_WIDTH-1:0] IM_out
       );
       
   struct packed {
        logic [ADDR_WIDTH-1:0] PC4;
        logic [REG_ADDR_WIDTH-1:0] RD;
        logic [DATA_WIDTH-1:0] DM;
        logic [DATA_WIDTH-1:0] ALU;
        logic [DATA_WIDTH-1:0] IM;
        } MEM_WB;
   
   always_ff @ (posedge Clk) begin
        if (Rst || Flush) begin
            MEM_WB <= '0;
            end

        else begin
            MEM_WB.PC4   <= PC4_in;
            MEM_WB.RD    <= Rd_addr_in;
            MEM_WB.DM    <= DM_in;
            MEM_WB.ALU   <= ALU_in;
            MEM_WB.IM  <= IM_in;
            end
   end

assign PC4_out = MEM_WB.PC4; 
assign Rd_addr_out = MEM_WB.RD;             
assign DM_out = MEM_WB.DM;             
assign ALU_out = MEM_WB.ALU;             
assign IM_out = MEM_WB.IM;             
      
endmodule
