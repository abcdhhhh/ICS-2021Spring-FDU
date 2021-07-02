`include"mycpu/defs.svh"

module MyCore (
    input logic clk, resetn,

    output ibus_req_t  ireq,
    input  ibus_resp_t iresp,
    output dbus_req_t  dreq,
    input  dbus_resp_t dresp,

    input i6 ext_int
);
    /**
     * TODO (Lab1) your code here :)
     */
    /*valid*/
    logic i_data_ok, d_data_ok;
    assign i_data_ok=~ireq.valid|iresp.data_ok;
    assign d_data_ok=~dreq.valid|dresp.data_ok;

    /*PC*/
    addr_t PC0, PCF, PCD, PCE, PCM, PCW;
    addr_t PCPlus4F;
    addr_t PCBranchD;
    logic PCSrcD;

    /*BD*/
    logic BDD, BDE;

    /*Stall*/
    logic StallF, StallD, StallE, StallM, StallW;
    /*Flush*/
    logic FlushF, FlushD, FlushE, FlushM, FlushW;

    /*d_valid*/
    logic d_validM;

    /*SignImm*/
    word_t SignImmD;
    /*RsD*/
    word_t RsDD;
    word_t RtDD, RtDE;

    /*Rs*/
    regidx_t RsD, RsE;
    /*Rt*/
    regidx_t RtD, RtE, RtM;
    /*Rd*/
    regidx_t RdD, RdE;
    /*RegDst*/
    logic RegDstD;
    /*WriteReg*/
    regidx_t WriteRegE, WriteRegM, WriteRegW;
    /*RegWrite*/
    logic RegWriteD, RegWriteE, RegWriteM, RegWriteW;

    /*MemtoReg*/
    logic MemtoRegD, MemtoRegE, MemtoRegM;    
    /*MemWrite*/
    logic MemWriteD, MemWriteE, MemWriteM;

    /*Hi, Lo*/
    word_t HiD, LoD;
    /*HiData, LoData*/
    word_t HiDataE, LoDataE;
    /*HiWrite*/
    logic HiWriteD, HiWriteE;
    /*LoWrite*/
    logic LoWriteD, LoWriteE;

    /*CP0Write*/
    logic CP0WriteD, CP0WriteE;
    /*CP0D*/
    word_t CP0DD;
    /*interrupt_info*/
    i8 interrupt_info;
    /*epc*/
    addr_t epc;

    /*ALU*/
    logic [1:0] ALUSrcAD, ALUSrcBD;
    alu_t ALUControlD;
    word_t ALUOutE, ALUOutM;
    /*MULT*/
    mult_t MULTControlD;
    logic done, willmult;

    /*WriteData*/
    word_t WriteDataE;
    /*Data*/
    word_t DataM;

    /*Result*/
    word_t ResultW;

    /*Link, Ret*/
    logic LinkD, RetD;
    
    /*Size*/
    msize_t SizeD, SizeE, SizeM;
    /*Signed*/
    logic SignedD, SignedE, SignedM;

    /*Forward*/
    logic [1:0] ForwardAD, ForwardBD;
    logic [1:0] ForwardAE, ForwardBE;
    logic ForwardM;

    /*BadVAddr*/
    addr_t BadVAddrE;

    /*Eret*/
    logic EretD, EretE;

    /*EVector*/
    i8 EVectorF, EVectorD;

    ecode_t ecode;
    logic exception_enable;

    logic ex_or_eret;
    
    selectpc selectpc_inst(.*);
    fetch fetch_inst(.*);
    decode decode_inst(.*);
    execute execute_inst(.*);
    memory memory_inst(.*);
    writeback writeback_inst(.*);
    hazard hazard_inst(.*);

    /*i_translator*/
    
    /*d_translator*/
    assign dreq.valid=d_validM;
    assign dreq.addr=ALUOutM;
    assign dreq.size=SizeM;
        /*strobe*/
    always_comb begin
        dreq.strobe=4'b0000;
        if(MemWriteM) begin
            unique case(SizeM)
                MSIZE1: begin
                    unique case(ALUOutM[1:0])
                        2'b00: dreq.strobe=4'b0001;
                        2'b01: dreq.strobe=4'b0010;
                        2'b10: dreq.strobe=4'b0100;
                        2'b11: dreq.strobe=4'b1000;
                        default: dreq.strobe=4'b0001;
                    endcase
                end
                MSIZE2: begin
                    unique case(ALUOutM[1])
                        1'b0: dreq.strobe=4'b0011;
                        1'b1: dreq.strobe=4'b1100;
                        default: dreq.strobe=4'b0011;
                    endcase
                end
                MSIZE4: dreq.strobe=4'b1111;
                default: dreq.strobe=4'b1111;
            endcase
        end
    end
        /*data*/
    always_comb begin
        unique case(ALUOutM[1:0])
            2'b00: dreq.data=DataM;
            2'b01: dreq.data=DataM<<32'h8;
            2'b10: dreq.data=DataM<<32'h10;
            2'b11: dreq.data=DataM<<32'h18;
            default: dreq.data=DataM;
        endcase
    end

    logic _unused_ok=&{1'b0, ireq, iresp, dreq, dresp, PCW};
/*
    always_ff @(posedge clk)
    if (resetn) begin
        // AHA!
    end else begin
        // reset
        // NOTE: if resetn is X, it will be evaluated to false.
    end

    // remove following lines when you start

    assign ireq = '0;
    assign dreq = '0;
    logic _unused_ok = &{iresp, dresp};
*/
endmodule
