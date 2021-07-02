`include"mycpu/defs.svh"

module Win(
    input logic clk,resetn, StallW, FlushW,
    /*PC*/
    input addr_t PCM,
    output addr_t PCW,

    //signals
    input logic RegWriteM, MemtoRegM,
    output logic RegWriteW, MemtoRegW,
    input msize_t SizeM,
    output msize_t SizeW,
    input logic SignedM,
    output logic SignedW,


    input word_t ALUOutM,
    output word_t ALUOutW,
    input regidx_t WriteRegM,
    output regidx_t WriteRegW,
    
    input dbus_resp_t dresp,
    output dbus_resp_t dresp_nxt
);
    always_ff @(posedge clk) begin
        if(~resetn|FlushW) begin
            PCW<='0;
            RegWriteW<='0;
            MemtoRegW<='0;
            SizeW<=MSIZE4;
            SignedW<='0;
            ALUOutW<='0;
            WriteRegW<='0; 
            dresp_nxt<='0;
        end
        else if(~StallW) begin
            PCW<=PCM;
            RegWriteW<=RegWriteM;
            MemtoRegW<=MemtoRegM;
            SizeW<=SizeM;
            SignedW<=SignedM;
            ALUOutW<=ALUOutM;
            WriteRegW<=WriteRegM;  
            dresp_nxt<=dresp; 
        end
    end
endmodule