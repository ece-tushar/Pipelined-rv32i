// Dropping support for LUI/AUIPC. 
// Jalr doesn't mask the last bit. 

// simplify the control units for each stage later, old code reused right now. 

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
    
    wire [PC_DATA_WIDTH-1:0] MEM_PC_PCnext; // Out of EX_MEM 
    wire [DATA_WIDTH-1:0] MEM_IM_Instr;
    wire [DATA_WIDTH-1:0] MEM_ALU_DataOut;
    wire [DATA_WIDTH-1:0] MEM_RB_DataOut2;
    
    wire [PC_DATA_WIDTH-1:0] WB_PC_PCnext; // Out of MEM_WB 
    wire [DATA_WIDTH-1:0] WB_SE_DataOut;
    wire [DATA_WIDTH-1:0] WB_ALU_DataOut;
    wire [DATA_WIDTH-1:0] WB_IM_Instr;




struct packed {
    struct packed {
        logic [1:0] SelOprd1;
        logic [1:0] SelOprd2;
        logic [3:0] ALUSelFunc;
        logic       SelAdderPC;
        logic       SelDataInPC;
    } EX_out;

    struct packed {
        logic       DataMemWEn;
        logic [1:0] DataMemWDataType;
        logic [1:0] DataMemRDataType;
        logic       SignExtd;
    } MEM_out;

    struct packed {
        logic       RegBankWEn;
        logic [1:0] SelRegBankDataIn;
    } WB_out;

    struct packed {
        logic [6:0] ImmInstrType;
    } ID_out;
} Ctrl;


    wire IF_ID_Flush;
    wire ID_EX_Flush;
    wire EX_MEM_Flush;
    wire MEM_WB_Flush;
    
    wire StallReq;  // pipeline controller
    wire PC_WEn;
    wire IF_ID_WEn;
    
    wire StrFwd;
    
    wire [DATA_WIDTH-1:0] ALU_DataOut;

    wire [DATA_WIDTH-1:0] RB_DataOut1;
    wire [DATA_WIDTH-1:0] RB_DataOut2;

    wire [DATA_WIDTH-1:0] IG_ImmOut;

    wire [DATA_WIDTH-1:0] MUX_ALU_DataOut2;
    wire [DATA_WIDTH-1:0] MUX_ALU_DataOut1;

    wire [DATA_WIDTH-1:0] DM_DataIn;
    wire [DATA_WIDTH-1:0] DM_DataOut;

    wire [DATA_WIDTH-1:0] SE_DataOut;

    wire [DATA_WIDTH-1:0] MUX_RB_DataOut;
 
 
 //----------PIPELINE CONTROLLER---------------
 
 PipelineControl PCtrl (
        .StallReq(StallReq),
        .PC_WEn(PC_WEn),
        .IF_ID_WEn(IF_ID_WEn),
        .ID_EX_Flush(ID_EX_Flush)
    );   
    
    
//============================================================
// I N S T R U C T I O N     F E T C H
//============================================================


     PCBlock PC (.SelAdderPC(Ctrl.EX_out.SelAdderPC),
                 .SelDataInPC(Ctrl.EX_out.SelDataInPC),
                 .Clk(Clk),
                 .Rst(Rst),.PC_WEn(PC_WEn), 
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
                        .WEn(IF_ID_WEn),
                    
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
                 .ImmInstrType(Ctrl.ID_out.ImmInstrType),
                 .ImmOut(IG_ImmOut)
                 );
 
     LoadHazardUnit LHU (
                     .EX_IM_Instr(EX_IM_Instr),
                     .ID_IM_Instr(ID_IM_Instr),
                     .StallReq(StallReq)
                 );
                 
     ControlUnit CUID (
                     .InstrCodes({
                         ID_IM_Instr[31:25],   // funct7
                         ID_IM_Instr[14:12],   // funct3
                         ID_IM_Instr[6:0]      // opcode
                     }),
                 
                     .ALUOutLSB(ALU_DataOut[0]),
                     // ID
                     .ImmInstrType(Ctrl.ID_out.ImmInstrType),
                     // EX
                     .SelAdderPC(),
                     .SelDataInPC(),
                     .SelMuxALU(),
                     .SelMuxALU0(),
                     .ALUSelFunc(),
                     // MEM
                     .SignExtd(),
                     .DataMemWEn(),
                     .DataMemRDataType(),
                     .DataMemWDataType(),
                     // WB
                     .RegBankWEn(),
                     .SelRegBankDataIn()
                 );

     RegBank32 RB (.DataIn(MUX_RB_DataOut),
                   .Clk(Clk),
                   .Rst(Rst), 
                   .WEn(Ctrl.WB_out.RegBankWEn),
                   .RAddr1(ID_IM_Instr[19:15]),
                   .RAddr2(ID_IM_Instr[24:20]),
                   .WAddr(WB_IM_Instr[11:7]),
                   .DataOut1(RB_DataOut1),
                   .DataOut2(RB_DataOut2));
                

    pipe_ID_EX ID_EX (
        .Clk(Clk),
        .Rst(Rst),
        .Flush(ID_EX_Flush),

        .PC4_in(ID_PC_PCnext),
        .Rs1_in(RB_DataOut1),
        .Rs2_in(RB_DataOut2),
        .Imm_in(IG_ImmOut),
        .IM_in(ID_IM_Instr),

        .PC4_out(EX_PC_PCnext),
        .Rs1_out(EX_RB_DataOut1),
        .Rs2_out(EX_RB_DataOut2),
        .Imm_out(EX_IG_ImmOut),
        .IM_out(EX_IM_Instr)
);


