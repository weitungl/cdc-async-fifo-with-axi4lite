
class fifo_read_driver #(parameter DATA_WIDTH = 32);
    virtual fifo_if #(DATA_WIDTH) vif;
    mailbox #(fifo_transaction #(DATA_WIDTH)) gen2rdrv;
    bit success;

    function new(virtual fifo_if #(DATA_WIDTH) vif, mailbox #(fifo_transaction #(DATA_WIDTH)) gen2rdrv);
        this.vif = vif;
        this.gen2rdrv = gen2rdrv;
    endfunction

    task run();
        $display("Read driver started");

        vif.s_axi_arvalid   <= 1'b0;
        vif.s_axi_rready    <= 1'b0;
        vif.s_axi_araddr    <= '0;

        forever begin
            fifo_transaction #(DATA_WIDTH) tr;
            gen2rdrv.get(tr);

            if(tr.delay > 0) begin
                repeat(tr.delay) @(posedge vif.rclk);
            end

            if(tr.trans_type == READ_ONLY) begin
                // set address valid
                success = 0;
                while(!success) begin
                    vif.s_axi_arvalid   <= 1'b1;
                    vif.s_axi_araddr    <= tr.addr;

                    while(!vif.s_axi_arready)
                        @(posedge vif.rclk);
                    

                    vif.s_axi_arvalid   <= 1'b0;
                    vif.s_axi_araddr    <= '0;

                    vif.s_axi_rready    <= 1'b1;

                    while(!vif.s_axi_rvalid)
                        @(posedge vif.rclk);

                    vif.s_axi_rready    <= 1'b0;

                    if(vif.s_axi_rresp == 2'b00) begin
                        success = 1;
                    end else begin
                        @(posedge vif.rclk);
                    end

                end
            end else begin
                vif.s_axi_arvalid   <= 1'b0;
                vif.s_axi_rready    <= 1'b0;
                @(posedge vif.rclk);
            end
        end
    endtask
endclass