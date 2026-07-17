
module axi4_lite_fifo_rbridge #(
    parameter DATA_WIDTH = 32
)(
    // AXI4-Lite clock and reset
    input  logic                    s_axi_aclk,
    input  logic                    s_axi_aresetn,
    
    // AXI4-Lite Read Address Channel (ar)
    input  logic [31:0]             s_axi_araddr,
    input  logic                    s_axi_arvalid,
    output logic                    s_axi_arready,

    // AXI4-Lite Read Data (r)
    output logic [DATA_WIDTH-1:0]   s_axi_rdata,
    output logic [1:0]              s_axi_rresp,    // OKAY: 00
    output logic                    s_axi_rvalid,
    input  logic                    s_axi_rready, 

    // FIFO
    output logic                    fifo_r_en,
    input  logic [DATA_WIDTH-1:0]   fifo_r_data,
    input  logic                    fifo_empty
);
    localparam ADDR_FIFO_DATA = 3'd0;

    typedef enum logic [1:0] {
        R_IDLE = 2'b00,
        R_DATA = 2'b01
    } axi_r_state_t;

    axi_r_state_t state;
    logic [31:0] araddr_reg;
    logic        fifo_empty_reg;

    always_ff @(posedge s_axi_aclk, negedge s_axi_aresetn) begin
        if(!s_axi_aresetn) begin
            state           <= R_IDLE;
            s_axi_arready   <= 1'b0;
            s_axi_rdata     <= '0;
            s_axi_rresp     <= 2'b00;
            s_axi_rvalid    <= 1'b0;
            fifo_r_en       <= 1'b0;
            araddr_reg      <= '0;
            fifo_empty_reg  <= 1'b0;
        end else begin
            fifo_r_en       <= 1'b0;

            case(state)
                // IDLE
                R_IDLE: begin
                    if(s_axi_arvalid) begin
                        s_axi_arready   <= 1'b1;
                        araddr_reg      <= s_axi_araddr;
                        state           <= R_DATA;
                        fifo_empty_reg  <= fifo_empty;
                        if(s_axi_araddr[4:2] == ADDR_FIFO_DATA && !fifo_empty) begin
                            fifo_r_en   <= 1'b1;
                        end
                    end
                end

                // DATA
                R_DATA: begin
                    s_axi_arready       <= 1'b0;
                    if (s_axi_rvalid && s_axi_rready) begin
                        s_axi_rvalid <= 1'b0;
                        state        <= R_IDLE;
                    end else begin
                        s_axi_rvalid <= 1'b1; 
                    end

                    if (fifo_r_en == 1'b1) begin
                        fifo_r_en <= 1'b0;
                    end

                    if (s_axi_rvalid == 1'b0) begin
                        if (araddr_reg[4:2] == ADDR_FIFO_DATA && fifo_empty_reg == 1'b0) begin  // Valid read
                            s_axi_rdata <= fifo_r_data; 
                            s_axi_rresp <= 2'b00;       
                        end else begin
                            s_axi_rdata <= 32'hDEAD_BEEF;
                            s_axi_rresp <= 2'b10;       
                        end
                    end
                end
                default: state <= R_IDLE;
            endcase
        end
    end


endmodule