//==================================================
// E X E C U T E 
//==================================================

//     mux2to1 # (.DATA_WIDTH(32)) 
//    MUX_ALU0 (.DataIn0(EX_RB_DataOut1),
//           .DataIn1({{(DATA_WIDTH-PC_DATA_WIDTH){1'b0}},ID_PC_RAddr}),  // PC isn't pipelined so dropped LUI / AUIPC
//           .Sel(Ctrl.EX_out.SelMuxALU0),
//           .DataOut(MUX_ALU_DataOut0));
   
       mux4to1 #(.DATA_WIDTH(32)) 
       MUX_ALU1 (.DataIn0(EX_RB_DataOut1),
               .DataIn1({{(DATA_WIDTH-PC_DATA_WIDTH){1'b0}},ID_PC_RAddr}),
               .DataIn2(MEM_ALU_DataOut),
               .DataIn3(MUX_RB_DataOut),
               .Sel(Ctrl.EX_out.SelOprd1),
               .DataOut(MUX_ALU_DataOut1));

       mux4to1 #(.DATA_WIDTH(32)) 
       MUX_ALU2 (.DataIn0(EX_RB_DataOut2),
               .DataIn1(EX_IG_ImmOut),
               .DataIn2(MEM_ALU_DataOut),
               .DataIn3(MUX_RB_DataOut),
               .Sel(Ctrl.EX_out.SelOprd2),
               .DataOut(MUX_ALU_DataOut2));                      

    
    
//    mux2to1 # (.DATA_WIDTH(32)) 
//           MUX_ALU (.DataIn0(EX_RB_DataOut2),
//                  .DataIn1(EX_IG_ImmOut),
//                  .Sel(Ctrl.EX_out.SelMuxALU),
//                  .DataOut(MUX_ALU_DataOut2));


     ALU ALU_UUT (.DataIn1(MUX_ALU_DataOut1),
                  .DataIn2(MUX_ALU_DataOut2),
                  .SelFunc(Ctrl.EX_out.ALUSelFunc),
                  .DataOut(ALU_DataOut));
                  
     ControlUnit CUEX (
                        .InstrCodes({
                            EX_IM_Instr[31:25],   // funct7
                            EX_IM_Instr[14:12],   // funct3
                            EX_IM_Instr[6:0]      // opcode
                                  }),
                              
                        .ALUOutLSB(ALU_DataOut[0]),
                        // ID
                        .ImmInstrType(),
                        // EX
                        .SelAdderPC(Ctrl.EX_out.SelAdderPC),
                        .SelDataInPC(Ctrl.EX_out.SelDataInPC),
                        .SelMuxALU(),
                        .SelMuxALU0(),
                        .ALUSelFunc(Ctrl.EX_out.ALUSelFunc),
                        // MEM
                        .SignExtd(),
                        .DataMemWEn(),
                        .DataMemRDataType(),
                        .DataMemWDataType(),
                        // WB
                        .RegBankWEn(),
                        .SelRegBankDataIn()
                              );
                              
            ForwardingUnit FU (
                         .EX_IM_Instr (EX_IM_Instr),
                         .MEM_IM_Instr(MEM_IM_Instr),
                         .WB_IM_Instr (WB_IM_Instr),
                              
                         .SelOprd1(Ctrl.EX_out.SelOprd1),
                         .SelOprd2(Ctrl.EX_out.SelOprd2)
                              );

pipe_EX_MEM EX_MEM (
                      .Clk(Clk),
                      .Rst(Rst),
                      .Flush(1'b0),
                  
                      .PC4_in(EX_PC_PCnext),
                      .Rs2_in(EX_RB_DataOut2),
                      .ALU_in(ALU_DataOut),
                      .IM_in(EX_IM_Instr),
                  
                      .PC4_out(MEM_PC_PCnext),
                      .Rs2_out(MEM_RB_DataOut2),
                      .ALU_out(MEM_ALU_DataOut),
                      .IM_out(MEM_IM_Instr)
                  );
    
//==================================================
// M E M O R Y    A C C E S S  
//==================================================      
      StoreForwardUnit SFU (
               .MEM_IM_Instr(MEM_IM_Instr),
               .WB_IM_Instr(WB_IM_Instr),
               .StrFwd(StrFwd)
                         );
                         
      mux2to1 # (.DATA_WIDTH(32)) 
            MUX_DM (.DataIn0(MEM_RB_DataOut2),
                    .DataIn1(MUX_RB_DataOut),
                    .Sel(StrFwd),
                    .DataOut(DM_DataIn));   
           
     ByteAdrRAM DM (.DataIn(DM_DataIn),  
               .Clk(Clk),
               .WEn(Ctrl.MEM_out.DataMemWEn),
               .WDataType(Ctrl.MEM_out.DataMemWDataType),
               .RDataType(Ctrl.MEM_out.DataMemRDataType),
               .WAddr(MEM_ALU_DataOut[7:0]),
               .RAddr(MEM_ALU_DataOut[7:0]),
               .DataOut(DM_DataOut));


         SignExtender SE (.DataIn(DM_DataOut),
                   .DataType(Ctrl.MEM_out.DataMemRDataType),
                   .SignExtd(Ctrl.MEM_out.SignExtd),
                   .DataOut(SE_DataOut)); 

     ControlUnit CUMEM (
                     .InstrCodes({
                         MEM_IM_Instr[31:25],   // funct7
                         MEM_IM_Instr[14:12],   // funct3
                         MEM_IM_Instr[6:0]      // opcode
                     }),
                 
                     .ALUOutLSB(ALU_DataOut[0]),
                     // ID
                     .ImmInstrType(),
                     // EX
                     .SelAdderPC(),
                     .SelDataInPC(),
                     .SelMuxALU(),
                     .SelMuxALU0(),
                     .ALUSelFunc(),
                      // MEM
                     .SignExtd(Ctrl.MEM_out.SignExtd),
                     .DataMemWEn(Ctrl.MEM_out.DataMemWEn),
                     .DataMemRDataType(Ctrl.MEM_out.DataMemRDataType),
                     .DataMemWDataType(Ctrl.MEM_out.DataMemWDataType),
                     // WB
                     .RegBankWEn(),
                     .SelRegBankDataIn()
                 );


        pipe_MEM_WB MEM_WB (
                .Clk(Clk),
                .Rst(Rst),
                .Flush(1'b0),

                .PC4_in(MEM_PC_PCnext),
                .ALU_in(MEM_ALU_DataOut),
                .DM_in(SE_DataOut),
                .IM_in(MEM_IM_Instr),

                .PC4_out(WB_PC_PCnext),
                .ALU_out(WB_ALU_DataOut),
                .DM_out(WB_SE_DataOut),
                .IM_out(WB_IM_Instr)
               );
               
//==================================================
// W R I T E   B A C K
//==================================================

     ControlUnit CUWB (
                 .InstrCodes({
                    WB_IM_Instr[31:25],   // funct7
                    WB_IM_Instr[14:12],   // funct3
                    WB_IM_Instr[6:0]      // opcode
                  }),
                 
                 .ALUOutLSB(ALU_DataOut[0]),
                 // ID
                 .ImmInstrType(),
                     // EX
                     .SelAdderPC(),
                     .SelDataInPC(),
                     .SelMuxALU(),
                     .SelMuxALU0(),
                     .ALUSelFunc(),
                      // MEM
                     .SignExtd(),
                     .DataMemWEn(),
                     .DataMemRDataType(),
                     .DataMemWDataType(),
                     // WB
                     .RegBankWEn(Ctrl.WB_out.RegBankWEn),
                     .SelRegBankDataIn(Ctrl.WB_out.SelRegBankDataIn)
                 );

    
    
          
    mux4to1 #(.DATA_WIDTH(32)) 
            MUX_RB (.DataIn0(WB_ALU_DataOut),
                     .DataIn1(WB_SE_DataOut),
                     .DataIn2({{(DATA_WIDTH-PC_DATA_WIDTH){1'b0}}, WB_PC_PCnext}),
                     .DataIn3(EX_IG_ImmOut),
                     .Sel(Ctrl.WB_out.SelRegBankDataIn),
                     .DataOut(MUX_RB_DataOut));
                

      assign DataOut = MUX_RB_DataOut; // to generate RTL schematic
    
endmodule


