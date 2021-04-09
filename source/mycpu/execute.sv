`include"common.svh"
`include"mycpu/type.svh"

module execute(
    input logic clk,resetn, StallE, FlushE,
    /*PC*/
    input addr_t PCD,
    output addr_t PCE,
    /*imm*/
    input word_t SignImmD,
    /*reg*/
    input regidx_t RsD, RtD, RdD,
    output regidx_t RsE, RtE,
    input word_t RsDD, RtDD,
    /*Write*/
    output regidx_t WriteRegE,
    /*Memory*/
    output word_t WriteDataE,
    /*ControlUnit*/
    input logic RegWriteD, MemtoRegD, MemWriteD, RegDstD, LinkD, RetD,
    input logic [1:0] ALUSrcAD,
    input logic ALUSrcBD,
    input alu_t ALUControlD,
    input mult_t MULTControlD,
    input msize_t SizeD,
    input logic SignedD,
    output logic RegWriteE, MemtoRegE, MemWriteE,
    output msize_t SizeE,
    output logic SignedE,
    /*ALU*/
    output word_t ALUOutE,
    /*MULT*/
    output i32 HiDataE, LoDataE,
    /*Forward*/
    input word_t ALUOutM,
    input word_t ResultW,
    input logic [1:0] ForwardAE, ForwardBE,
    /*hilo*/
    input i32 HiD, LoD,
    input logic HiWriteD, LoWriteD,
    output logic HiWriteE, LoWriteE
);
    regidx_t RdE;
    word_t RsDE, RtDE;
    word_t SignImmE;
    logic [1:0] ALUSrcAE;
    logic ALUSrcBE;
    logic RegDstE, LinkE, RetE;
    alu_t ALUControlE;
    mult_t MULTControlE;
    i32 HiE, LoE;
    Ein Ein_inst(.*);
    /*WriteRegE*/
    always_comb begin
        WriteRegE=RegDstE ? RdE : (RetE ? 5'b11111 : RtE);
    end
    /*SrcA, WriteDataE, SrcB*/
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
        endcase
        unique case(ForwardBE)
            2'b01: WriteDataE=ResultW;
            2'b10: WriteDataE=ALUOutM;
            default: WriteDataE=RtDE;
        endcase
        SrcB=ALUSrcBE ? SignImmE : WriteDataE;
    end
    word_t ALUResult;
    alu alu_inst(.*);
    i32 hi, lo;
    mult mult_inst(.*);
    /*hilo*/
    assign HiDataE=(MULTControlE==CLR) ? RsDE : hi;
    assign LoDataE=(MULTControlE==CLR) ? RsDE : lo;
    always_comb begin
        ALUOutE=LinkE ? PCE+32'b1000 : ALUResult;
    end
endmodule



