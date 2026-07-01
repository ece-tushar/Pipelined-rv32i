// Dropping support for LUI/AUIPC. 
// Jalr doesn't mask the last bit. 

module DataPath #(
    parameter DATA_WIDTH=32,
    parameter PC_DATA_WIDTH=8,
    parameter BYTE = 2'b00,
    parameter HALF_WORD = 2'b01,
    parameter WORD = 2'b10,
    parameter FUNC_WIDTH = 17
    )(
    input Clk, Rst,
    output [DATA_WIDTH-1:0] DataOut
    );
    wire [PC_DATA_WIDTH-1:0] PC_RAddr;  // Into IF_ID
    wire [PC_DATA_WIDTH-1:0] PC_PCnext;
    wire [DATA_WIDTH-1:0] IM_Instr; // the entire instruction
    
    wire [PC_DATA_WIDTH-1:0] ID_PC_RAddr;  // Out of IF_ID
    wire [PC_DATA_WIDTH-1:0] ID_PC_PCnext;
    wire [DATA_WIDTH-1:0] ID_IM_Instr;
    wire [FUNC_WIDTH-1:0] ID_ControlKey;

    wire [PC_DATA_WIDTH-1:0] EX_PC_PCnext; // Out of ID_EX 
    wire [DATA_WIDTH-1:0] EX_IM_Instr;
    wire [DATA_WIDTH-1:0] EX_RB_DataOut1;
    wire [DATA_WIDTH-1:0] EX_RB_DataOut2;
    wire [DATA_WIDTH-1:0] EX_IG_ImmOut;

struct packed {
    logic       SelAdderPC;
    logic       SelDataInPC;
    logic       RegBankWEn;
    logic       DataMemWEn;
    logic       SelMuxALU;
    logic       SelMuxALU0;
    logic       SignExtd;
    logic [6:0] ImmInstrType;
    logic [3:0] ALUSelFunc;
    logic [1:0] DataMemRDataType;
    logic [1:0] DataMemWDataType;
    logic [1:0] SelRegBankDataIn;
} Ctrl_ID;

struct packed {
    struct packed {
        logic       SelMuxALU;
        logic       SelMuxALU0;
        logic [3:0] ALUSelFunc;
        logic       SelAdderPC;
        logic       SelDataInPC;
    } EX_in, EX_out;

    struct packed {
        logic       DataMemWEn;
        logic [1:0] DataMemWDataType;
        logic [1:0] DataMemRDataType;
        logic       SignExtd;
    } MEM_in, MEM_out;

    struct packed {
        logic       RegBankWEn;
        logic [1:0] SelRegBankDataIn;
    } WB_in, WB_out;

    struct packed {
        logic [6:0] ImmInstrType;
    } ID;
} Ctrl;

    wire [DATA_WIDTH-1:0] ALU_DataOut;

    wire [DATA_WIDTH-1:0] RB_DataOut1;
    wire [DATA_WIDTH-1:0] RB_DataOut2;

    wire [DATA_WIDTH-1:0] IG_ImmOut;

    wire [DATA_WIDTH-1:0] MUX_ALU_DataOut;
    wire [DATA_WIDTH-1:0] MUX_ALU_DataOut0;

    wire [DATA_WIDTH-1:0] DM_DataOut;

    wire [DATA_WIDTH-1:0] SE_DataOut;

    wire [DATA_WIDTH-1:0] MUX_RB_DataOut;
    
    
    
