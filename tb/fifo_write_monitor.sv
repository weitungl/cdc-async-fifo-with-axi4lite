class fifo_write_monitor #(parameter DATA_WIDTH = 32);
    virtual fifo_if #(DATA_WIDTH) vif;
    mailbox #(fifo_transaction #(DATA_WIDTH)) mon2scb;

    function new(mailbox #(fifo_transaction #(DATA_WIDTH)) mon2scb, virtual fifo_if #(DATA_WIDTH) vif);
        this.vif = vif;
        this.mon2scb = mon2scb;
    endfunction

    task run();
        fifo_transaction #(DATA_WIDTH) tr;
        $display("Write monitor started");

        forever begin
            @(posedge vif.wclk);
            if((vif.s_axi_awready && vif.s_axi_awvalid) && (vif.s_axi_wready && vif.s_axi_wvalid)) begin
                if(vif.s_axi_awaddr[4:2] == 3'd0) begin
                    tr = new();
                    tr.data = vif.s_axi_wdata;
                    tr.addr = vif.s_axi_awaddr;
                    mon2scb.put(tr);
                    $display("[Write Monitor] Captured AXI Write Data: 0x%h to Addr: 0x%h", tr.data, tr.addr);
                end
            end
        end
    endtask
endclass