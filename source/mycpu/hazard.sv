`include"mycpu/defs.svh"

module hazard(
    output logic StallF, FlushF,

    input regidx_t RsD, RtD,
    output logic StallD, FlushD,
    output logic [1:0] ForwardAD, ForwardBD,

    input regidx_t WriteRegE, RsE, RtE,
    input logic MemtoRegE, RegWriteE, 
    output logic StallE, FlushE,
    output logic [1:0] ForwardAE, ForwardBE,

    input regidx_t WriteRegM, RtM,
    input logic MemtoRegM, RegWriteM, MemWriteM,
    output logic StallM, FlushM, ForwardM,

    input regidx_t WriteRegW,
    input logic RegWriteW,
    output logic StallW, FlushW,

    input logic i_data_ok, d_data_ok,

    input logic done, willmult,
    
    input logic ex_or_eret
);
    always_comb begin
        StallF='0;
        FlushF='0;
        StallD='0;
        FlushD='0;
        StallE='0;
        FlushE='0;
        StallM='0;
        FlushM='0;
        StallW='0;
        FlushW='0;

        /*Flush W*/
        if(~d_data_ok) begin
            FlushW = '1;
            StallM = '1;
            StallE = '1;
            StallD = '1;
            StallF = '1;
        end
        /*Flush M*/
        else if(~i_data_ok && ex_or_eret) begin
            FlushM='1;
            StallE='1;
            StallD='1;
            StallF='1;
        end
        /*Flush M,E,D*/
        else if(ex_or_eret) begin
            FlushM = '1;
            FlushE = '1;
            FlushD = '1;
        end
        /*Flush M*/
        else if(RegWriteM && MemtoRegM && (WriteRegM==RsE|| WriteRegM==RtE) || ~done) begin
            FlushM='1;
            StallE='1;
            StallD='1;
            StallF='1;
        end
        /*Flush E*/
        else if(~i_data_ok) begin
            FlushE='1;
            StallD='1;
            StallF='1;
        end
        else if(RegWriteM && MemtoRegM && (WriteRegM==RsD|| WriteRegM==RtD)) begin
            FlushE='1;
            StallD='1;
            StallF='1;
        end
        else if(RegWriteE && MemtoRegE && (WriteRegE==RsD|| WriteRegE==RtD)) begin
            FlushE='1;
            StallD='1;
            StallF='1;
        end
        else if(RegWriteW && (WriteRegW==RsD|| WriteRegW==RtD) && willmult) begin
            FlushE='1;
            StallD='1;
            StallF='1;
        end        
        else if(RegWriteM && ~MemtoRegM && (WriteRegM==RsD|| WriteRegM==RtD) && willmult) begin
            FlushE='1;
            StallD='1;
            StallF='1;
        end
        else if(RegWriteE && ~MemtoRegE && (WriteRegE==RsD|| WriteRegE==RtD) && willmult) begin
            FlushE='1;
            StallD='1;
            StallF='1;
        end
    end
    
    always_comb begin 
        ForwardAD=2'b0;
        ForwardBD=2'b0;
        ForwardAE=2'b0;
        ForwardBE=2'b0;
        ForwardM='0;
        /*M*/
        if(RegWriteW && MemWriteM && WriteRegW==RtM) begin
            ForwardM='1;
        end
        /*E*/
        if(RegWriteW && (WriteRegW==RsE|| WriteRegW==RtE)) begin
            if(WriteRegW==RsE) ForwardAE=2'b1;
            if(WriteRegW==RtE) ForwardBE=2'b1;
        end
        if(RegWriteM && ~MemtoRegM && (WriteRegM==RsE|| WriteRegM==RtE)) begin
            if(WriteRegM==RsE) ForwardAE=2'b10;
            if(WriteRegM==RtE) ForwardBE=2'b10;
        end
        /*D*/
        if(RegWriteW && (WriteRegW==RsD|| WriteRegW==RtD)) begin
            if(WriteRegW==RsD) ForwardAD=2'b1;
            if(WriteRegW==RtD) ForwardBD=2'b1;
        end        
        if(RegWriteM && ~MemtoRegM && (WriteRegM==RsD|| WriteRegM==RtD)) begin
            if(WriteRegM==RsD) ForwardAD=2'b10;
            if(WriteRegM==RtD) ForwardBD=2'b10;
        end
        if(RegWriteE && ~MemtoRegE && (WriteRegE==RsD|| WriteRegE==RtD)) begin
            if(WriteRegE==RsD) ForwardAD=2'b11;
            if(WriteRegE==RtD) ForwardBD=2'b11;
        end
    end
endmodule