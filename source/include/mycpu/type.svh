`ifndef __MYCPU_TYPE_SVH__
`define __MYCPU_TYPE_SVH__

typedef enum{
    ALU_SLL,
    ALU_SRL,
    ALU_SRA,
    ALU_ADD,
    ALU_ADDU,
    ALU_SUB,
    ALU_SUBU,
    ALU_AND,
    ALU_OR,
    ALU_XOR,
    ALU_NOR,
    ALU_SLT,
    ALU_SLTU
} alu_t;

typedef enum{
    MULT,
    MULTU,
    DIV,
    DIVU,
    CLR
} mult_t;
`endif