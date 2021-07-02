`include"mycpu/defs.svh"

module Din(
    input logic clk,resetn, StallD,FlushD,
    input ibus_resp_t iresp,
    output ibus_resp_t instr,
    /*PC*/
    input addr_t PCF, PCPlus4F,
    output addr_t PCD, PCPlus4D,
    /*BD*/
    input logic BDF,
    output logic BDD,
    //exception
    input i8 EVectorF,
    output i8 EVectorDin
);
    always_ff @(posedge clk) begin
        if(~resetn|FlushD) begin
            instr<='0;
            PCD<='0;
            PCPlus4D<='0;
            BDD <= '0;
            EVectorDin <= '0;
        end
        else if(~StallD) begin
            instr<=iresp;
            PCD<=PCF;
            PCPlus4D<=PCPlus4F; 
            BDD <= BDF; 
            EVectorDin <= EVectorF;
        end
    end
endmodule