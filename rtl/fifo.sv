`timescale 1ns/1ps

module fifo #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 3    // 1 fewer bit than pointer
)(
    input logic                     wclk,
    input logic                     w_en,
    input logic                     full,
    input logic [ADDR_WIDTH-1:0]    waddr,
    input logic [ADDR_WIDTH-1:0]    raddr,
    input logic [DATA_WIDTH-1:0]    data_in,

    output logic [DATA_WIDTH-1:0]   data_out
);
    localparam DEPTH = 1 << ADDR_WIDTH; // 2^3
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    always_ff @(posedge wclk) begin
        if(!full && w_en) begin
            mem[waddr] <= data_in;
        end
    end

    assign data_out = mem[raddr];

endmodule