`include"common.svh"
`include"mycpu/type.svh"

module Win(
    input logic clk,resetn, StallW, FlushW,
    input addr_t PCM,
    input logic RegWriteM, MemtoRegM,
    input word_t ALUOutM,
    input regidx_t WriteRegM,
    input dbus_resp_t dresp,

    output addr_t PCW,
    output logic RegWriteW, MemtoRegW,
    output word_t ALUOutW,
    output regidx_t WriteRegW,
    output dbus_resp_t ReadDataW
);
    always_ff @(posedge clk) begin
        if(~resetn|FlushW) begin
            PCW<=32'hbfc00000;
            RegWriteW<='0;
            MemtoRegW<='0;
            ALUOutW<='0;
            WriteRegW<='0; 
            ReadDataW<='0;
        end
        else if(~StallW) begin
            PCW<=PCM;
            RegWriteW<=RegWriteM;
            MemtoRegW<=MemtoRegM;
            ALUOutW<=ALUOutM;
            WriteRegW<=WriteRegM;  
            ReadDataW<=dresp; 
        end
    end
endmodule