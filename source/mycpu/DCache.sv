`include "common.svh"

module DCache #(
    parameter int OFFSET_BITS = 2, // 0 ~ 4
    parameter int INDEX_BITS = 2, 
    
    localparam int TAG_BITS = 30 - OFFSET_BITS - INDEX_BITS
)(
    input logic clk, resetn,

    input  dbus_req_t  dreq,
    output dbus_resp_t dresp,
    output cbus_req_t  dcreq,
    input  cbus_resp_t dcresp
);
    /**
     * TODO (Lab3) your code here :)
     */
     // typedefs
    typedef enum{
        IDLE,
        CHECK,
        FLUSH,
        FETCH,
        READY     
    } state_t /* verilator public */;

    typedef logic [TAG_BITS-1:0] tag_t;
    typedef logic [INDEX_BITS-1:0] index_t;
    typedef logic [OFFSET_BITS-1:0] offset_t;
    typedef logic [1:0] position_t;  // cache set 内部的下标

    typedef struct packed {
        tag_t tag;
        logic valid;  // cache line 是否有效？
        logic dirty;  // cache line 是否被写入了？
    } meta_t;
    typedef meta_t [3:0] meta_set_t;

    typedef word_t [(1<<OFFSET_BITS)-1:0] cache_line_t;
    typedef cache_line_t [3:0] cache_set_t;

    // 存储单元（寄存器）
    meta_set_t [(1<<INDEX_BITS)-1:0] meta;
    /* verilator tracing_off */
    cache_set_t [(1<<INDEX_BITS)-1:0] data /* verilator public_flat_rd */;
    /* verilator tracing_on */

    // registers
    state_t    state;
    dbus_req_t req;  // dreq is saved once addr_ok is asserted.
    word_t mask;

    assign mask = {{8{req.strobe[3]}}, {8{req.strobe[2]}}, {8{req.strobe[1]}}, {8{req.strobe[0]}}};

    // 解析地址
    tag_t tag;
    index_t index;
    offset_t offset;
    assign {tag, index, offset} = req.addr[31:2];

    // wires
    offset_t cur, cur_nxt;
    assign cur_nxt = cur + 2'b01;

    // 访问元数据
    meta_set_t foo;
    assign foo = meta[index];

    // 搜索 cache line
    position_t position;
    logic hit;
    always_comb begin
        position = 2'b00;  // 防止出现锁存器
        hit='1;
        if (foo[0].valid && foo[0].tag == tag)
            position = 2'b00;
        else if (foo[1].valid && foo[1].tag == tag)
            position = 2'b01;
        else if (foo[2].valid && foo[2].tag == tag)
            position = 2'b10;
        else if (foo[3].valid && foo[3].tag == tag)
            position = 2'b11;
        else hit='0;
    end

    // visit data
    cache_set_t coo;
    assign coo=data[index];

    // reorder cache line
    meta_set_t foo_nxt;
    cache_set_t coo_nxt;
    always_comb begin
        foo_nxt=foo;
        coo_nxt=coo;
        unique case(position)
            2'b00: begin
                foo_nxt[0]=foo[1];
                foo_nxt[1]=foo[2];
                foo_nxt[2]=foo[3];
                foo_nxt[3]=foo[0];
                coo_nxt[0]=coo[1];
                coo_nxt[1]=coo[2];
                coo_nxt[2]=coo[3];
                coo_nxt[3]=coo[0];
            end
            2'b01: begin
                foo_nxt[1]=foo[2];
                foo_nxt[2]=foo[3];
                foo_nxt[3]=foo[1];
                coo_nxt[1]=coo[2];
                coo_nxt[2]=coo[3];
                coo_nxt[3]=coo[1];
            end
            2'b10: begin
                foo_nxt[2]=foo[3];
                foo_nxt[3]=foo[2];
                coo_nxt[2]=coo[3];
                coo_nxt[3]=coo[2];
            end
            default:;
        endcase
    end

    // 访问 cache line
    cache_line_t bar;
    assign bar = coo[3];
    word_t bar_data;
    assign bar_data = bar[cur];  // 4 字节对齐

    // DBus driver
    assign dresp.addr_ok = state == IDLE;
    assign dresp.data_ok = state == READY;
    assign dresp.data    = bar_data;

    // CBus driver
    assign dcreq.valid    = state == FLUSH || state == FETCH;
    assign dcreq.is_write = state == FLUSH;
    assign dcreq.size     = MSIZE4;
    assign dcreq.addr     = {(state == FLUSH) ? foo[3].tag : tag, index, {(OFFSET_BITS+2){1'b0}}};
    assign dcreq.strobe   = 4'b1111;
    assign dcreq.data     = bar_data;
    always_comb begin
        unique case(OFFSET_BITS)
            0: dcreq.len = MLEN1;
            1: dcreq.len = MLEN2;
            2: dcreq.len = MLEN4;
            3: dcreq.len = MLEN8;
            4: dcreq.len = MLEN16;
            default: dcreq.len= MLEN4;
        endcase
    end

    //the FSM
    always_ff @(posedge clk)
    if (resetn) begin
        unique case (state)
            IDLE: if (dreq.valid) begin
                state  <= CHECK;
                req    <= dreq; // save info
            end

            CHECK: begin
                meta[index] <= foo_nxt;
                data[index] <= coo_nxt; // reorder cache line
                if(hit) begin
                    state <= READY;
                    cur   <= offset;
                end
                else if(foo[position].dirty) begin
                    state <= FLUSH;
                    cur   <= '0;
                end 
                else begin
                    state <= FETCH;
                    cur   <= '0;
                end
            end

            FLUSH: if (dcresp.ready) begin // cache -> mem
                if(dcresp.last) begin
                    state  <=  FETCH;
                    cur    <=  '0;    
                end
                else cur <= cur_nxt;
            end

            FETCH: if (dcresp.ready) begin // mem -> cache
                data[index][3][cur] <= dcresp.data;
                if(dcresp.last) begin
                    meta[index][3].tag <= tag;
                    meta[index][3].valid <= '1;
                    meta[index][3].dirty <= '0;
                    state  <= READY; 
                    cur    <= offset;   
                end
                else cur <= cur_nxt;
            end

            READY: begin // cache <-> cpu
                if(|req.strobe) begin
                    data[index][3][cur] <= (req.data & mask) | (coo[3][cur] & ~mask);
                    meta[index][3].dirty <= '1;
                end
                state <= IDLE;
            end
            default:;
        endcase
    end else begin
        meta <= '0;
        data <= '0;
        state <= IDLE;
        req <= '0;
        cur <= '0;
    end

    `UNUSED_OK({req.valid, req.size});
    // remove following lines when you start
    /*
    assign {dresp, dcreq} = '0;
    `UNUSED_OK({clk, resetn, dreq, dcresp});
    */

endmodule
