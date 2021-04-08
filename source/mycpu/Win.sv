`include"common.svh"
`include"mycpu/type.svh"

module Win(
    input logic clk,resetn, StallW, FlushW,
    input addr_t PCM,
    input logic RegWriteM, MemtoRegM,
    input msize_t SizeM,
    input logic SignedM,
    input word_t ALUOutM,
    input regidx_t WriteRegM,
    input dbus_resp_t dresp,

    output addr_t PCW,
    output logic RegWriteW, MemtoRegW,
    output msize_t SizeW,
    output logic SignedW,
    output word_t ALUOutW,
    output regidx_t WriteRegW,
    output dbus_resp_t dresp_nxt
);
    always_ff @(posedge clk) begin
        if(~resetn|FlushW) begin
            PCW<=32'hbfc00000;
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