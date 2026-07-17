`timescale 1ns/1ps

module top #(
    parameter DATA_WIDTH = 32,
    parameter WIDTH = 4,
    parameter STAGES = 2
)(
    input logic                     wclk,
    input logic                     rclk,
    input logic                     w_en,
    input logic                     r_en,
    input logic [DATA_WIDTH-1:0]    data_in,
    input logic                     wrst_n,
    input logic                     rrst_n,

    output logic [DATA_WIDTH-1:0]   data_out,
    output logic                    full,
    output logic                    full_next,
    output logic                    empty,
    output logic                    empty_next
);

    localparam ADDR_WIDTH = WIDTH - 1;
    logic [ADDR_WIDTH-1:0]  waddr;
    logic [ADDR_WIDTH-1:0]  raddr;
    logic [WIDTH-1:0]       b_wptr;
    logic [WIDTH-1:0]       b_rptr;
    logic [WIDTH-1:0]       g_wptr;
    logic [WIDTH-1:0]       g_rptr;
    logic [WIDTH-1:0]       g_rptr_sync, g_wptr_sync;

    assign waddr = b_wptr[ADDR_WIDTH-1:0];
    assign raddr = b_rptr[ADDR_WIDTH-1:0];

    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) fifo_h(
        // Input
        .wclk(wclk),
        .w_en(w_en),
        .full(full),
        .waddr(waddr),
        .raddr(raddr),
        .data_in(data_in),
        // Output
        .data_out(data_out)
    );

    wptr_handler #(
        .WIDTH(WIDTH)
    ) write_handle_h(
        // Input
        .wclk(wclk),
        .w_en(w_en),
        .wrst_n(wrst_n),
        .g_rptr_sync(g_rptr_sync),
        // Output
        .b_wptr(b_wptr),
        .g_wptr(g_wptr),
        .full(full),
        .full_next(full_next)
    );

    rptr_handler #(
        .WIDTH(WIDTH)
    ) read_handle_h(
        // Input
        .rclk(rclk),
        .r_en(r_en),
        .rrst_n(rrst_n),
        .g_wptr_sync(g_wptr_sync),
        // Output
        .empty(empty),
        .empty_next(empty_next),
        .g_rptr(g_rptr),
        .b_rptr(b_rptr)
    );

    sync_STAGES #(
        .WIDTH(WIDTH),
        .STAGES(STAGES)
    ) sync_r2w(
        .clk(wclk),
        .reset_n(wrst_n),
        .data_in(g_rptr),
        .data_out(g_rptr_sync)
    );

    sync_STAGES #(
        .WIDTH(WIDTH),
        .STAGES(STAGES)
    ) sync_w2r(
        .clk(rclk),
        .reset_n(rrst_n),
        .data_in(g_wptr),
        .data_out(g_wptr_sync)
    );


endmodule






