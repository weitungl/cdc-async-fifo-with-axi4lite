
module fifo_assertions(
    input logic                    wclk,
    input logic                    wrst_n,
    input logic                    rclk,
    input logic                    rrst_n,

    // AXI (aw / w / b)
    input logic [31:0]             s_axi_awaddr,
    input logic                    s_axi_awvalid,
    input logic                    s_axi_awready,
    input logic [31:0]             s_axi_wdata,   
    input logic [3:0]              s_axi_wstrb,
    input logic                    s_axi_wvalid,
    input logic                    s_axi_wready, 
    input logic [1:0]              s_axi_bresp,    
    input logic                    s_axi_bvalid, 
    input logic                    s_axi_bready,   

    // AXI (ar / r)
    input logic [31:0]             s_axi_araddr,
    input logic                    s_axi_arvalid,
    input logic                    s_axi_arready,
    input logic [31:0]             s_axi_rdata,
    input logic [1:0]              s_axi_rresp,    
    input logic                    s_axi_rvalid,
    input logic                    s_axi_rready,

    // FIFO
    input logic                    int_w_en,
    input logic                    int_r_en,
    input logic [31:0]             int_w_data,
    input logic [31:0]             int_r_data,
    input logic                    int_full,
    input logic                    int_empty,
    input logic                    full_next,
    input logic                    empty_next
);

    //  ================== 
    //  AXI4-Lite Write
    //  ==================
    
    // 1. Stable check for aw channel
    property p_wbridge_aw_stable;
        @(posedge wclk) disable iff(!wrst_n)
        (s_axi_awvalid && !s_axi_awready) |=> ($stable(s_axi_awaddr) && s_axi_awvalid);
    endproperty
    ast_wbridge_awstable: assert property(p_wbridge_aw_stable)
    else $error("[SVA WBRIDGE ERROR] s_axi_awaddr changed before awready at time %0t", $time);

    // 2. Stable check for w channel
    property p_wbridge_w_stable;
        @(posedge wclk) disable iff(!wrst_n)
        (s_axi_wvalid && !s_axi_wready) |=> ($stable(s_axi_wdata) && $stable(s_axi_wstrb) && s_axi_wvalid);
    endproperty
    ast_wbridge_wstable: assert property(p_wbridge_w_stable)
    else $error("[SVA WBRIDGE ERROR] s_axi_wdata changed before wready at time %0t", $time);

    // 3. IDLE handshake
    property p_wbridge_idle_handshake;
        @(posedge wclk) disable iff(!wrst_n)
        (u_wbridge.state == u_wbridge.W_IDLE && s_axi_awvalid && s_axi_wvalid && !int_full) 
        |=> (s_axi_awready && s_axi_wready);
    endproperty
    ast_wbridge_idle_handshake: assert property (p_wbridge_idle_handshake)
    else $error("[SVA WBRIDGE ERROR] Ready signals failed to assert time = %0t", $time);

    // 4. Ready reset
    property p_wbridge_ready_reset;
        @(posedge wclk) disable iff(!wrst_n)
        (s_axi_awready || s_axi_wready) |=> (!s_axi_awready && !s_axi_wready);
    endproperty
    ast_wbridge_ready_reset: assert property(p_wbridge_ready_reset)
    else $error("[SVA WBRIDGE ERROR] awready/wready stayed high for more than 1 cycle at time = %0t", $time);

    // 5. Full check (When it's full, state shoudl stay in IDLE)
    property p_wbridge_full;
        @(posedge wclk) disable iff(!wrst_n)
        int_full |=> (!s_axi_awready && !s_axi_wready && 
                        (u_wbridge.state == u_wbridge.W_IDLE)); 
    endproperty
    ast_wbridge_full: assert property(p_wbridge_full)
    else $error("[SVA WBRIDGE ERROR] wbridge changed state when the FIFO is full");

    // 6. w_en should be 1 after state == W_PUSH
    property p_wbridge_legal_write;
        @(posedge wclk) disable iff(!wrst_n)
        (u_wbridge.state == u_wbridge.W_PUSH && u_wbridge.awaddr_reg[4:2] == u_wbridge.ADDR_FIFO_DATA) |=> 
        (int_w_en == 1'b1 && int_w_data == $past(u_wbridge.data_reg) && s_axi_bresp == 2'b00);
    endproperty
    ast_wbridge_legal_write: assert property (p_wbridge_legal_write)
    else $error("[SVA WBRIDGE ERROR] Legal write failed to drive FIFO at time=%0t", $time);

    // 7. bresp should return 10 when the address is not correct
    property p_wbridge_illegal_write_err;
        @(posedge wclk) disable iff (!wrst_n)
        (u_wbridge.state == u_wbridge.W_PUSH && u_wbridge.awaddr_reg[4:2] != u_wbridge.ADDR_FIFO_DATA) |=> 
        (int_w_en == 1'b0 && s_axi_bresp == 2'b10);
    endproperty
    ast_wbridge_illegal_write_err: assert property (p_wbridge_illegal_write_err)
    else $error("[SVA WBRIDGE ERROR] Illegal address was NOT blocked, or bresp failed to report SLVERR(2'b10)! time=%0t", $time);

    // 8. B channel check
    property p_wbridge_b_stable;
        @(posedge wclk) disable iff (!wrst_n)
        (s_axi_bvalid && !s_axi_bready) |=> ($stable(s_axi_bresp) && s_axi_bvalid);
    endproperty
    ast_wbridge_b_stable: assert property (p_wbridge_b_stable)
    else $error("[SVA WBRIDGE ERROR] s_axi_bresp shook before master bready! time=%0t", $time);

    //  ================== 
    //  AXI4-Lite Read
    //  ==================

    // 1. AR channel check
    property p_rbridge_ar_stable;
        @(posedge rclk) disable iff (!rrst_n)
        (s_axi_arvalid && !s_axi_arready) |=> ($stable(s_axi_araddr) && s_axi_arvalid);
    endproperty
    ast_rbridge_ar_stable: assert property (p_rbridge_ar_stable)
    else $error("[SVA RBRIDGE ERROR] s_axi_araddr or arvalid changed before arready! time=%0t", $time);

    // 2. IDLE handshake
    property p_rbridge_idle_handshake;
        @(posedge rclk) disable iff (!rrst_n)
        (u_rbridge.state == u_rbridge.R_IDLE && s_axi_arvalid && !int_empty) |=> (s_axi_arready);
    endproperty
    ast_rbridge_idle_handshake: assert property (p_rbridge_idle_handshake)
    else $error("[SVA RBRIDGE ERROR] s_axi_arready failed to assert in R_IDLE state! time=%0t", $time);

    // 3. When the FIFO is empty, we allow arready becomes 1, but response should not be 00
    property p_rbridge_empty_backpressure;
        @(posedge rclk) disable iff (!rrst_n)
        (u_rbridge.state == 1'b1 && u_rbridge.fifo_empty_reg === 1'b1) |=>
        (s_axi_rdata == 32'hDEAD_BEEF && s_axi_rresp == 2'b10);
    endproperty
    ast_rbridge_empty_backpressure: assert property (p_rbridge_empty_backpressure)
    else $error("[SVA RBRIDGE ERROR] Empty FIFO read violation! Expected SLVERR (2'b10) and DEAD_BEEF, but RTL failed to protect! time=%0t", $time);

    // 4. fifo_r_en
    property p_rbridge_fifo_en_timing;
        @(posedge rclk) disable iff (!rrst_n)
        (u_rbridge.state == u_rbridge.R_IDLE && s_axi_arvalid && !int_empty && s_axi_araddr[4:2] == u_rbridge.ADDR_FIFO_DATA) |=> 
        (int_r_en == 1'b1);
    endproperty
    ast_rbridge_fifo_en_timing: assert property (p_rbridge_fifo_en_timing)
    else $error("[SVA RBRIDGE ERROR] int_r_en failed to fire on the transition to R_DATA! time=%0t", $time);

    // 5. legal read check
    property p_rbridge_legal_read;
        @(posedge rclk) disable iff (!rrst_n)
        (u_rbridge.state == u_rbridge.R_DATA && $past(u_rbridge.fifo_r_en) == 1'b1) |-> 
        (s_axi_rdata == $past(int_r_data, 2) && s_axi_rresp == 2'b00);
    endproperty
    ast_rbridge_legal_read: assert property (p_rbridge_legal_read)
    else $error("[SVA RBRIDGE ERROR] Legal read failed to pass FIFO data or rresp != OKAY! time=%0t", $time);

    // 6. Illegal address 
    property p_rbridge_illegal_read_err;
        @(posedge rclk) disable iff (!rrst_n)
        (u_rbridge.state == u_rbridge.R_DATA && u_rbridge.araddr_reg[4:2] != u_rbridge.ADDR_FIFO_DATA) |=> 
        (s_axi_rdata == 32'hDEAD_BEEF && s_axi_rresp == 2'b10);
    endproperty
    ast_rbridge_illegal_read_err: assert property (p_rbridge_illegal_read_err)
    else $error("[SVA RBRIDGE ERROR] Illegal read failed to report DEAD_BEEF or SLVERR! time=%0t", $time);

    // 7. R channel check
    property p_rbridge_r_stable;
        @(posedge rclk) disable iff (!rrst_n)
        (s_axi_rvalid && !s_axi_rready) |=> ($stable(s_axi_rdata) && $stable(s_axi_rresp) && s_axi_rvalid);
    endproperty
    ast_rbridge_r_stable: assert property (p_rbridge_r_stable)
    else $error("[SVA RBRIDGE ERROR] AXI R-channel signals changed before master rready! time=%0t", $time);

    //  ================== 
    //  FIFO
    //  ==================

    // 1. Overflow
    property p_overflow;
        @(posedge wclk) disable iff(~wrst_n)
        (int_full && int_w_en) |-> (u_fifo_core.write_handle_h.b_wptr_next == u_fifo_core.write_handle_h.b_wptr);
    endproperty
    ast_core_wptr_overflow_lock: assert property(p_overflow)
    else $error("[SVA CORE ERROR]: full=%b w_en=%b b_wptr=%0h at time %0t", 
             int_full, int_w_en, u_fifo_core.write_handle_h.b_wptr, $time);
    
    // 2. Underflow
    property p_underflow;
        @(posedge rclk) disable iff(~rrst_n)
        (int_empty && int_r_en) |-> (u_fifo_core.read_handle_h.b_rptr_next == u_fifo_core.read_handle_h.b_rptr);
    endproperty
    ast_core_rptr_underflow_lock: assert property(p_underflow)
    else $error("[[SVA CORE ERROR]]: empty=%b r_en=%b b_rptr=%0h at time %0t", 
             int_empty, int_r_en, u_fifo_core.read_handle_h.b_rptr, $time);
    
    // 3. Check full
    property p_full_pointer_check;
        @(posedge wclk) disable iff (~wrst_n)
        full_next |=> int_full;
    endproperty
    ast_core_full_check: assert property(p_full_pointer_check)
    else $error("[SVA CORE ERROR]: Register int_full didn't follow full_next! full_next=%b full=%b at time %0t", 
             full_next, int_full, $time);
  
    
    // 4. Check empty
    property p_empty_pointer_check;
        @(posedge rclk) disable iff (~wrst_n)
        empty_next |=> int_empty;
    endproperty
    ast_core_empty_check: assert property(p_empty_pointer_check)
    else $error("[SVA CORE ERROR]: Register int_empty didn't follow empty_next! empty_next=%b empty=%b at time %0t", 
             empty_next, int_empty, $time);
    
    // 5. Gray Code trans
    property p_wptr_gray_code;
        @(posedge wclk) disable iff(~wrst_n)
        (u_fifo_core.write_handle_h.g_wptr != $past(u_fifo_core.write_handle_h.g_wptr)) 
        |-> ($countones(u_fifo_core.write_handle_h.g_wptr ^ $past(u_fifo_core.write_handle_h.g_wptr)) == 1);    // Can only change one bit
    endproperty
    ast_core_wptr_gray: assert property(p_wptr_gray_code)
    else $error("[SVA CORE ERROR]] g_wptr changed multiple bits at time %0t", $time);

    property p_rptr_gray_code;
        @(posedge rclk) disable iff(~rrst_n)
        (u_fifo_core.read_handle_h.g_rptr != $past(u_fifo_core.read_handle_h.g_rptr)) 
        |-> ($countones(u_fifo_core.read_handle_h.g_rptr ^ $past(u_fifo_core.read_handle_h.g_rptr)) == 1);    // Can only change one bit
    endproperty
    ast_core_rptr_gray: assert property(p_rptr_gray_code)
    else $error("[SVA CORE ERROR] g_rptr changed multiple bits at time %0t", $time);

    //  ================== 
    //  Others
    //  ==================

    // 1. Data write 
    property p_axi_to_fifo_data;
        @(posedge wclk) disable iff (!wrst_n)
        (!int_full && s_axi_awvalid && s_axi_awready && s_axi_wvalid && s_axi_wready && (s_axi_awaddr[4:2] == u_wbridge.ADDR_FIFO_DATA))
        |=> (int_w_en == 1'b1 && int_w_data == $past(s_axi_wdata, 1));
    endproperty
    ast_axi_to_fifo_data: assert property (p_axi_to_fifo_data)
    else $error("[SVA ERROR] AXI wdata mismatch with FIFO int_w_data! time=%0t", $time);



endmodule

bind axi4_lite_fifo_top fifo_assertions u_fifo_assertions_inst (
    .wclk           (wclk),
    .wrst_n         (wrst_n),
    .rclk           (rclk),
    .rrst_n         (rrst_n),
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
    .s_axi_araddr   (s_axi_araddr),
    .s_axi_arvalid  (s_axi_arvalid),
    .s_axi_arready  (s_axi_arready),
    .s_axi_rdata    (s_axi_rdata),
    .s_axi_rresp    (s_axi_rresp),
    .s_axi_rvalid   (s_axi_rvalid),
    .s_axi_rready   (s_axi_rready),
    .int_w_en       (int_w_en),
    .int_r_en       (int_r_en),
    .int_w_data     (int_w_data),
    .int_r_data     (int_r_data),
    .int_full       (int_full),
    .int_empty      (int_empty),
    .full_next      (full_next),
    .empty_next     (empty_next)
);