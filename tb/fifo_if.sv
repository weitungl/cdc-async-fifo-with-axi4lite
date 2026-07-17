interface fifo_if #(parameter DATA_WIDTH = 32) (
    input logic wclk,
    input logic rclk,
    input logic wrst_n,
    input logic rrst_n
);
    // 
    // Write Domain
    //

    // AW
    logic [31:0]                    s_axi_awaddr;
    logic                           s_axi_awvalid;
    logic                           s_axi_awready;

    // W
    logic [DATA_WIDTH-1:0]          s_axi_wdata;
    logic [3:0]                     s_axi_wstrb;
    logic                           s_axi_wvalid;
    logic                           s_axi_wready; 

    // B
    logic [1:0]                     s_axi_bresp;   
    logic                           s_axi_bvalid; 
    logic                           s_axi_bready;  

    //
    // Read Domain
    //

    // AR
    logic [31:0]                    s_axi_araddr;
    logic                           s_axi_arvalid;
    logic                           s_axi_arready;

    // R
    logic [DATA_WIDTH-1:0]          s_axi_rdata;
    logic [1:0]                     s_axi_rresp;    
    logic                           s_axi_rvalid;
    logic                           s_axi_rready;


endinterface
