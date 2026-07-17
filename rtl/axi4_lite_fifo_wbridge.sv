`timescale 1ns/1ps

module axi4_lite_fifo_wbridge #(
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
    output logic                    s_axi_wready,  // To master

    // AXI4-Lite Response (B)
    output logic [1:0]              s_axi_bresp,    // OKAY: 00
    output logic                    s_axi_bvalid, 
    input  logic                    s_axi_bready,   // From master

    // With FIFO
    output logic                    fifo_w_en,
    output logic [DATA_WIDTH-1:0]   fifo_w_data,
    input  logic                    fifo_full
);
    localparam ADDR_FIFO_DATA = 3'd0;

    typedef enum logic [1:0] {
        W_IDLE = 2'b00,
        W_PUSH = 2'b01,
        W_RESP = 2'b10
    } axi_w_state_t;

    axi_w_state_t state;
    logic [31:0]            awaddr_reg;
    logic [DATA_WIDTH-1:0]  data_reg;

    logic                   aw_val_saved;
    logic                   w_val_saved;

    always_ff @(posedge s_axi_aclk, negedge s_axi_aresetn) begin
        if(!s_axi_aresetn) begin
            state <= W_IDLE;
            s_axi_awready   <= 1'b0;
            s_axi_wready    <= 1'b0;
            s_axi_bresp     <= 2'b00;
            s_axi_bvalid    <= 1'b0;
            fifo_w_en       <= 1'b0;
            fifo_w_data     <= '0; 
            awaddr_reg      <= '0;
            data_reg        <= '0;
            aw_val_saved    <= 1'b0;
            w_val_saved     <= 1'b0;
        end else begin
            fifo_w_en <= 1'b0;

            case(state)
                //   IDLE
                W_IDLE: begin
                    if ((s_axi_awvalid || aw_val_saved) && !fifo_full) begin
                        if (!aw_val_saved) begin
                            awaddr_reg   <= s_axi_awaddr;
                            aw_val_saved <= 1'b1;
                        end
                    end

                    if ((s_axi_wvalid || w_val_saved) && !fifo_full) begin
                        if (!w_val_saved) begin
                            data_reg    <= s_axi_wdata;
                            w_val_saved <= 1'b1;
                        end
                    end
                    if ((s_axi_awvalid || aw_val_saved) && (s_axi_wvalid || w_val_saved) && !fifo_full) begin
                        s_axi_awready   <= 1'b1;
                        s_axi_wready    <= 1'b1;
                        w_val_saved     <= 1'b0;
                        aw_val_saved    <= 1'b0;
                        state           <= W_PUSH;
                    end
                end

                // PUSH
                W_PUSH: begin
                    s_axi_awready       <= 1'b0;
                    s_axi_wready        <= 1'b0;

                    if(awaddr_reg[4:2] == ADDR_FIFO_DATA) begin
                        fifo_w_en       <= 1'b1;
                        fifo_w_data     <= data_reg;
                        s_axi_bresp     <= 2'b00;
                    end else begin
                        s_axi_bresp     <= 2'b10;
                    end

                    s_axi_bvalid        <= 1'b1;
                    state               <= W_RESP;
                end

                // Respond
                W_RESP: begin
                    if(s_axi_bready && s_axi_bvalid) begin
                        s_axi_bvalid    <= 1'b0;
                        state           <= W_IDLE;
                    end
                end

                default: state          <= W_IDLE;
            endcase
        end
    end

endmodule