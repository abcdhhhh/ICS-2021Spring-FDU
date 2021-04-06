`include"common.svh"
`include"mycpu/type.svh"

module memory(
    input logic clk,resetn,StallM, FlushM,
    /*PC*/
    input addr_t PCE, 
    output addr_t PCM,
    /*req*/
    output word_t DataM,
    /*reg*/
    input regidx_t RtE,
    output regidx_t RtM,
    /*Write*/
    input word_t WriteDataE,
    input regidx_t WriteRegE,
    output regidx_t WriteRegM,
    /*ALU*/
    input word_t ALUOutE,
    output word_t ALUOutM,
    /*ControlUnit*/
    input logic RegWriteE, MemtoRegE, MemWriteE,
    output logic RegWriteM, MemtoRegM, MemWriteM,
    output logic d_validM,
    /*Forward*/
    input logic ForwardM,
    input word_t ResultW
);
    word_t WriteDataM;
    Min Min_inst(.*);
    /*Forward for WriteData*/
    always_comb begin
        DataM=ForwardM ? ResultW : WriteDataM;
    end
    assign d_validM=MemtoRegM|MemWriteM;
endmodule

