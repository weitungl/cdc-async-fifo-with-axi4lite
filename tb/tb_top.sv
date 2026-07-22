// Code your testbench here
// or browse Examples
`timescale 1ns/1ps

`include "fifo_if.sv"
`include "fifo_pkg.sv"
`include "fifo_assertion.sv"
import fifo_pkg::*;

module  testbench;
    logic wclk;
    logic rclk;
    logic wrst_n;
    logic rrst_n;

    initial begin
        wclk = 0;
        forever #8.3 wclk = ~wclk;
    end
    
    initial begin
        rclk = 0;
        forever #6.5 rclk = ~rclk;
    end
    // Instantiate an interface
    fifo_if #(32) intf(wclk, rclk, wrst_n, rrst_n);

    axi4_lite_fifo_top #(
        .DATA_WIDTH(32),
        .WIDTH(4),
        .STAGES(2)
    ) dut(
        // Write
        .wclk(wclk),
        .wrst_n(wrst_n),
        .s_axi_awaddr(intf.s_axi_awaddr),
        .s_axi_awvalid(intf.s_axi_awvalid),
        .s_axi_awready(intf.s_axi_awready),
        .s_axi_wdata(intf.s_axi_wdata),
        .s_axi_wstrb(intf.s_axi_wstrb),
        .s_axi_wvalid(intf.s_axi_wvalid),
        .s_axi_wready(intf.s_axi_wready),
        .s_axi_bresp(intf.s_axi_bresp),
        .s_axi_bvalid(intf.s_axi_bvalid),
        .s_axi_bready(intf.s_axi_bready),
        // Read
        .rclk(rclk),
        .rrst_n(rrst_n),
        .s_axi_araddr(intf.s_axi_araddr),
        .s_axi_arvalid(intf.s_axi_arvalid),
        .s_axi_arready(intf.s_axi_arready),
        .s_axi_rdata(intf.s_axi_rdata),
        .s_axi_rresp(intf.s_axi_rresp),
        .s_axi_rvalid(intf.s_axi_rvalid),
        .s_axi_rready(intf.s_axi_rready)
    );
    
    fifo_env #(32) env;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, testbench);
        // Reset
        wrst_n = 1'b0;
        rrst_n = 1'b0;

        repeat(3) @(posedge wclk);
        wrst_n = 1'b1;
        repeat(3) @(posedge rclk);
        rrst_n = 1'b1;

        # 20;

        env = new(intf,100, "READ_WRITE"); // RANDOM, WRITE_ONLY, READ_BACK, READ_WRITE
        env.run();
        $display("Simulation Finished");
        $finish;
    end
    
endmodule

