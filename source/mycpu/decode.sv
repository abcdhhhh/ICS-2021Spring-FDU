`include"common.svh"
`include"mycpu/type.svh"

module decode(
    input logic clk,resetn,StallD,FlushD,
    /*resp*/
    input ibus_resp_t iresp,
    /*PC*/
    input addr_t PCF, PCPlus4F,
    output addr_t PCD, PCBranchD,
    /*imm*/
    output word_t SignImmD,
    /*reg*/
    output regidx_t RsD, RtD, RdD,
    output word_t RsDD, RtDD,
    input regidx_t WriteRegW,
    input logic RegWriteW,
    input word_t ResultW,
    /*ControlUnit*/
    output logic PCSrcD,
    output logic RegWriteD, MemtoRegD, MemWriteD, ALUSrcD, RegDstD, LinkD,
    output alu_t ALUControlD,
    /*Forward*/
    input word_t ALUOutM, ALUOutE,
    input logic [1:0] ForwardAD, ForwardBD
);
    /*fetch instr*/
    ibus_resp_t instr;
    /*PC*/
    addr_t PCPlus4D;
    Din D_inst(.*);
    /*instr structure*/
    logic i_validD;
    opcode_t op;
    funct_t funct;
    regidx_t rs, rt, rd, sa;
    logic [25:0] instr_index;
    logic [15:0] imm;

    assign i_validD=instr.data_ok;
    always_comb begin
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
            default: op=OP_RTYPE;
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
            default: funct=FN_SLL;
        endcase
    end
    assign rs=instr.data[25:21];
    assign rt=instr.data[20:16];
    assign rd=instr.data[15:11];
    assign sa=instr.data[10:6];
    assign instr_index=instr.data[25:0];
    assign imm=instr.data[15:0];
    /*SignImm*/
    always_comb begin
        unique case(op)
            OP_LUI: SignImmD={imm,16'b0};
            OP_RTYPE: SignImmD={27'b0, sa};
            OP_ANDI, OP_ORI, OP_XORI: SignImmD={16'b0, imm};
            default: SignImmD={imm[15]?~(16'b0):16'b0, imm};
        endcase
    end

    /*regfile*/
    word_t rd1, rd2;
    regfile regfile_inst(.clk, .resetn,.ra1(rs), .ra2(rt), .wa3(WriteRegW), .wd3(ResultW), .write_enable(RegWriteW), .rd1, .rd2);
    assign RsD=rs;
    assign RtD=rt;
    assign RdD=rd;
    /*Compare*/
    always_comb begin
        unique case(ForwardAD)
            2'b01: RsDD=ResultW;
            2'b10: RsDD=ALUOutM;
            2'b11: RsDD=ALUOutE;
            default: RsDD=rd1;
        endcase
        unique case(ForwardBD)
            2'b01: RtDD=ResultW;
            2'b10: RtDD=ALUOutM;
            2'b11: RtDD=ALUOutE;
            default: RtDD=rd2;
        endcase
    end
    /*PCSrc, PCBranch*/
    always_comb begin
        unique case(op)
            OP_BEQ, OP_BNE: begin
                PCSrcD=(RsDD==RtDD)^(op==OP_BNE);
                PCBranchD=PCPlus4D+(SignImmD<<2);
            end
            OP_J, OP_JAL: begin
                PCSrcD='1;
                PCBranchD={PCPlus4D[31:28], instr_index, 2'b0};
            end
            OP_RTYPE: begin
                if(funct==FN_JR) begin
                    PCSrcD='1;
                    PCBranchD=RsDD;
                end
                else begin
                    PCSrcD='0;
                    PCBranchD=32'hbfc00000;
                end
            end
            default: begin
                PCSrcD='0;
                PCBranchD=32'hbfc00000;
            end
        endcase
    end
    /*ControlUnit*/
    ControlUnit ControlUnit_inst(.*);
    logic _unused_ok = &{'0, instr};
endmodule





