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
    /*ControlUnit*/
    output logic PCSrcD,
    output logic RegWriteD, MemtoRegD, MemWriteD, RegDstD, LinkD,
    output logic [1:0] ALUSrcD,
    output alu_t ALUControlD,
    /*Forward*/
    input word_t ALUOutM, ALUOutE,
    input logic [1:0] ForwardAD, ForwardBD
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
    regfile regfile_inst(.clk, .resetn,.ra1(rs), .ra2(rt), .wa3(WriteRegW), .wd3(ResultW), .write_enable(RegWriteW), .rd1, .rd2);
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

    /*ControlUnit*/
    ControlUnit ControlUnit_inst(.*);
    logic _unused_ok = &{'0, instr};
endmodule





