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
    logic RegWriteD, MemtoRegD, MemWriteD, RegDstD, LinkD, RetD;
    msize_t SizeD;
    logic SignedD;
    logic [1:0] ALUSrcD;
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
    msize_t SizeE;
    logic SignedE;
    logic [1:0] ForwardAE, ForwardBE;
    execute execute_inst(.*);

    logic StallM, FlushM;
    addr_t PCM;
    regidx_t RtM;
    regidx_t WriteRegM;
    logic RegWriteM, MemtoRegM, MemWriteM;
    msize_t SizeM;
    logic SignedM;
    logic d_validM;
    logic ForwardM;
    memory memory_inst(.*);

    /*d_translator*/
    word_t DataM;
    assign dreq.valid=d_validM;
    assign dreq.addr={3'b0,ALUOutM[28:0]};
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
