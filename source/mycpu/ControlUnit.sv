`include"common.svh"
`include"mycpu/type.svh"

module ControlUnit(
    input ibus_resp_t instr,
    input addr_t PCPlus4D,
    input word_t RsDD, RtDD,

    /*instr structure*/
    output regidx_t rs, rt, rd,
    output word_t SignImmD,
    /*signal*/
    output addr_t PCBranchD,
    output logic PCSrcD,
    output logic RegWriteD, MemtoRegD, MemWriteD, RegDstD, LinkD, 
    output logic [1:0] ALUSrcD,
    output alu_t ALUControlD
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
        /*op*/
    always_comb begin
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
            default: op=OP_RTYPE;
        endcase
    end
        /*funct*/
    always_comb begin
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
            default: funct=FN_SLL;
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
            OP_RTYPE: PCSrcD=(funct==FN_JR);
            default: PCSrcD='0;
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
            OP_RTYPE: RegWriteD=(rd!=5'b0);
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

    /*ALUSrc*/
    always_comb begin
        unique case(op)
            OP_RTYPE: begin
                unique case(funct)
                    FN_SLL, FN_SRA, FN_SRL: ALUSrcD=2'b01;
                    default: ALUSrcD='0;
                endcase
            end
            default: ALUSrcD=2'b10;
        endcase
    end

    /*RegDst*/
    assign RegDstD=(op==OP_RTYPE);

    /*LinkD*/
    always_comb begin
        unique case(op)
            OP_BTYPE: LinkD=rt[4];
            OP_JAL: LinkD='1;
            default: LinkD='0;
        endcase
    end

    /*ALUControl*/
    always_comb begin  
        if(op==OP_RTYPE) begin
            unique case(funct)
                FN_SLL, FN_SLLV: ALUControlD=ALU_SLL;
                FN_SRL, FN_SRLV: ALUControlD=ALU_SRL;
                FN_SRA, FN_SRAV: ALUControlD=ALU_SRA;
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
    logic _unused_ok = &{'0, instr};
endmodule