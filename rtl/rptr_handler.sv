`timescale 1ns/1ps

module rptr_handler #(
    parameter WIDTH = 4
)(
    input logic                 rclk,
    input logic                 r_en,
    input logic                 rrst_n,
    input logic [WIDTH-1:0]     g_wptr_sync,

    output logic                empty,
    output logic                empty_next,
    output logic [WIDTH-1:0]    g_rptr,
    output logic [WIDTH-1:0]    b_rptr
);
    logic [WIDTH-1:0]   b_rptr_internal;
    logic [WIDTH-1:0]   b_rptr_next;
    logic [WIDTH-1:0]   g_rptr_next;

    assign b_rptr_next = (r_en && !empty)? b_rptr_internal + 1'b1 : b_rptr_internal;
    assign g_rptr_next =  b_rptr_next ^ (b_rptr_next >> 1);

    always_ff @(posedge rclk, negedge rrst_n) begin
        if(~rrst_n) begin
            b_rptr_internal <= '0;  
            b_rptr          <= '0;  
            g_rptr          <= '0;
        end else begin
            b_rptr_internal <= b_rptr_next; 
            b_rptr          <= b_rptr_next; 
            g_rptr          <= g_rptr_next;
        end
    end


    assign empty_next = (g_rptr_next == g_wptr_sync);

    always_ff @(posedge rclk, negedge rrst_n)begin
        if(~rrst_n)begin
            empty <= 1'b1;
        end else begin
            empty <= empty_next;
        end
    end


endmodule




