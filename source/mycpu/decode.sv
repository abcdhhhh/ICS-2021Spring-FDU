`include"mycpu/defs.svh"

module decode(
    input logic clk,resetn,StallD,FlushD,
    input ibus_resp_t iresp,
    /*PC*/
    input addr_t PCF, PCPlus4F,
    output addr_t PCD, PCBranchD,
    /*BD*/
    output logic BDD,
    /*SignImm*/
    output word_t SignImmD,

    //regfile
    /*Rs, Rt, Rd*/
    output regidx_t RsD, RtD, RdD,
    /*RsD, RtD*/
    output word_t RsDD, RtDD,
    /*Forward*/
    input regidx_t WriteRegW,
    input logic RegWriteW,
    input word_t ResultW,

    //ControlUnit
    output logic PCSrcD,
    output logic RegWriteD, MemtoRegD, MemWriteD, RegDstD,
    output logic LinkD, RetD,
    output logic HiWriteD, LoWriteD,
    output logic [1:0] ALUSrcAD, ALUSrcBD,
    output alu_t ALUControlD,
    output mult_t MULTControlD,
    output msize_t SizeD,
    output logic SignedD,

    /*Forward*/
    input word_t ALUOutE, ALUOutM,
    input logic [1:0] ForwardAD, ForwardBD,

    //hilo
    input logic HiWriteE, LoWriteE,
    input i32 HiDataE, LoDataE,
    output i32 HiD, LoD,

    //mult
    output logic willmult,

    /*Eret*/
    output logic EretD,
    //cp0
    //CP0Write
    output logic CP0WriteD,

    /*CP0D*/
    output word_t CP0DD,

    output i8 interrupt_info,
    output addr_t epc,
    /*Forward*/
    input regidx_t RdE,
    input logic CP0WriteE,
    input word_t RtDE,
    input addr_t PCE, BadVAddrE,
    input logic BDE,
    input logic EretE,
    input logic exception_enable,
    input ecode_t ecode,

    //exceptions
    input i8 EVectorF,
    output i8 EVectorD,
    input logic ex_or_eret,
    input logic i_data_ok,

    //ext_int
    input i6 ext_int,

    input logic StallE
);
    /*fetch instr*/
    ibus_resp_t instr;
    /*PC*/
    addr_t PCPlus4D;
    /*instr structure*/
    regidx_t rs, rt, rd;
    /*regfile*/
    word_t rd1, rd2;
    /*hilo*/
    word_t hi, lo;
    /*BD(F)*/
    logic BDF;

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

    assign HiD = (HiWriteE & ~ex_or_eret) ? HiDataE : hi;
    assign LoD = (LoWriteE & ~ex_or_eret) ? LoDataE : lo;

    //exceptions
    logic Break, Syscall, Reserved;
    i8 EVectorDin;
    always_comb begin
        EVectorD = EVectorDin;
        if(Break) EVectorD[3] = '1;
        if(Syscall) EVectorD[2] = '1;
        if(Reserved) EVectorD[4] = '1;
    end

    Din D_inst(.*);
    regfile regfile_inst(.clk, .resetn, .ra1(rs), .ra2(rt), .wa3(WriteRegW), .wd3(ResultW), .write_enable(RegWriteW), .rd1, .rd2);
    cp0 cp0_inst(.clk, .resetn, .ra(rd), .wa(RdE), .write_enable(CP0WriteE & ~ex_or_eret & ~StallE), .wd(RtDE), .rd(CP0DD), .interrupt_info, .exception_enable(exception_enable & i_data_ok), .pc(PCE), .addr(BadVAddrE), .bd(BDE), .ecode, .eret_enable(EretE & i_data_ok), .epc, .ext_int);
    hilo hilo_inst(.clk, .resetn, .hi, .lo, .hi_write(HiWriteE & ~ex_or_eret), .lo_write(LoWriteE & ~ex_or_eret), .hi_data(HiDataE), .lo_data(LoDataE));    
    ControlUnit ControlUnit_inst(.*);
    logic _unused_ok = &{'0, instr};
endmodule
