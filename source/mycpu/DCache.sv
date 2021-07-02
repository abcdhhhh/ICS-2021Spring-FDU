`include "common.svh"

module DCache #(
    parameter int OFFSET_BITS = 4, // 0 ~ 4
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
        FLUSH,
        FETCH,
        READY     
    } state_t;

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

    typedef position_t [3:0] order_set_t;

    // 存储单元（寄存器）
    order_set_t [(1<<INDEX_BITS)-1:0] order;
    meta_set_t [(1<<INDEX_BITS)-1:0] meta;
    logic [(1<<(INDEX_BITS+2))-1:0] ram_en;
    strobe_t ram_strobe;
    word_t ram_wdata;
    word_t [(1<<(INDEX_BITS+2))-1:0] ram_rdata;

    // registers
    state_t    state;
    dbus_req_t req;  // dreq is saved once addr_ok is asserted.

    // 解析地址
    tag_t tag;
    index_t index;
    offset_t offset;
    assign {tag, index, offset} = (state == IDLE) ? dreq.addr[31:2] : req.addr[31:2];

    // wires
    offset_t cur, cur_nxt;
    assign cur_nxt = cur + offset_t'(1'b1);

    // 访问元数据
    meta_set_t foo;
    assign foo = meta[index];

    // 搜索 cache line
    position_t position;
    logic hit;
    always_comb begin
        if(state == IDLE) begin
            position = order[index][0];  // oldest used
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
        else begin
            position = order[index][3];  // latest used
        end
    end

    // reorder (during IDLE)
    order_set_t ooo, ooo_nxt;
    assign ooo = order[index];
    always_comb begin
        ooo_nxt = ooo;
        if(position == ooo[0]) begin
            ooo_nxt[0] = ooo[1];
            ooo_nxt[1] = ooo[2];
            ooo_nxt[2] = ooo[3];
            ooo_nxt[3] = ooo[0];
        end
        else if(position == ooo[1]) begin
            ooo_nxt[1] = ooo[2];
            ooo_nxt[2] = ooo[3];
            ooo_nxt[3] = ooo[1];
        end
        else if(position == ooo[2]) begin
            ooo_nxt[2] = ooo[3];
            ooo_nxt[3] = ooo[2];
        end
    end

    //ram
    always_comb begin
        ram_en = '0;
        ram_strobe = '0;
        ram_wdata = '0;
        unique case (state)
            FETCH: begin
                ram_en[{index,position}] = '1;
                ram_strobe = 4'b1111;
                ram_wdata  = dcresp.data;
            end
            READY: begin
                ram_en[{index,position}] = |{req.strobe};
                ram_strobe = req.strobe;
                ram_wdata  = req.data;
            end
            default: ;
        endcase
    end

    genvar gvr_i;
    generate
        for(gvr_i = 0; gvr_i < (1<<(INDEX_BITS+2)); gvr_i++) begin: ram_gen
            LUTRAM ram_inst(
                .clk, .en(ram_en[gvr_i]),
                .addr(cur),
                .strobe(ram_strobe),
                .wdata(ram_wdata),
                .rdata(ram_rdata[gvr_i])
            );
        end
    endgenerate


    // DBus driver
    assign dresp.addr_ok = state == IDLE;
    assign dresp.data_ok = state == READY;
    assign dresp.data    = ram_rdata[{index,position}];

    // CBus driver
    assign dcreq.valid    = state == FLUSH || state == FETCH;
    assign dcreq.is_write = state == FLUSH;
    assign dcreq.size     = MSIZE4;
    assign dcreq.addr     = {(state == FLUSH) ? foo[position].tag : tag, index, {(OFFSET_BITS+2){1'b0}}};
    assign dcreq.strobe   = 4'b1111;
    assign dcreq.data     = ram_rdata[{index,position}];
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
                req    <= dreq; // save info
                // reorder
                order[index] <= ooo_nxt;
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
                if(dcresp.last) begin
                    meta[index][position].tag <= tag;
                    meta[index][position].valid <= '1;
                    meta[index][position].dirty <= '0;
                    state  <= READY; 
                    cur    <= offset;   
                end
                else cur <= cur_nxt;
            end

            READY: begin // cache <-> cpu
                if(|req.strobe) begin
                    meta[index][position].dirty <= '1;
                end
                state <= IDLE;
            end
            default:;
        endcase
    end else begin
        order <= {(1<<INDEX_BITS){8'b00011011}};
        meta <= '0;
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
