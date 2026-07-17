`timescale 1ns/1ps

module wptr_handler #(
    parameter WIDTH = 4
)(
    input logic                 wclk,
    input logic                 w_en,
    input logic                 wrst_n,
    input logic     [WIDTH-1:0] g_rptr_sync,

    output logic    [WIDTH-1:0] b_wptr,
    output logic    [WIDTH-1:0] g_wptr,
    output logic                full_next,
    output logic                full   
);

    logic [WIDTH-1:0]   b_wptr_next;
    logic [WIDTH-1:0]   g_wptr_next;

    // Pointer update
    assign b_wptr_next = (w_en && ~full)? b_wptr + 1'b1 : b_wptr;
    assign g_wptr_next = b_wptr_next ^ (b_wptr_next >> 1);  // Convert binary to grey code

    always_ff @(posedge wclk, negedge wrst_n)begin
        if(~wrst_n)begin
            b_wptr <= '0;
            g_wptr <= '0;
        end else begin
            b_wptr <= b_wptr_next;
            g_wptr <= g_wptr_next;
        end
    end

    // Full logic (first two bits not equal, the rest equal)
    assign full_next = (g_wptr_next[WIDTH-1] != g_rptr_sync[WIDTH-1] && g_wptr_next[WIDTH-2] != g_rptr_sync[WIDTH-2]
                            && g_wptr_next[WIDTH-3:0] == g_rptr_sync[WIDTH-3:0]);

    always_ff @(posedge wclk, negedge wrst_n)begin
        if(~wrst_n)
            full <= '0;
        else
            full <= full_next;
    end

endmodule