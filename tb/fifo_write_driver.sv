

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
                fork
                    // AW Channel handshake
                    begin
                        forever begin
                            @(posedge vif.wclk); 
                            if (vif.s_axi_awready) begin 
                                vif.s_axi_awvalid <= 1'b0; 
                                break;
                            end
                        end
                    end 
                    // W Channel handshake
                    begin
                        forever begin
                            @(posedge vif.wclk); // wait for the clock edge
                            if (vif.s_axi_wready) begin
                                vif.s_axi_wvalid <= 1'b0;
                                break;
                            end
                        end
                    end
                join    // Both should both set to 0

                vif.s_axi_bready <= 1'b1;
                forever begin
                    @(posedge vif.wclk);
                    if (vif.s_axi_bvalid) begin
                        break;
                    end
                end
                
                if (vif.s_axi_bresp != 2'b00) begin
                    $error("[Write Driver ERROR] AXI Write Transfer Error! bresp = 2'b%b", vif.s_axi_bresp);
                end
                vif.s_axi_bready <= 1'b0;
            end else begin
                vif.s_axi_awvalid   <= 1'b0;
                vif.s_axi_wvalid    <= 1'b0;
                @(posedge vif.wclk);
            end
        end
    endtask
endclass