`include"common.svh"
`include"mycpu/type.svh"

module Ein(
    input logic clk,resetn, StallE, FlushE,
    input addr_t PCD,
    input word_t SignImmD,
    input logic RegWriteD, MemtoRegD, MemWriteD, RegDstD, LinkD, RetD,
    input logic [1:0] ALUSrcD,
    input alu_t ALUControlD,
    input msize_t SizeD,
    input logic SignedD,
    input regidx_t RsD, RtD, RdD,
    input word_t RsDD, RtDD,
    
    output addr_t PCE,
    output word_t SignImmE,
    output logic RegWriteE, MemtoRegE, MemWriteE, RegDstE, LinkE, RetE,
    output logic [1:0] ALUSrcE,
    output alu_t ALUControlE,
    output msize_t SizeE,
    output logic SignedE,
    output regidx_t RsE, RtE, RdE,
    output word_t RsDE, RtDE
);
    
    always_ff @(posedge clk) begin
        if(~resetn|FlushE) begin
            PCE<=32'hbfc00000;
            SignImmE<='0;
            RegWriteE<='0;
            MemtoRegE<='0;
            MemWriteE<='0;
            ALUSrcE<='0;
            RegDstE<='0;
            LinkE<='0;
            RetE<='0;
            ALUControlE<=ALU_ADDU;
            SizeE<=MSIZE4;
            SignedE<='0;
            RsE<='0;
            RtE<='0;
            RdE<='0;
            RsDE<='0;
            RtDE<='0;
        end
        else if(~StallE) begin
            PCE<=PCD;
            SignImmE<=SignImmD;
            RegWriteE<=RegWriteD;
            MemtoRegE<=MemtoRegD;
            MemWriteE<=MemWriteD;
            ALUSrcE<=ALUSrcD;
            RegDstE<=RegDstD;
            LinkE<=LinkD;
            RetE<=RetD;
            ALUControlE<=ALUControlD;
            SizeE<=SizeD;
            SignedE<=SignedD;
            RsE<=RsD;
            RtE<=RtD;
            RdE<=RdD;
            RsDE<=RsDD;
            RtDE<=RtDD;
        end
    end
endmodule