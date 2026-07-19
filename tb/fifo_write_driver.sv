

class fifo_write_driver #(parameter DATA_WIDTH = 32);
    virtual fifo_if #(DATA_WIDTH) vif;
    mailbox #(fifo_transaction #(DATA_WIDTH)) gen2wdrv;  // mailbox


    function new(virtual fifo_if #(DATA_WIDTH) vif, mailbox #(fifo_transaction #(DATA_WIDTH)) gen2wdrv);
        this.vif = vif;
        this.gen2wdrv = gen2wdrv;
    endfunction

    task run();
        $display("Write driver started");
        vif.s_axi_awvalid   <= 1'b0;
        vif.s_axi_wvalid    <= 1'b0;
        vif.s_axi_bready    <= 1'b0;

        vif.s_axi_awaddr    <= '0;
        vif.s_axi_wdata     <= '0;
        vif.s_axi_wstrb     <= 4'b1111;

        repeat(2) @(posedge vif.wclk);


        forever begin
            fifo_transaction #(DATA_WIDTH) tr;
            gen2wdrv.get(tr);   // From generator
            if(tr.delay > 0) begin
                repeat(tr.delay) @(posedge vif.wclk);
            end

            if(tr.trans_type == WRITE_ONLY) begin

                vif.s_axi_awaddr    <= tr.addr;
                vif.s_axi_wdata     <= tr.data;
                vif.s_axi_wvalid    <= 1'b1;
                vif.s_axi_awvalid   <= 1'b1;
                @(posedge vif.wclk);
                
                fork
                    // AW Channel handshake
                    begin
                        while(!vif.s_axi_awready) begin
                            @(posedge vif.wclk);
                        end
                        vif.s_axi_awvalid <= 1'b0;
                    end 
                    // W Channel handshake
                    begin
                        while(!vif.s_axi_wready) begin
                            @(posedge vif.wclk);
                        end
                        vif.s_axi_wvalid <= 1'b0;
                    end
                join    // Both should both set to 0

                vif.s_axi_bready <= 1'b1;
                while(!vif.s_axi_bvalid) begin
                    @(posedge vif.wclk);
                end
                
                if (vif.s_axi_bresp != 2'b00) begin
                    $error("[Write Driver ERROR] AXI Write Transfer Error! bresp = 2'b%b", vif.s_axi_bresp);
                end
                vif.s_axi_bready <= 1'b0;
                @(posedge vif.wclk);
            end else begin
                vif.s_axi_awvalid   <= 1'b0;
                vif.s_axi_wvalid    <= 1'b0;
                @(posedge vif.wclk);
            end
        end
    endtask
endclass