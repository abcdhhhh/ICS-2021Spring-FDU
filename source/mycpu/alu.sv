`include"mycpu/defs.svh"

module alu(
    input alu_t ALUControlE,
    input word_t SrcA, SrcB,
    output word_t ALUResult,
    output logic ALUOverflow
);
    always_comb begin
        ALUOverflow='0;
        unique case(ALUControlE)
            ALU_SLL: ALUResult=SrcB<<{27'b0,SrcA[4:0]};
            ALU_SRL: ALUResult=SrcB>>{27'b0,SrcA[4:0]};
            ALU_SRA: ALUResult=$signed(SrcB)>>>{27'b0,SrcA[4:0]};
            ALU_ADD: begin
                ALUResult=$signed(SrcA)+$signed(SrcB);
                if(SrcA[31] == SrcB[31]) ALUOverflow=SrcA[31]^ALUResult[31];
            end
            ALU_ADDU: ALUResult=SrcA+SrcB;
            ALU_SUB: begin
                ALUResult=$signed(SrcA)-$signed(SrcB);
                if(SrcA[31] != SrcB[31]) ALUOverflow=SrcA[31]^ALUResult[31];
            end
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