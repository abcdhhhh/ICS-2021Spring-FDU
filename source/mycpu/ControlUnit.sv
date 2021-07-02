`include"mycpu/defs.svh"

module ControlUnit(
    input ibus_resp_t instr,
    input addr_t PCPlus4D,
    input word_t RsDD, RtDD,

    /*instr structure*/
    output regidx_t rs, rt, rd,
    output word_t SignImmD,
    //signals
    output addr_t PCBranchD,
    output logic PCSrcD,
    output logic BDF,
    output logic RegWriteD, MemtoRegD, MemWriteD, RegDstD,
    output logic LinkD, RetD,
    output logic HiWriteD, LoWriteD,
    output logic [1:0] ALUSrcAD, ALUSrcBD,
    output alu_t ALUControlD,
    output mult_t MULTControlD,
    output logic willmult,
    output msize_t SizeD,
    output logic SignedD,

    //exceptions
    output logic Break, Syscall, Reserved,

    // COP0
    output logic CP0WriteD,
    output logic EretD
);
    /*instr structure*/
    logic [4:0] sa;
    logic [25:0] instr_index;
    logic [15:0] imm;
    opcode_t op;
    funct_t funct;
    assign rs=instr.data[25:21];
    assign rt=instr.data[20:16];
    assign rd=instr.data[15:11];
    assign sa=instr.data[10:6];
    assign instr_index=instr.data[25:0];
    assign imm=instr.data[15:0];

    // Reserved, op, funct        
    always_comb begin
        Reserved='0;
        /*op*/
        unique case(instr.data[31:26])
            6'b000000: op=OP_RTYPE;
            6'b000001: op=OP_BTYPE;
            6'b000010: op=OP_J;
            6'b000011: op=OP_JAL;
            6'b000100: op=OP_BEQ;
            6'b000101: op=OP_BNE;
            6'b000110: op=OP_BLEZ;
            6'b000111: op=OP_BGTZ;
            6'b001000: op=OP_ADDI;
            6'b001001: op=OP_ADDIU;
            6'b001010: op=OP_SLTI;
            6'b001011: op=OP_SLTIU;
            6'b001100: op=OP_ANDI;
            6'b001101: op=OP_ORI;
            6'b001110: op=OP_XORI;
            6'b001111: op=OP_LUI;
            6'b010000: op=OP_COP0;
            6'b100000: op=OP_LB;
            6'b100001: op=OP_LH;
            6'b100011: op=OP_LW;
            6'b100100: op=OP_LBU;
            6'b100101: op=OP_LHU;
            6'b101000: op=OP_SB;
            6'b101001: op=OP_SH;
            6'b101011: op=OP_SW;
            default: begin
                op=OP_RTYPE;
                Reserved='1;
            end
        endcase
        /*funct*/
        unique case(instr.data[5:0])
            6'b000000: funct=FN_SLL;
            6'b000010: funct=FN_SRL;
            6'b000011: funct=FN_SRA;
            6'b000110: funct=FN_SRLV;
            6'b000111: funct=FN_SRAV;
            6'b000100: funct=FN_SLLV;
            6'b001000: funct=FN_JR;
            6'b001001: funct=FN_JALR;
            6'b001100: funct=FN_SYSCALL;
            6'b001101: funct=FN_BREAK;
            6'b010000: funct=FN_MFHI;
            6'b010001: funct=FN_MTHI;
            6'b010010: funct=FN_MFLO;
            6'b010011: funct=FN_MTLO;
            6'b011000: funct=FN_MULT;
            6'b011001: funct=FN_MULTU;
            6'b011010: funct=FN_DIV;
            6'b011011: funct=FN_DIVU;
            6'b100000: funct=FN_ADD;
            6'b100001: funct=FN_ADDU;
            6'b100010: funct=FN_SUB;
            6'b100011: funct=FN_SUBU;
            6'b100100: funct=FN_AND;
            6'b100101: funct=FN_OR;
            6'b100110: funct=FN_XOR;
            6'b100111: funct=FN_NOR;
            6'b101010: funct=FN_SLT;
            6'b101011: funct=FN_SLTU;
            default: begin
                funct=FN_SLL;
                if(op==OP_RTYPE) Reserved='1;
            end
        endcase
        unique case(op)
            OP_RTYPE: begin
                unique case(funct)
                    // rs
                    FN_SLL, FN_SRL, FN_SRA: begin
                        if(rs != 5'b0) Reserved = '1;
                    end
                    // rt
                    FN_JALR: begin
                        if(rt != 5'b0) Reserved = '1;
                    end
                    // rt+rd
                    FN_JR: begin
                        if({rt,rd} != 10'b0) Reserved = '1;
                    end
                    // sa
                    FN_SLLV, FN_SRLV, FN_SRAV, FN_ADD, FN_ADDU, FN_SUB, FN_SUBU, FN_AND, FN_OR, FN_XOR, FN_NOR, FN_SLT, FN_SLTU: begin
                        if(sa != 5'b0) Reserved = '1;
                    end
                    // rs+rt+sa
                    FN_MFHI, FN_MFLO: begin
                        if({rs,rt,sa} != 15'b0) Reserved = '1;
                    end
                    // rt+rd+sa
                    FN_MTHI, FN_MTLO: begin
                        if({rt,rd,sa} != 15'b0) Reserved = '1;
                    end
                    // rd+sa
                    FN_MULT, FN_MULTU, FN_DIV, FN_DIVU: begin
                        if({rd,sa} != 10'b0) Reserved = '1;
                    end
                    default: ;
                endcase
            end
            OP_BTYPE: begin
                if(rt[3:1] != 3'b0) Reserved = '1;
            end
            OP_COP0: begin
                unique case(rs)
                    5'b00000, 5'b00100: begin
                        if(instr.data[10:3] != 8'b0) Reserved = '1;
                    end
                    5'b10000: begin
                        if(instr.data[20:0] != 21'b11000) Reserved = '1;
                    end
                    default: Reserved = '1;
                endcase
            end
            OP_BLEZ, OP_BGTZ: begin
                if(rt != 5'b0) Reserved = '1;
            end
            OP_LUI: begin
                if(rs != 5'b0) Reserved = '1;
            end
            default: ;
        endcase
    end

    /*SignImm*/
    always_comb begin
        unique case(op)
            /*sa*/
            OP_RTYPE: SignImmD={27'b0, sa};
            /*high imm*/
            OP_LUI: SignImmD={imm,16'b0};
            /*unsigned imm*/
            OP_ANDI, OP_ORI, OP_XORI: SignImmD={16'b0, imm};
            /*signed imm*/
            default: SignImmD={{16{imm[15]}}, imm};
        endcase
    end

    /*PCBranch*/
    always_comb begin
        unique case(op)
            OP_BTYPE, OP_BEQ, OP_BNE, OP_BLEZ, OP_BGTZ: PCBranchD=PCPlus4D+(SignImmD<<2);
            OP_J, OP_JAL: PCBranchD={PCPlus4D[31:28], instr_index, 2'b0};
            OP_RTYPE: PCBranchD=RsDD;
            default: PCBranchD=32'hbfc00000;
        endcase
    end

    /*PCSrc*/
    always_comb begin
        unique case(op)
            OP_BTYPE: PCSrcD=RsDD[31]^rt[0];
            OP_BEQ: PCSrcD=(RsDD==RtDD);
            OP_BNE: PCSrcD=(RsDD!=RtDD);
            OP_BLEZ: PCSrcD=($signed(RsDD)<=0);
            OP_BGTZ: PCSrcD=($signed(RsDD)>0);
            OP_J, OP_JAL: PCSrcD='1;
            OP_RTYPE: PCSrcD=(funct==FN_JR || funct==FN_JALR);
            default: PCSrcD='0;
        endcase
    end

    /*BD(F)*/
    always_comb begin
        unique case(op)
            OP_BTYPE, OP_BEQ, OP_BNE, OP_BLEZ, OP_BGTZ, OP_J, OP_JAL: BDF = '1;
            OP_RTYPE: BDF = (funct==FN_JR || funct==FN_JALR);
            default: BDF = '0;
        endcase
    end

    /*RegWrite*/
    always_comb begin
        unique case(op)
            /*write*/
            OP_JAL: RegWriteD='1;
            /*rt[4]*/
            OP_BTYPE: RegWriteD=rt[4];
            /*not write*/
            OP_J, OP_BEQ, OP_BNE, OP_BLEZ, OP_BGTZ, OP_SB, OP_SH, OP_SW: RegWriteD='0;
            /*rd*/
            OP_RTYPE: RegWriteD = (funct!=FN_BREAK && funct!=FN_SYSCALL && rd!=5'b0);
            /*COP0*/
            OP_COP0: RegWriteD = (rs == 5'b0);
            /*rt*/
            default: RegWriteD=(rt!=5'b0);
        endcase
    end

    /*MemtoReg*/
    always_comb begin
        unique case(op)
            OP_LB, OP_LH, OP_LW, OP_LBU, OP_LHU: MemtoRegD='1;
            default: MemtoRegD='0;
        endcase
    end

    /*MemWrite*/
    always_comb begin
        unique case(op)
            OP_SB, OP_SH, OP_SW: MemWriteD='1;
            default: MemWriteD='0;
        endcase
    end

    /*ALUSrcA*/
    always_comb begin
        unique case(op)
            OP_RTYPE: begin
                unique case(funct)
                    /*SignImm*/
                    FN_SLL, FN_SRA, FN_SRL: ALUSrcAD=2'b01;
                    /*Hi*/
                    FN_MFHI: ALUSrcAD=2'b10;
                    /*Lo*/
                    FN_MFLO: ALUSrcAD=2'b11;
                    /*Rs*/
                    default: ALUSrcAD=2'b00;
                endcase
            end
            /*Rs*/
            default: ALUSrcAD=2'b00;
        endcase
    end

    /*ALUSrcB*/
    always_comb begin
        unique case(op)
            /*WriteData(RtD)*/
            OP_RTYPE: ALUSrcBD = 2'b00;
            /*CP0D*/
            OP_COP0: ALUSrcBD = 2'b01;
            /*SignImm*/
            default: ALUSrcBD = 2'b10;
        endcase
    end

    /*RegDst*/
    assign RegDstD=(op==OP_RTYPE);

    /*Link*/
    always_comb begin
        unique case(op)
            OP_BTYPE: LinkD=rt[4];
            OP_JAL: LinkD='1;
            OP_RTYPE: LinkD=(funct==FN_JALR);
            default: LinkD='0;
        endcase
    end

    /*Ret*/
    always_comb begin
        unique case(op)
            OP_BTYPE: RetD=rt[4];
            OP_JAL: RetD='1;
            default: RetD='0;
        endcase
    end

    /*HiWrite*/
    always_comb begin
        unique case(op)
            OP_RTYPE: begin
                unique case(funct)
                    FN_MTHI, FN_MULT, FN_MULTU, FN_DIV, FN_DIVU: HiWriteD='1;
                    default: HiWriteD='0;
                endcase
            end
            default: HiWriteD='0;
        endcase
    end
    /*LoWrite*/
    always_comb begin
        unique case(op)
            OP_RTYPE: begin
                unique case(funct)
                    FN_MTLO, FN_MULT, FN_MULTU, FN_DIV, FN_DIVU: LoWriteD='1;
                    default: LoWriteD='0;
                endcase
            end
            default: LoWriteD='0;
        endcase
    end

    /*ALUControl*/
    always_comb begin  
        if(op==OP_RTYPE) begin
            unique case(funct)
                FN_SLL, FN_SLLV: ALUControlD=ALU_SLL;
                FN_SRL, FN_SRLV: ALUControlD=ALU_SRL;
                FN_SRA, FN_SRAV: ALUControlD=ALU_SRA;
                FN_ADD: ALUControlD=ALU_ADD;
                FN_ADDU: ALUControlD=ALU_ADDU;
                FN_SUB: ALUControlD=ALU_SUB;
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
                OP_ADDI: ALUControlD=ALU_ADD;
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

    /*MULTControl*/
    always_comb begin  
        willmult = '0;
        if(op==OP_RTYPE) begin
            willmult = '1;
            unique case(funct)
                FN_MULT: MULTControlD=MULT;
                FN_MULTU: MULTControlD=MULTU;
                FN_DIV: MULTControlD=DIV;
                FN_DIVU: MULTControlD=DIVU;
                default: begin
                    MULTControlD=CLR;
                    willmult = '0;
                end
            endcase
        end
        else MULTControlD=CLR;
    end

    /*Strobe*/
    always_comb begin
        unique case(op)
            OP_LB, OP_LBU, OP_SB: SizeD=MSIZE1;
            OP_LH, OP_LHU, OP_SH: SizeD=MSIZE2;
            default: SizeD=MSIZE4;
        endcase
    end
    /*Signed*/
    always_comb begin
        unique case(op)
            OP_LBU, OP_LHU: SignedD='0;
            default: SignedD='1;
        endcase
    end

    //exceptions
    assign Break = (instr.data[31:26]==6'b0 && funct==FN_BREAK);
    assign Syscall = (instr.data[31:26]==6'b0 && funct==FN_SYSCALL);

    /*CP0Write*/
    assign CP0WriteD = (op == OP_COP0 && rs==5'b00100);

    /*EretD*/
    assign EretD = (op == OP_COP0 && rs==5'b10000);

    logic _unused_ok = &{'0, instr};
endmodule