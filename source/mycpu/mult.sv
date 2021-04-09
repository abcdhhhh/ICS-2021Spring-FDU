`include"common.svh"
`include"mycpu/type.svh"

module mult (
    input i32 SrcA, SrcB,
    input mult_t MULTControlE,
    output i32 hi, lo
);
    i64 ans;
    always_comb begin
        case (MULTControlE)
            MULTU: begin
                ans = {32'b0, SrcA} * {32'b0, SrcB};
                hi = ans[63:32]; lo = ans[31:0];
            end
            MULT: begin
                ans = signed'({{32{SrcA[31]}}, SrcA}) * signed'({{32{SrcB[31]}}, SrcB});
                hi = ans[63:32]; lo = ans[31:0];
            end
            DIVU: begin
                ans = '0;
                lo = SrcA/SrcB;
                hi = SrcA%SrcB;
            end
            DIV: begin
                ans = '0;
                lo = signed'(SrcA) / signed'(SrcB);
                hi = signed'(SrcA) % signed'(SrcB);
            end
            default: begin
                {hi, lo, ans} = '0;
            end
        endcase
    end
endmodule