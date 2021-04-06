`include"common.svh"

module selectpc(
    /*PC*/
    input logic PCSrcD,
    input addr_t PCPlus4F, PCBranchD,
    output addr_t PC0
);
    always_comb begin
        if(PCSrcD) begin
            PC0=PCBranchD;
        end
        else begin
            PC0=PCPlus4F;
        end
    end
endmodule
