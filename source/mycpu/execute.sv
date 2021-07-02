`include"mycpu/defs.svh"

module execute(
    input logic clk,resetn, StallE, FlushE,
    /*PC*/
    input addr_t PCD,
    output addr_t PCE,
    /*BD*/
    input logic BDD,
    output logic BDE,
    /*SignImm*/
    input word_t SignImmD,

    //regfile
    input regidx_t RsD, RtD, RdD,
    output regidx_t RsE, RtE, RdE,
    input word_t RsDD, RtDD,
    output word_t RtDE,

    /*WriteReg*/
    output regidx_t WriteRegE,
    /*WriteData*/
    output word_t WriteDataE,

    //ControlUnit
    input logic RegWriteD, MemtoRegD, MemWriteD, RegDstD, 
    output logic RegWriteE, MemtoRegE, MemWriteE,
    input logic LinkD, RetD,
    input logic [1:0] ALUSrcAD, ALUSrcBD,
    input alu_t ALUControlD,
    input mult_t MULTControlD,
    input msize_t SizeD,
    output msize_t SizeE,
    input logic SignedD,
    output logic SignedE,
    //ALU
    output word_t ALUOutE,
    //MULT
    output i32 HiDataE, LoDataE,
    output logic done,

    /*Forward*/
    input word_t ALUOutM,
    input word_t ResultW,
    input logic [1:0] ForwardAE, ForwardBE,

    //hilo
    input i32 HiD, LoD,
    input logic HiWriteD, LoWriteD,
    output logic HiWriteE, LoWriteE,

    /*Eret*/
    input logic EretD,
    output logic EretE,

    //cp0
    input logic CP0WriteD,
    output logic CP0WriteE,
    output addr_t BadVAddrE,
    input word_t CP0DD,

    //exceptions
    input i8 interrupt_info,
    input i8 EVectorD,
    output logic exception_enable,
    output ecode_t ecode,
    output logic ex_or_eret
);
    word_t RsDE;
    word_t SignImmE;
    logic [1:0] ALUSrcAE, ALUSrcBE;
    logic RegDstE, LinkE, RetE;
    alu_t ALUControlE;
    mult_t MULTControlE;
    i32 HiE, LoE;
    /*WriteRegE*/
    always_comb begin
        WriteRegE=RegDstE ? RdE : (RetE ? 5'b11111 : RtE);
    end
    /*SrcA, WriteData, SrcB*/
    word_t CP0DE;
    word_t SrcA, SrcB;
    always_comb begin
        unique case(ALUSrcAE)
            /*Rs*/
            2'b00: begin
                unique case(ForwardAE)
                    2'b01: SrcA=ResultW;
                    2'b10: SrcA=ALUOutM;
                    default: SrcA=RsDE;
                endcase
            end
            /*SignImm*/
            2'b01: SrcA=SignImmE;
            /*Hi*/
            2'b10: SrcA=HiE;
            /*Lo*/
            2'b11: SrcA=LoE;
            default: SrcA=SignImmE;
        endcase
        unique case(ForwardBE)
            2'b01: WriteDataE=ResultW;
            2'b10: WriteDataE=ALUOutM;
            default: WriteDataE=RtDE;
        endcase
        unique case(ALUSrcBE)
            /*WriteData(RtD)*/
            2'b00: SrcB = WriteDataE;
            /*CP0D*/
            2'b01: SrcB = CP0DE;
            /*SignImm*/
            2'b10: SrcB = SignImmE;
            default: SrcB = WriteDataE;
        endcase
    end
    word_t ALUResult;
    i32 hi, lo;
    /*hilo*/
    assign HiDataE=(MULTControlE==CLR) ? RsDE : hi;
    assign LoDataE=(MULTControlE==CLR) ? RsDE : lo;
    always_comb begin
        ALUOutE=LinkE ? PCE+32'b1000 : ALUResult;
    end
    //exception
    logic ALUOverflow, ADELD, ADESD;
    i8 EVectorEin, EVectorE;
    /*ADELD*/
    always_comb begin
        ADELD='0;
        if(MemtoRegE) begin
            unique case(SizeE)
                MSIZE1: ;
                MSIZE2: ADELD = ALUOutE[0];
                MSIZE4: ADELD = |{ALUOutE[1:0]};
                default: ADELD = |{ALUOutE[1:0]};
            endcase
        end
    end
    /*ADESD*/
    always_comb begin
        ADESD='0;
        if(MemWriteE) begin
            unique case(SizeE)
                MSIZE1: ;
                MSIZE2: ADESD = ALUOutE[0];
                MSIZE4: ADESD = |{ALUOutE[1:0]};
                default: ADESD = |{ALUOutE[1:0]};
            endcase
        end
    end
    /*BadVAddr*/
    always_comb begin
        BadVAddrE = PCE;
        if(ADELD|ADESD) begin
            BadVAddrE = ALUOutE;
        end
    end
    //EVector
    always_comb begin
        EVectorE = EVectorEin;
        if(interrupt_info != 8'b0) EVectorE[0] = '1;
        if(ALUOverflow) EVectorE[5] = '1;
        if(ADELD) EVectorE[6] = '1;
        if(ADESD) EVectorE[7] = '1;
    end
    // exception_enable
    assign exception_enable = (|{EVectorE}) & (|{PCE});
    assign ex_or_eret = exception_enable | EretE;
    //ecode
    always_comb begin
        priority case(1'b1)
            EVectorE[0] : ecode = EX_INT;
            EVectorE[1] : ecode = EX_ADEL;
            EVectorE[2] : ecode = EX_SYS;
            EVectorE[3] : ecode = EX_BP;
            EVectorE[4] : ecode = EX_RI;
            EVectorE[5] : ecode = EX_OV;
            EVectorE[6] : ecode = EX_ADEL;
            EVectorE[7] : ecode = EX_ADES;
            default : ecode = EX_INT;
        endcase
    end
    Ein Ein_inst(.*);
    alu alu_inst(.*);
    mult mult_inst(.*);
endmodule



