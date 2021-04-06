`include"common.svh"
`include"mycpu/type.svh"


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
    input regidx_t WriteRegM /* verilator public_flat_rd */,
    output regidx_t WriteRegW,
    /*ControlUnit*/
    input logic RegWriteM, MemtoRegM,
    output logic RegWriteW /* verilator public_flat_rd */
);
    dbus_resp_t ReadDataW;
    logic MemtoRegW;
    word_t ALUOutW;
    Win Win_inst(.*);
    always_comb begin
        if(MemtoRegW) begin
            ResultW=ReadDataW.data;
        end
        else begin
            ResultW=ALUOutW;
        end
    end
    logic _unused_ok = &{'0, ReadDataW};
endmodule

