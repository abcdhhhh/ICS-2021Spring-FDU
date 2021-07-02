`include"mycpu/defs.svh"

module selectpc(
    /*PC*/
    input logic PCSrcD,
    input addr_t PCPlus4F, PCBranchD,
    output addr_t PC0,

    //exceptions
    input logic exception_enable,
    input logic EretE,
    input addr_t epc
);
    always_comb begin
        if(exception_enable) begin
            PC0 = 32'hbfc00380;
        end
        else if(EretE) begin
            PC0 = epc;
        end
        else if(PCSrcD) begin
            PC0=PCBranchD;
        end
        else begin
            PC0=PCPlus4F;
        end
    end
endmodule
