`include"mycpu/defs.svh"


module writeback(
    input logic clk,resetn, StallW, FlushW,
    /*resp*/
    input dbus_resp_t dresp,
    /*PC*/
    input addr_t PCM,
    output addr_t PCW /* verilator public_flat_rd */,
    /*Write*/
    input word_t ALUOutM,
    output word_t ResultW /* verilator public_flat_rd */,
    input regidx_t WriteRegM,
    output regidx_t WriteRegW /* verilator public_flat_rd */,

    //signals
    input logic RegWriteM, MemtoRegM,
    input msize_t SizeM,
    input logic SignedM,
    output logic RegWriteW /* verilator public_flat_rd */
);
    logic MemtoRegW;
    msize_t SizeW;
    logic SignedW;
    dbus_resp_t dresp_nxt;
    word_t ALUOutW;
    Win Win_inst(.*);
    word_t ReadDataW;
    always_comb begin
        unique case(SizeW)
            MSIZE1: begin
                unique case(ALUOutW[1:0])
                    2'b00: ReadDataW[7:0]=dresp_nxt.data[7:0];
                    2'b01: ReadDataW[7:0]=dresp_nxt.data[15:8];
                    2'b10: ReadDataW[7:0]=dresp_nxt.data[23:16];
                    2'b11: ReadDataW[7:0]=dresp_nxt.data[31:24];
                    default: ReadDataW[7:0]=dresp_nxt.data[7:0];
                endcase
                ReadDataW[31:8]={24{SignedW&ReadDataW[7]}};
            end
            MSIZE2: begin
                unique case(ALUOutW[1])
                    1'b0: ReadDataW[15:0]=dresp_nxt.data[15:0];
                    1'b1: ReadDataW[15:0]=dresp_nxt.data[31:16];
                    default: ReadDataW[15:0]=dresp_nxt.data[15:0];
                endcase
                ReadDataW[31:16]={16{SignedW&ReadDataW[15]}};
            end
            default: ReadDataW=dresp_nxt.data;
        endcase
    end
    assign ResultW= MemtoRegW ? ReadDataW : ALUOutW;
    logic _unused_ok = &{'0, dresp_nxt};
endmodule

