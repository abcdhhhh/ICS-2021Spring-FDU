`include"mycpu/defs.svh"

module mult (
    input logic clk, resetn,
    input i32 SrcA, SrcB,
    input mult_t MULTControlE,
    output i32 hi, lo,
    output logic done
);
    logic mult_valid, div_valid;
    i32 a, b;
    logic mult_done, div_done;
    i64 mult_c, div_c;
    multmult multmult_inst(.clk, .resetn, .valid(mult_valid), .a, .b, .done(mult_done), .c(mult_c));
    multdiv multdiv_inst(.clk, .resetn, .valid(div_valid), .a, .b, .done(div_done), .c(div_c));
    always_comb begin
        {mult_valid, div_valid, hi, lo} = '0;
        done = '1;
        case (MULTControlE)
            MULTU: begin
                mult_valid = '1;
                a = SrcA; b = SrcB;
                {hi, lo} = mult_c;
                done = mult_done;
            end
            MULT: begin
                mult_valid = '1;
                a = SrcA[31] ? -SrcA : SrcA; 
                b = SrcB[31] ? -SrcB : SrcB; 
                {hi, lo} = (SrcA[31]^SrcB[31]) ? -mult_c : mult_c;
                done = mult_done;
            end
            DIVU: begin
                div_valid = '1;
                a = SrcA; b = SrcB;
                {hi, lo} = div_c;
                done = div_done;
            end
            DIV: begin
                div_valid = '1;
                a = SrcA[31] ? -SrcA : SrcA; 
                b = SrcB[31] ? -SrcB : SrcB; 
                hi = SrcA[31] ? -div_c[63:32] : div_c[63:32];
                lo = (SrcA[31]^SrcB[31]) ? -div_c[31:0] : div_c[31:0];
                done = div_done;
            end
            default: ;
        endcase
    end
endmodule