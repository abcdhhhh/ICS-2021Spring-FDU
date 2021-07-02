`include"mycpu/defs.svh"

module Min(
    input logic clk,resetn, StallM, FlushM,
    /*PC*/
    input addr_t PCE,
    output addr_t PCM,
    //signals
    input logic RegWriteE, MemtoRegE, MemWriteE,
    output logic RegWriteM, MemtoRegM, MemWriteM,
    input msize_t SizeE,
    output msize_t SizeM,
    input logic SignedE,
    output logic SignedM,
    /*ALUOut, WriteData*/
    input word_t ALUOutE, WriteDataE,
    output word_t ALUOutM, WriteDataM,
    /*WriteReg*/
    input regidx_t WriteRegE,
    output regidx_t WriteRegM,
    /*Rt*/
    input regidx_t RtE,  
    output regidx_t RtM
);
    always_ff @(posedge clk) begin
        if(~resetn|FlushM) begin
            PCM<='0;
            RegWriteM<='0;
            MemtoRegM<='0;
            MemWriteM<='0;
            ALUOutM<='0;
            SizeM<=MSIZE4;
            SignedM<='0;
            WriteDataM<='0;
            WriteRegM<='0;
            RtM<='0;
        end
        else if(~StallM)begin
            PCM<=PCE;
            RegWriteM<=RegWriteE;
            MemtoRegM<=MemtoRegE;
            MemWriteM<=MemWriteE;
            ALUOutM<=ALUOutE;
            SizeM<=SizeE;
            SignedM<=SignedE;
            WriteDataM<=WriteDataE;
            WriteRegM<=WriteRegE;
            RtM<=RtE;
        end
    end
endmodule