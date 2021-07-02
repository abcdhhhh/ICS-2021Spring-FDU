`include"mycpu/defs.svh"

module fetch(
    input logic clk,resetn,StallF,FlushF,
    /*ireq*/
    output ibus_req_t ireq,
    /*PC*/
    input addr_t PC0,
    output addr_t PCF, PCPlus4F,

    //exception
    output i8 EVectorF
);
    logic i_validF;
    logic ADELI;

    assign PCPlus4F=PCF+32'b100;  
    assign ADELI = |{PCF[1:0]};
    
    /*EVector*/
    always_comb begin
        EVectorF = '0;
        if(ADELI) EVectorF[1] = '1;
    end

    /*ireq*/
    assign ireq.valid=i_validF;
    always_comb begin
        ireq.addr=PCF;
        if(ADELI) ireq.addr=32'hbfc00000;
    end

    Fin Fin_inst(.*);
endmodule




