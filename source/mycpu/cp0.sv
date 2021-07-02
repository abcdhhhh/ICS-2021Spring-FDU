`include "mycpu/defs.svh"

module cp0(
    input logic clk, resetn,
    input regidx_t ra, wa,
    input logic write_enable,
    input word_t wd,
    output word_t rd,
    output i8 interrupt_info,

    //exception
    input logic exception_enable,
    ecode_t ecode,
    input addr_t pc, addr,
    input logic bd,

    //eret
    input logic eret_enable,
    output addr_t epc,

    //ext_int
    input i6 ext_int
);
    word_t [14:8] regs, regs_nxt;
    logic dcount, dcount_nxt;
    logic timer_interrupt;
    // write: sequential logic
    always_ff @(posedge clk) begin
        regs <= regs_nxt;
        dcount <= dcount_nxt;
        if (wa == 11 && write_enable) begin
            timer_interrupt <= (wd == regs_nxt[9]);
        end
    end

    //dcount
    always_comb begin
        if(~resetn) begin
            dcount_nxt = '0;
        end else begin
            dcount_nxt = ~dcount;
        end
    end
    //regs
    always_comb begin
        regs_nxt = regs;
        // self-increase
        regs_nxt[9] = regs[9] + word_t'(dcount);
        // reset
        if(~resetn) begin
            regs_nxt = '0; 
            regs_nxt[12] = CP0_STATUS_RESET;               
        end
        // exception
        else if(exception_enable) begin 
            regs_nxt[13][6:2] = ecode; // ExcCode
            if(ecode == EX_ADEL || ecode == EX_ADES) begin // BadVAddr
                regs_nxt[8] = addr;
            end
            if(~regs[12][1]) begin // EPC, BD
                if(~bd) regs_nxt[14] = pc;
                else regs_nxt[14] = pc-32'h4;
                regs_nxt[13][31] = bd;
            end
            regs_nxt[12][1] = '1; // EXL
        end
        // eret
        else if(eret_enable) begin
            regs_nxt[12][1] = '0; // EXL
        end
        // write
        else if (write_enable) begin
            unique case(wa)
                9: regs_nxt[9] = wd; // Count
                11: regs_nxt[11] = wd; // Compare
                12: regs_nxt[12] = (wd & CP0_STATUS_MASK) | (regs[12] & ~CP0_STATUS_MASK); // Status
                13: regs_nxt[13] = (wd & CP0_CAUSE_MASK) | (regs[13] & ~CP0_CAUSE_MASK); // Cause
                14: regs_nxt[14] = wd; // EPC
                default:;
            endcase
        end
    end

    // interrupt_info
    assign interrupt_info = ({ext_int, 2'b00} | regs[13][15:8] | {timer_interrupt, 7'b0}) & regs[12][15:8] & {8{regs[12][0] & ~regs[12][1]}};

    assign epc = regs[14];

    // read: combinational logic
    assign rd = regs_nxt[ra];

endmodule