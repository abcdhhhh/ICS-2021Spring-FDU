`include"common.svh"
`include"mycpu/type.svh"

module Fin(
    input logic clk,resetn, StallF,FlushF,
    input addr_t PC0,
    output addr_t PCF,
    output logic i_validF
);
    always_ff @(posedge clk) begin
        if(~resetn|FlushF) begin
            PCF<=32'hbfc00000-32'h4;
            i_validF<='0;
        end
        else if(~StallF) begin
            PCF<=PC0;
            i_validF<='1;
        end
    end
endmodule