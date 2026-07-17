`timescale 1ns/1ps

module axi4_lite_fifo_wbridge_2 #(
    parameter DATA_WIDTH = 32
)(
    // AXI4-Lite clock and reset
    input  logic                    s_axi_aclk,
    input  logic                    s_axi_aresetn,

    // AXI4-Lite Write Address Channel (aw)
    input  logic [31:0]             s_axi_awaddr,
    input  logic                    s_axi_awvalid,
    output logic                    s_axi_awready,

    // AXI4-Lite Write Data (w)
    input  logic [DATA_WIDTH-1:0]   s_axi_wdata,
    input  logic [3:0]              s_axi_wstrb,
    input  logic                    s_axi_wvalid,
    output logic                    s_axi_wready,

    // AXI4-Lite Response (B)
    output logic [1:0]              s_axi_bresp,
    output logic                    s_axi_bvalid,
    input  logic                    s_axi_bready,

    // With FIFO
    output logic                    fifo_w_en,
    output logic [DATA_WIDTH-1:0]   fifo_w_data,
    input  logic                    fifo_full
);
    localparam ADDR_FIFO_DATA = 3'd0;

    typedef enum logic {
        W_IDLE = 1'b0,
        W_RESP = 1'b1
    } axi_w_state_t;

    axi_w_state_t state;

    assign s_axi_awready = (state == W_IDLE) && !fifo_full;
    assign s_axi_wready  = (state == W_IDLE) && !fifo_full;

    always_ff @(posedge s_axi_aclk, negedge s_axi_aresetn) begin
        if(!s_axi_aresetn) begin
            state        <= W_IDLE;
            s_axi_bresp  <= 2'b00;
            s_axi_bvalid <= 1'b0;
            fifo_w_en    <= 1'b0;
            fifo_w_data  <= '0;
        end else begin
            fifo_w_en <= 1'b0;

            case(state)
                W_IDLE: begin
                    if(s_axi_awvalid && s_axi_wvalid && !fifo_full) begin
                        if(s_axi_awaddr[4:2] == ADDR_FIFO_DATA) begin
                            fifo_w_en   <= 1'b1;
                            fifo_w_data <= s_axi_wdata;
                            s_axi_bresp <= 2'b00;
                        end else begin
                            s_axi_bresp <= 2'b10;
                        end
                        s_axi_bvalid    <= 1'b1;
                        state           <= W_RESP;
                    end
                end

                W_RESP: begin
                    fifo_w_en           <= 1'b0;
                    if(s_axi_bready && s_axi_bvalid) begin
                        s_axi_bvalid    <= 1'b0;
                        state           <= W_IDLE;
                    end
                end

                default: state <= W_IDLE;
            endcase
        end
    end

endmodule