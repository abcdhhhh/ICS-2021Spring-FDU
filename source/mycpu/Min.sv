`include"common.svh"
`include"mycpu/type.svh"

module Min(
    input logic clk,resetn, StallM, FlushM,
    input addr_t PCE,
    input logic RegWriteE, MemtoRegE, MemWriteE,
    input msize_t SizeE,
    input logic SignedE,
    input word_t ALUOutE, WriteDataE,
    input regidx_t WriteRegE,
    input regidx_t RtE,
    output addr_t PCM,
    output logic RegWriteM, MemtoRegM, MemWriteM,
    output msize_t SizeM,
    output logic SignedM,
    output word_t ALUOutM, WriteDataM,
    output regidx_t WriteRegM,
    output regidx_t RtM
);
    always_ff @(posedge clk) begin
        if(~resetn|FlushM) begin
            PCM<=32'hbfc00000;
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