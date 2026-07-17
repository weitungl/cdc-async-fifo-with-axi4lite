class fifo_read_monitor #(parameter DATA_WIDTH = 32);
    virtual fifo_if #(DATA_WIDTH) vif;
    mailbox #(fifo_transaction #(DATA_WIDTH)) mon2scb;
    logic [31:0]    addr_reg;

    function new(mailbox #(fifo_transaction #(DATA_WIDTH)) mon2scb, virtual fifo_if #(DATA_WIDTH) vif);
        this.vif = vif;
        this.mon2scb = mon2scb;
    endfunction

    task run();
        fifo_transaction #(DATA_WIDTH) tr;
        $display("Read monitor started");

        forever begin
            @(posedge vif.rclk);
            // Get the address
            if(vif.s_axi_arvalid && vif.s_axi_arready) begin
                addr_reg = vif.s_axi_araddr;
            end
            // Get data
            if(vif.s_axi_rready && vif.s_axi_rvalid) begin
                if(vif.s_axi_rresp == 2'b10) begin
                    addr_reg[4:2] = 3'b111; // Even the address is legal, the FIFO might be empty right now
                    $error("[Read Monitor ERROR] AXI rresp = 2'b%b", vif.s_axi_rresp);
                end else if(vif.s_axi_rresp != 2'b00) begin
                    $error("[Read Monitor ERROR] Unknown AXI rresp = 2'b%b", vif.s_axi_rresp);
                end

                if(addr_reg[4:2] == 3'd0) begin
                    tr = new();
                    tr.data = vif.s_axi_rdata;
                    tr.addr = addr_reg;
                    mon2scb.put(tr);
                    $display("[Read Monitor] Captured AXI Read Data: 0x%h from Addr: 0x%h", tr.data, tr.addr);
                end
            end
        end
    endtask
endclass