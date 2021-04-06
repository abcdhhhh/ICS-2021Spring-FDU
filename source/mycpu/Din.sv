`include"common.svh"
`include"mycpu/type.svh"

module Din(
    input logic clk,resetn, StallD,FlushD,
    input ibus_resp_t iresp,
    input addr_t PCF, PCPlus4F,

    output ibus_resp_t instr,
    output addr_t PCD, PCPlus4D
);
    always_ff @(posedge clk) begin
        if(~resetn|FlushD) begin
            instr<='0;
            PCD<=32'hbfc00000;
            PCPlus4D<=32'hbfc00000;
        end
        else if(~StallD) begin
            instr<=iresp;
            PCD<=PCF;
            PCPlus4D<=PCPlus4F;  
        end
    end
endmodule