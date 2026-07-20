set clk_period 5.5

# Clock 1
create_clock -name wclk -period $clk_period [get_ports {wclk}]
set_clock_transition 0.15 [get_clocks {wclk}]
set_clock_uncertainty 0.2 [get_clocks {wclk}]

# 2. Clock 2
create_clock -name rclk -period $clk_period [get_ports {rclk}]
set_clock_transition 0.15 [get_clocks {rclk}]
set_clock_uncertainty 0.2 [get_clocks {rclk}]

set_clock_groups -asynchronous -group [get_clocks {wclk}] -group [get_clocks {rclk}]

set wclk_inputs [list wrst_n s_axi_awaddr s_axi_awvalid s_axi_wdata s_axi_wstrb s_axi_wvalid s_axi_bready]
set wclk_outputs [list s_axi_awready s_axi_wready s_axi_bresp s_axi_bvalid]

set rclk_inputs [list rrst_n s_axi_araddr s_axi_arvalid s_axi_rready]
set rclk_outputs [list s_axi_arready s_axi_rdata s_axi_rresp s_axi_rvalid]

set io_delay [expr $clk_period * 0.3]

set_input_delay $io_delay -clock [get_clocks {wclk}] [get_ports $wclk_inputs]
set_input_delay $io_delay -clock [get_clocks {rclk}] [get_ports $rclk_inputs]
set_output_delay $io_delay -clock [get_clocks {wclk}] [get_ports $wclk_outputs]
set_output_delay $io_delay -clock [get_clocks {rclk}] [get_ports $rclk_outputs]
