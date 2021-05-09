`include "access.svh"
`include "common.svh"

module VTop (
    input logic clk, resetn,

    output cbus_req_t  oreq,
    input  cbus_resp_t oresp,

    input i6 ext_int
);
    `include "bus_decl"

    ibus_req_t  ireq, ipreq;
    ibus_resp_t iresp;
    dbus_req_t  dreq, dpreq;
    dbus_resp_t dresp;
    cbus_req_t  icreq,  dcreq;
    cbus_resp_t icresp, dcresp;

    always_comb begin
        ipreq = ireq;
        if(ireq.addr[31:30] == 2'b10) ipreq.addr[31:29] = 3'b000;
        dpreq = dreq;
        if(dreq.addr[31:30] == 2'b10) dpreq.addr[31:29] = 3'b000;
    end

    MyCore core(.*);
    ibus_req_t  [1:0] mux_ireq;
    ibus_resp_t [1:0] mux_iresp;
    dbus_req_t  [1:0] mux_dreq;
    dbus_resp_t [1:0] mux_dresp;
    cbus_req_t  [1:0] mux_icreq, mux_dcreq;
    cbus_resp_t [1:0] mux_icresp, mux_dcresp;

    always_comb begin
        mux_dreq = '0;
        mux_dcresp = '0;

        if (dreq.addr[31:29] == 3'b101) begin
            mux_dreq[1] = dpreq;
            dresp = mux_dresp[1];
            dcreq = mux_dcreq[1];
            mux_dcresp[1] = dcresp;
        end else begin
            mux_dreq[0] = dpreq;
            dresp = mux_dresp[0];
            dcreq = mux_dcreq[0];
            mux_dcresp[0] = dcresp;
        end
    end

    always_comb begin
        mux_ireq = '0;
        mux_icresp = '0;

        if (ireq.addr[31:29] == 3'b101) begin
            mux_ireq[1] = ipreq;
            iresp = mux_iresp[1];
            icreq = mux_icreq[1];
            mux_icresp[1] = icresp;
        end else begin
            mux_ireq[0] = ipreq;
            iresp = mux_iresp[0];
            icreq = mux_icreq[0];
            mux_icresp[0] = icresp;
        end
    end

    DCache dcvt0(
        .dreq(mux_dreq[0]),
        .dresp(mux_dresp[0]),
        .dcreq(mux_dcreq[0]),
        .dcresp(mux_dcresp[0]),
        .*
    );
    DBusToCBus dcvt1(
        .dreq(mux_dreq[1]),
        .dresp(mux_dresp[1]),
        .dcreq(mux_dcreq[1]),
        .dcresp(mux_dcresp[1]),
        .*
    );
    ICache icvt0(
        .ireq(mux_ireq[0]),
        .iresp(mux_iresp[0]),
        .icreq(mux_icreq[0]),
        .icresp(mux_icresp[0]),
        .*
    );
    IBusToCBus icvt1(
        .ireq(mux_ireq[1]),
        .iresp(mux_iresp[1]),
        .icreq(mux_icreq[1]),
        .icresp(mux_icresp[1]),
        .*
    );

    /**
     * TODO (Lab2) replace mux with your own arbiter :)
     */
    CBusArbiter mux(
        .ireqs({icreq, dcreq}),
        .iresps({icresp, dcresp}),
        .*
    );

    /**
     * TODO (optional) add address translation for oreq.addr :)
     */

    `UNUSED_OK({ext_int});
endmodule
