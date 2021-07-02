`include"mycpu/defs.svh"

module Fin(
    input logic clk,resetn, StallF,FlushF,
    /*PC*/
    input addr_t PC0,
    output addr_t PCF,
    /*i_valid*/
    output logic i_validF
);
    always_ff @(posedge clk) begin
        if(~resetn) begin
            PCF<=32'hbfc00000-32'h4;
            i_validF<='0;
        end
        else if(FlushF) begin
            PCF<='0;
            i_validF<='0;
        end
        else if(~StallF) begin
            PCF<=PC0;
            i_validF<='1;
        end
    end
endmodule