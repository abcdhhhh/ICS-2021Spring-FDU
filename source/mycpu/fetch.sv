`include"common.svh"

module fetch(
    input logic clk,resetn,StallF,FlushF,
    /*PC*/
    input addr_t PC0,
    output addr_t PCF, PCPlus4F,
    /*valid*/
    output logic i_validF
);
    Fin Fin_inst(.*);
    assign PCPlus4F=PCF+32'b100;
endmodule




