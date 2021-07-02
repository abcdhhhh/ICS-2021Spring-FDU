`include"mycpu/defs.svh"

module Ein(
    input logic clk,resetn, StallE, FlushE,
    /*PC*/
    input addr_t PCD,
    output addr_t PCE,

    /*BD*/
    input logic BDD,
    output logic BDE,

    /*SignImm*/
    input word_t SignImmD,
    output word_t SignImmE,

    //signals
    input logic RegWriteD, MemtoRegD, MemWriteD, RegDstD,
    output logic RegWriteE, MemtoRegE, MemWriteE, RegDstE,
    input logic LinkD, RetD,
    output logic LinkE, RetE,
    input logic [1:0] ALUSrcAD, ALUSrcBD,
    output logic [1:0] ALUSrcAE, ALUSrcBE,
    input alu_t ALUControlD,
    output alu_t ALUControlE,
    input mult_t MULTControlD,
    output mult_t MULTControlE,
    input msize_t SizeD,
    output msize_t SizeE,
    input logic SignedD,
    output logic SignedE,

    //regfile
    input regidx_t RsD, RtD, RdD,
    output regidx_t RsE, RtE, RdE,
    input word_t RsDD, RtDD,
    output word_t RsDE, RtDE,

    //hilo
    input logic HiWriteD, LoWriteD,
    output logic HiWriteE, LoWriteE,
    input i32 HiD, LoD,
    output i32 HiE, LoE,

    /*Eret*/
    input logic EretD,
    output logic EretE,
    
    //cp0
    input logic CP0WriteD,
    output logic CP0WriteE,
    input word_t CP0DD,
    output word_t CP0DE,

    //exceptions
    input i8 EVectorD,
    output i8 EVectorEin
);
    
    always_ff @(posedge clk) begin
        if(~resetn|FlushE) begin
            PCE<='0;
            SignImmE<='0;
            RegWriteE<='0;
            MemtoRegE<='0;
            MemWriteE<='0;
            ALUSrcAE<='0;
            ALUSrcBE<='0;
            RegDstE<='0;
            LinkE<='0;
            RetE<='0;
            ALUControlE<=ALU_ADDU;
            MULTControlE<=CLR;
            SizeE<=MSIZE4;
            SignedE<='0;
            RsE<='0;
            RtE<='0;
            RdE<='0;
            RsDE<='0;
            RtDE<='0;
            HiWriteE<='0;
            LoWriteE<='0;
            HiE<='0;
            LoE<='0;
            BDE <= '0;
            EretE <= '0;
            CP0WriteE <= '0;
            CP0DE <= '0;
            EVectorEin <= '0;
        end
        else if(~StallE) begin
            PCE<=PCD;
            SignImmE<=SignImmD;
            RegWriteE<=RegWriteD;
            MemtoRegE<=MemtoRegD;
            MemWriteE<=MemWriteD;
            ALUSrcAE<=ALUSrcAD;
            ALUSrcBE<=ALUSrcBD;
            RegDstE<=RegDstD;
            LinkE<=LinkD;
            RetE<=RetD;
            ALUControlE<=ALUControlD;
            MULTControlE<=MULTControlD;
            SizeE<=SizeD;
            SignedE<=SignedD;
            RsE<=RsD;
            RtE<=RtD;
            RdE<=RdD;
            RsDE<=RsDD;
            RtDE<=RtDD;
            HiWriteE<=HiWriteD;
            LoWriteE<=LoWriteD;
            HiE<=HiD;
            LoE<=LoD;
            BDE <= BDD;
            EretE <= EretD;
            CP0WriteE <= CP0WriteD;
            CP0DE <= CP0DD;
            EVectorEin <= EVectorD;
        end
    end
endmodule