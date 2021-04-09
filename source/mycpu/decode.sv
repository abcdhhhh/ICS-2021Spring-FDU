`include"common.svh"
`include"mycpu/type.svh"

module decode(
    input logic clk,resetn,StallD,FlushD,
    /*resp*/
    input ibus_resp_t iresp,
    /*PC*/
    input addr_t PCF, PCPlus4F,
    output addr_t PCD, PCBranchD,
    /*imm*/
    output word_t SignImmD,
    /*reg*/
    output regidx_t RsD, RtD, RdD,
    output word_t RsDD, RtDD,
    input regidx_t WriteRegW,
    input logic RegWriteW,
    input word_t ResultW,
    /*signals*/
    output logic PCSrcD,
    output logic RegWriteD, MemtoRegD, MemWriteD, RegDstD, LinkD, RetD,
    output logic HiWriteD, LoWriteD,
    output logic [1:0] ALUSrcAD,
    output logic ALUSrcBD,
    output alu_t ALUControlD,
    output mult_t MULTControlD,
    output msize_t SizeD,
    output logic SignedD,
    /*Forward*/
    input word_t ALUOutM, ALUOutE,
    input logic [1:0] ForwardAD, ForwardBD,
    /*hilo*/
    input logic HiWriteE, LoWriteE,
    input i32 HiDataE, LoDataE,
    output i32 HiD, LoD
);
    /*fetch instr*/
    ibus_resp_t instr;
    /*PC*/
    addr_t PCPlus4D;
    Din D_inst(.*);
    /*instr structure*/
    regidx_t rs, rt, rd;
    /*regfile*/
    word_t rd1, rd2;
    regfile regfile_inst(.clk, .resetn, .ra1(rs), .ra2(rt), .wa3(WriteRegW), .wd3(ResultW), .write_enable(RegWriteW), .rd1, .rd2);
    assign RsD=rs;
    assign RtD=rt;
    assign RdD=rd;
    /*Compare*/
    always_comb begin
        unique case(ForwardAD)
            2'b01: RsDD=ResultW;
            2'b10: RsDD=ALUOutM;
            2'b11: RsDD=ALUOutE;
            default: RsDD=rd1;
        endcase
        unique case(ForwardBD)
            2'b01: RtDD=ResultW;
            2'b10: RtDD=ALUOutM;
            2'b11: RtDD=ALUOutE;
            default: RtDD=rd2;
        endcase
    end  
    /*hilo*/
    i32 hi, lo;
    hilo hilo_inst(.clk, .hi, .lo, .hi_write(HiWriteE), .lo_write(LoWriteE), .hi_data(HiDataE), .lo_data(LoDataE));
    assign HiD=HiWriteD ? HiDataE : hi;
    assign LoD=LoWriteD ? LoDataE : lo;
    /*ControlUnit*/
    ControlUnit ControlUnit_inst(.*);
    logic _unused_ok = &{'0, instr};
endmodule





