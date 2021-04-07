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
    input logic RegWriteD, MemtoRegD, MemWriteD, RegDstD, LinkD,
    input logic [1:0] ALUSrcD,
    input alu_t ALUControlD,
    output logic RegWriteE, MemtoRegE, MemWriteE,
    /*ALU*/
    output word_t ALUOutE,
    /*Forward*/
    input word_t ALUOutM,
    input word_t ResultW,
    input logic [1:0] ForwardAE, ForwardBE
);
    regidx_t RdE;
    word_t RsDE, RtDE;
    word_t SignImmE;
    logic [1:0] ALUSrcE;
    logic RegDstE, LinkE;
    alu_t ALUControlE;
    Ein Ein_inst(.*);
    /*WriteRegE*/
    always_comb begin
        WriteRegE=RegDstE ? RdE : (LinkE ? 5'b11111 : RtE);
    end
    /*SrcA, WriteDataE, SrcB*/
    word_t SrcA, SrcB;
    always_comb begin
        if(ALUSrcE[0]) SrcA=SignImmE;
        else begin
            unique case(ForwardAE)
                2'b01: SrcA=ResultW;
                2'b10: SrcA=ALUOutM;
                default: SrcA=RsDE;
            endcase
        end
        unique case(ForwardBE)
            2'b01: WriteDataE=ResultW;
            2'b10: WriteDataE=ALUOutM;
            default: WriteDataE=RtDE;
        endcase
        SrcB=ALUSrcE[1] ? SignImmE : WriteDataE;
    end
    word_t ALUResult;
    alu alu_inst(.*);
    always_comb begin
        ALUOutE=LinkE ? PCE+32'b1000 : ALUResult;
    end
endmodule



