`timescale 1ns/1ps

module sync_STAGES #(
    parameter WIDTH = 4,
    parameter STAGES = 2
)(
    input   logic clk,
    input   logic reset_n,
    input   logic [WIDTH-1:0] data_in,
    output  logic [WIDTH-1:0] data_out
);

    logic [WIDTH-1:0] sync_reg [0:STAGES-1];

    genvar i;

    generate
        for(i = 0; i < STAGES; i = i + 1)begin: sync_update
            if(i == 0) begin: gen_first
                always_ff @(posedge clk, negedge reset_n) begin
                    if(!reset_n)    sync_reg[0] <= '0;
                    else            sync_reg[0] <= data_in;
                end
            end else begin: gen_next
                always_ff @(posedge clk, negedge reset_n) begin
                    if(!reset_n)    sync_reg[i] <= '0;
                    else            sync_reg[i] <= sync_reg[i-1];
                end
            end
        end
    endgenerate

    assign data_out = sync_reg[STAGES-1];

endmodule