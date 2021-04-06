`include"common.svh"
`include"mycpu/type.svh"

module MyCore (
    input logic clk, resetn,

    output ibus_req_t  ireq,
    input  ibus_resp_t iresp,
    output dbus_req_t  dreq,
    input  dbus_resp_t dresp
);
    /**
     * TODO (Lab1) your code here :)
     */
    /*valid*/
    logic i_data_ok, d_data_ok;
    assign i_data_ok=~ireq.valid|iresp.data_ok;
    assign d_data_ok=~dreq.valid|dresp.data_ok;

    logic PCSrcD;
    addr_t PCPlus4F, PCBranchD;
    addr_t PC0;
    selectpc selectpc_inst(.*);

    logic StallF,FlushF;
    addr_t PCF;
    logic i_validF;
    fetch fetch_inst(.*);

    /*i_translator*/
    assign ireq.valid=i_validF;
    assign ireq.addr={3'b0, PCF[28:0]};

    logic StallD,FlushD;
    addr_t PCD;
    word_t SignImmD;
    regidx_t RsD, RtD, RdD;
    word_t RsDD, RtDD;
    regidx_t WriteRegW;
    logic RegWriteW;
    word_t ResultW;
    logic RegWriteD, MemtoRegD, MemWriteD, ALUSrcD, RegDstD, LinkD;
    alu_t ALUControlD;
    word_t ALUOutE, ALUOutM;
    logic [1:0] ForwardAD, ForwardBD;
    decode decode_inst(.*);

    logic StallE, FlushE;
    addr_t PCE;
    regidx_t RsE, RtE;
    regidx_t WriteRegE;
    word_t WriteDataE;
    logic RegWriteE, MemtoRegE, MemWriteE;
    logic [1:0] ForwardAE, ForwardBE;
    execute execute_inst(.*);

    logic StallM, FlushM;
    addr_t PCM;
    regidx_t RtM;
    regidx_t WriteRegM;
    logic RegWriteM, MemtoRegM, MemWriteM;
    logic d_validM;
    logic ForwardM;
    memory memory_inst(.*);

    /*d_translator*/
    word_t DataM;
    assign dreq.valid=d_validM;
    assign dreq.addr={3'b0,ALUOutM[28:0]};
    assign dreq.size=MSIZE4;
    assign dreq.strobe=MemWriteM ? 4'b1111 : 4'b0;
    assign dreq.data=DataM;

    logic StallW, FlushW;
    addr_t PCW;
    writeback writeback_inst(.*);

    hazard hazard_inst(.*);

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
