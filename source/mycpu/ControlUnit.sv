`include"common.svh"
`include"mycpu/type.svh"

module ControlUnit(
    input opcode_t op,
    input funct_t funct,
    input regidx_t rt, rd,
    input logic i_validD,
    output logic RegWriteD, MemtoRegD, MemWriteD, ALUSrcD, RegDstD, LinkD,
    output alu_t ALUControlD
);
    always_comb begin
        RegWriteD='0;
        MemtoRegD='0;
        MemWriteD='0;
        ALUSrcD='0;
        RegDstD='0;
        LinkD='0;
        ALUControlD=ALU_ADDU;
        if(i_validD) begin
            /*RegWriteD*/
            unique case(op)
                OP_RTYPE: begin
                    if(rd==5'b0) RegWriteD='0;
                    else RegWriteD='1;
                end
                OP_J, OP_BEQ, OP_BNE, OP_SW: RegWriteD='0;
                default: begin
                    if(rt==5'b0) RegWriteD='0;
                    else RegWriteD='1;
                end
            endcase
            /*MemtoRegD*/
            if(op==OP_LW) begin
                MemtoRegD='1;
            end
            /*MemWriteD*/
            if(op==OP_SW) begin
                MemWriteD='1;
            end
            /*ALUSrcD*/
            if(op!=OP_RTYPE || funct==FN_SLL || funct==FN_SRA || funct==FN_SRL) begin
                ALUSrcD='1;
            end
            /*RegDstD*/
            if(op==OP_RTYPE) begin
                RegDstD='1;
            end
            /*LinkD*/
            if(op==OP_JAL) begin
                LinkD='1;
            end
            /*ALUControlD*/
            if(op==6'b0) begin
                unique case(funct)
                    FN_SLL: ALUControlD=ALU_SLL;
                    FN_SRL: ALUControlD=ALU_SRL;
                    FN_SRA: ALUControlD=ALU_SRA;
                    FN_ADDU: ALUControlD=ALU_ADDU;
                    FN_SUBU: ALUControlD=ALU_SUBU;
                    FN_AND: ALUControlD=ALU_AND;
                    FN_OR: ALUControlD=ALU_OR;
                    FN_XOR: ALUControlD=ALU_XOR;
                    FN_NOR: ALUControlD=ALU_NOR;
                    FN_SLT: ALUControlD=ALU_SLT;
                    FN_SLTU: ALUControlD=ALU_SLTU;
                    default: ALUControlD=ALU_ADDU;
                endcase
            end
            else begin
                unique case(op)
                    OP_ADDIU: ALUControlD=ALU_ADDU;
                    OP_SLTI: ALUControlD=ALU_SLT;
                    OP_SLTIU: ALUControlD=ALU_SLTU;
                    OP_ANDI: ALUControlD=ALU_AND;
                    OP_ORI: ALUControlD=ALU_OR;
                    OP_XORI: ALUControlD=ALU_XOR;
                    default: ALUControlD=ALU_ADDU;
                endcase
            end
        end
    end
endmodule