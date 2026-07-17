

module axi4_lite_fifo_top #(
    parameter DATA_WIDTH = 32,
    parameter WIDTH = 4,
    parameter STAGES = 2
)(
    //
    // Write Domain
    //
    input  logic                    wclk,
    input  logic                    wrst_n,

    // AXI4-Lite Write Address (aw)
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

    //
    // Read Domain
    //
    input  logic                    rclk,
    input  logic                    rrst_n,

    // AXI4-Lite Read Address (ar)
    input  logic [31:0]             s_axi_araddr,
    input  logic                    s_axi_arvalid,
    output logic                    s_axi_arready,

    // AXI4-Lite Read Data (r)
    output logic [DATA_WIDTH-1:0]   s_axi_rdata,
    output logic [1:0]              s_axi_rresp,    // OKAY: 00
    output logic                    s_axi_rvalid,
    input  logic                    s_axi_rready
);

    logic                   int_w_en;
    logic                   int_r_en;
    logic [DATA_WIDTH-1:0]  int_w_data;
    logic [DATA_WIDTH-1:0]  int_r_data;
    logic                   int_full;
    logic                   int_empty;

    // For debug
    logic                   full_next;
    logic                   empty_next;


    axi4_lite_fifo_wbridge #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_wbridge(
        .s_axi_aclk     (wclk),
        .s_axi_aresetn  (wrst_n),
        .s_axi_awaddr   (s_axi_awaddr),
        .s_axi_awvalid  (s_axi_awvalid),
        .s_axi_awready  (s_axi_awready),
        .s_axi_wdata    (s_axi_wdata),
        .s_axi_wstrb    (s_axi_wstrb),
        .s_axi_wvalid   (s_axi_wvalid),
        .s_axi_wready   (s_axi_wready),
        .s_axi_bresp    (s_axi_bresp),
        .s_axi_bvalid   (s_axi_bvalid),
        .s_axi_bready   (s_axi_bready),
        .fifo_w_en      (int_w_en),
        .fifo_w_data    (int_w_data),
        .fifo_full      (int_full)    
    );

    axi4_lite_fifo_rbridge #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_rbridge(
        .s_axi_aclk(rclk),
        .s_axi_aresetn(rrst_n),
        .s_axi_araddr   (s_axi_araddr),
        .s_axi_arvalid  (s_axi_arvalid),
        .s_axi_arready  (s_axi_arready),
        .s_axi_rdata    (s_axi_rdata),
        .s_axi_rresp    (s_axi_rresp),
        .s_axi_rvalid   (s_axi_rvalid),
        .s_axi_rready   (s_axi_rready),
        .fifo_r_en      (int_r_en),
        .fifo_r_data    (int_r_data),
        .fifo_empty     (int_empty)
    );

    top #(
        .DATA_WIDTH(DATA_WIDTH),
        .WIDTH(WIDTH),
        .STAGES(STAGES)
    ) u_fifo_core(
        .wclk(wclk),
        .rclk(rclk),
        .w_en(int_w_en),
        .r_en(int_r_en),
        .data_in(int_w_data),
        .wrst_n(wrst_n),
        .rrst_n(rrst_n),

        .data_out(int_r_data),
        .full(int_full),
        .empty(int_empty),
        .full_next(full_next),
        .empty_next(empty_next)
    );

endmodule