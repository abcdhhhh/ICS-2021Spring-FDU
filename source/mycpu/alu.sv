`include"common.svh"
`include"mycpu/type.svh"

module alu(
    input alu_t ALUControlE,
    input word_t SrcA, SrcB,
    output word_t ALUResult
);
    always_comb begin
        unique case(ALUControlE)
            ALU_SLL: ALUResult=SrcB<<SrcA;
            ALU_SRL: ALUResult=SrcB>>SrcA;
            ALU_SRA: ALUResult=$signed(SrcB)>>>SrcA;
            ALU_ADDU: ALUResult=SrcA+SrcB;
            ALU_SUBU: ALUResult=SrcA-SrcB;
            ALU_AND: ALUResult=SrcA&SrcB;
            ALU_OR: ALUResult=SrcA|SrcB;
            ALU_XOR: ALUResult=SrcA^SrcB;
            ALU_NOR: ALUResult=~(SrcA|SrcB);
            ALU_SLT: ALUResult={31'b0, ($signed(SrcA)<$signed(SrcB))};
            ALU_SLTU: ALUResult={31'b0, (SrcA<SrcB)};
            default: ALUResult=SrcA+SrcB;
        endcase
    end
endmodule