//============================================================
// I N S T R U C T I O N     F E T C H
//============================================================


     PCBlock PC (.SelAdderPC(Ctrl.EX_out.SelAdderPC),
                 .SelDataInPC(Ctrl.EX_out.SelDataInPC),
                 .Clk(Clk),
                 .Rst(Rst), 
                 .Immediate(EX_IG_ImmOut[7:0]),   
                 .PCnext(PC_PCnext),
                 .MainALUData(ALU_DataOut[7:0]),
                 .AddrOutPC(PC_RAddr));
    
     ByteAdrRAM IM (.DataIn(),  // loading from a .mem file so no need
                    .Clk(Clk),
                    .WEn(0),
                    .WDataType(),
                    .RDataType(WORD),
                    .WAddr(),
                    .RAddr(PC_RAddr),
                    .DataOut(IM_Instr));
     
     // IF_ID register
     pipe_IF_ID IF_ID (
                        .Clk    (Clk),
                        .Rst    (Rst),
                        .Flush  (1'b0),
                    
                        .PC_in  (PC_RAddr),    
                        .PC4_in (PC_PCnext),
                        .IM_in  (IM_Instr),
                    
                        .PC_out (ID_PC_RAddr),
                        .PC4_out(ID_PC_PCnext),
                        .IM_out (ID_IM_Instr)
                    );

//============================================================
// I N S T R U C T I O N     D E C O D E
//============================================================
     
     ImmGen       IG (.ImmIn(ID_IM_Instr[31:7]),
                 .ImmInstrType(Ctrl.ID.ImmInstrType),
                 .ImmOut(IG_ImmOut)
                 );
 
     InstrDecoder ID (.InstrCodes({ID_IM_Instr[31:25], //F7|F3|OP
                              ID_IM_Instr[14:12],
                              ID_IM_Instr[6:0]}),
                 .ControlKey(ID_ControlKey));   
     

                        
     Controller CTRL (.ControlKey(ID_ControlKey),

            .ImmInstrType(Ctrl.ID.ImmInstrType), // Consumed in ID

            .ALUOutLSB(ALU_DataOut[0]),
            .SelAdderPC(Ctrl.EX_in.SelAdderPC),
            .SelDataInPC(Ctrl.EX_in.SelDataInPC),
            .RegBankWEn(Ctrl.WB_in.RegBankWEn),
            .SelMuxALU(Ctrl.EX_in.SelMuxALU),
            .SelMuxALU0(Ctrl.EX_in.SelMuxALU0),
            .SignExtd(Ctrl.MEM_in.SignExtd), 
            .SelRegBankDataIn(Ctrl.WB_in.SelRegBankDataIn),
            .DataMemWEn(Ctrl.MEM_in.DataMemWEn),
            .DataMemRDataType(Ctrl.MEM_in.DataMemRDataType),
            .DataMemWDataType(Ctrl.MEM_in.DataMemWDataType),
            .ALUSelFunc(Ctrl.EX_in.ALUSelFunc));         

     RegBank32 RB (.DataIn(MUX_RB_DataOut),
                   .Clk(Clk),
                   .Rst(Rst), // i will preload data using .mem file so don't need this
                   .WEn(Ctrl.WB_out.RegBankWEn),
                   .RAddr1(ID_IM_Instr[19:15]),
                   .RAddr2(ID_IM_Instr[24:20]),
                   .WAddr(EX_IM_Instr[11:7]),
                   .DataOut1(RB_DataOut1),
                   .DataOut2(RB_DataOut2));
                

    pipe_ID_EX ID_EX (
        .Clk(Clk),
        .Rst(Rst),
        .Flush(1'b0),

        .PC4_in(ID_PC_PCnext),
        .Rd_addr_in(ID_IM_Instr[11:7]),
        .Rs1_in(RB_DataOut1),
        .Rs2_in(RB_DataOut2),
        .Imm_in(IG_ImmOut),
        .Ctrl_in({Ctrl.EX_in,Ctrl.MEM_in,Ctrl.WB_in}),

        .PC4_out(EX_PC_PCnext),
        .Rd_addr_out(EX_IM_Instr[11:7]),
        .Rs1_out(EX_RB_DataOut1),
        .Rs2_out(EX_RB_DataOut2),
        .Imm_out(EX_IG_ImmOut),
        .Ctrl_out({Ctrl.EX_out,Ctrl.MEM_out,Ctrl.WB_out})
);


//==================================================
// E X E C U T E 
//==================================================

         SignExtender SE (.DataIn(DM_DataOut),
                   .DataType(Ctrl.MEM_out.DataMemRDataType),
                   .SignExtd(Ctrl.MEM_out.SignExtd),
                   .DataOut(SE_DataOut)); 


     ByteAdrRAM DM (.DataIn(EX_RB_DataOut2),  
               .Clk(Clk),
               .WEn(Ctrl.MEM_out.DataMemWEn),
               .WDataType(Ctrl.MEM_out.DataMemWDataType),
               .RDataType(Ctrl.MEM_out.DataMemRDataType),
               .WAddr(ALU_DataOut[7:0]),
               .RAddr(ALU_DataOut[7:0]),
               .DataOut(DM_DataOut));


     mux2to1 # (.DATA_WIDTH(32)) 
    MUX_ALU0 (.DataIn0(EX_RB_DataOut1),
           .DataIn1({{(DATA_WIDTH-PC_DATA_WIDTH){1'b0}},ID_PC_RAddr}),  // PC isn't pipelined so dropped LUI / AUIPC
           .Sel(Ctrl.EX_out.SelMuxALU0),
           .DataOut(MUX_ALU_DataOut0));
           
           
     mux2to1 # (.DATA_WIDTH(32)) 
    MUX_ALU (.DataIn0(EX_RB_DataOut2),
           .DataIn1(EX_IG_ImmOut),
           .Sel(Ctrl.EX_out.SelMuxALU),
           .DataOut(MUX_ALU_DataOut));
         
                      
     ALU ALU_UUT (.DataIn1(MUX_ALU_DataOut0),
                  .DataIn2(MUX_ALU_DataOut),
                  .SelFunc(Ctrl.EX_out.ALUSelFunc),
                  .DataOut(ALU_DataOut));
      
                 
    mux4to1 #(.DATA_WIDTH(32)) 
            MUX_RB (.DataIn0(ALU_DataOut),
                     .DataIn1(SE_DataOut),
                     .DataIn2({{(DATA_WIDTH-PC_DATA_WIDTH){1'b0}}, EX_PC_PCnext}),
                     .DataIn3(EX_IG_ImmOut),
                     .Sel(Ctrl.WB_out.SelRegBankDataIn),
                     .DataOut(MUX_RB_DataOut));
                

      assign DataOut = ALU_DataOut; // to generate RTL schematic
    
endmodule



