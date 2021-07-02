`include"mycpu/defs.svh"

module memory(
    input logic clk,resetn,StallM, FlushM,
    /*PC*/
    input addr_t PCE, 
    output addr_t PCM,
    /*Data*/
    output word_t DataM,
    /*Rt*/
    input regidx_t RtE,
    output regidx_t RtM,
    /*ALUOut*/
    input word_t ALUOutE,
    output word_t ALUOutM,
    /*WriteData*/
    input word_t WriteDataE,
    /*WriteReg*/
    input regidx_t WriteRegE,
    output regidx_t WriteRegM, 
    /*d_valid*/
    output logic d_validM,

    //signals
    input logic RegWriteE, MemtoRegE, MemWriteE,
    output logic RegWriteM, MemtoRegM, MemWriteM,
    input msize_t SizeE,
    output msize_t SizeM,
    input logic SignedE, 
    output logic SignedM,

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

