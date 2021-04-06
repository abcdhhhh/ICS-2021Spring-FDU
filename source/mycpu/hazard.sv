`include"common.svh"
`include"mycpu/type.svh"

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

    input logic i_data_ok, d_data_ok
);
    always_comb begin
        StallF=~i_data_ok|~d_data_ok;
        FlushF='0;
        StallD=~i_data_ok|~d_data_ok;
        FlushD='0;
        StallE=~d_data_ok;
        FlushE=~i_data_ok;
        StallM=~d_data_ok;
        FlushM='0;
        StallW='0;
        FlushW=~d_data_ok;
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
        if(RegWriteM && MemtoRegM && (WriteRegM==RsE|| WriteRegM==RtE)) begin
            FlushM='1;
            StallE='1;
            StallD='1;
            StallF='1;
        end
        else begin
            if(RegWriteW && (WriteRegW==RsE|| WriteRegW==RtE)) begin
                if(WriteRegW==RsE) ForwardAE=2'b1;
                if(WriteRegW==RtE) ForwardBE=2'b1;
            end
            if(RegWriteM && ~MemtoRegM && (WriteRegM==RsE|| WriteRegM==RtE)) begin
                if(WriteRegM==RsE) ForwardAE=2'b10;
                if(WriteRegM==RtE) ForwardBE=2'b10;
            end
            /*D*/
            if(RegWriteM && MemtoRegM && (WriteRegM==RsD|| WriteRegM==RtD)) begin
                FlushE='1;
                StallD='1;
                StallF='1;
            end
            else if(RegWriteE && MemtoRegE && (WriteRegE==RsD|| WriteRegE==RtD)) begin
                FlushE='1;
                StallD='1;
                StallF='1;
            end
            else begin
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
        end
    end
endmodule