class fifo_env #(parameter DATA_WIDTH = 32);

    fifo_generator      #(DATA_WIDTH) gen;
    fifo_read_driver    #(DATA_WIDTH) r_drv;
    fifo_write_driver   #(DATA_WIDTH) w_drv;
    fifo_read_monitor   #(DATA_WIDTH) r_mon;
    fifo_write_monitor  #(DATA_WIDTH) w_mon;
    fifo_scoreboard     #(DATA_WIDTH) scb;
    // Mailboxes
    mailbox #(fifo_transaction #(DATA_WIDTH)) gen2wdrv;
    mailbox #(fifo_transaction #(DATA_WIDTH)) gen2rdrv;
    mailbox #(fifo_transaction #(DATA_WIDTH)) wmon2scb;
    mailbox #(fifo_transaction #(DATA_WIDTH)) rmon2scb;
    // virtual interface
    virtual fifo_if #(DATA_WIDTH) vif;
    string test_mode;
    int timeout_cnt;
    int write_full;

    function new(virtual fifo_if #(DATA_WIDTH) vif, int num_transactions, string test_mode = "RANDOM");
        this.vif = vif;
        this.test_mode = test_mode;
        // Mailbox
        gen2wdrv = new();
        gen2rdrv = new();
        wmon2scb = new();
        rmon2scb = new();

        gen     = new(gen2wdrv, gen2rdrv, num_transactions, test_mode);
        r_drv   = new(vif, gen2rdrv);
        w_drv   = new(vif, gen2wdrv);
        r_mon   = new(rmon2scb, vif);
        w_mon   = new(wmon2scb, vif);
        scb     = new(wmon2scb, rmon2scb);
    endfunction

    task run();
        $display("Environment starting");
        fork 
            gen.run();
            r_drv.run();
            w_drv.run();
            r_mon.run();
            w_mon.run();
            scb.run();
        join_any

        wait(gen.drv_done.triggered);

        if(test_mode == "READ_WRITE" || test_mode == "RANDOM" || test_mode == "READ_BACK") begin
            timeout_cnt = 0;
            while(gen2wdrv.num() > 0 || gen2rdrv.num() > 0) begin
                #10; 
                timeout_cnt ++;
                if(timeout_cnt > 5000) begin
                    $display("[Read Driver Stuck] Waiting for rvalid for too long at time %0t", $time);
                    break;
                end
            end
            #500;
        end else if (test_mode == "WRITE_ONLY") begin
            write_full = 0;
            timeout_cnt = 0;
            while(gen2wdrv.num() > 0 || gen2rdrv.num() > 0) begin
                #10; 
                timeout_cnt ++;
                if(timeout_cnt > 300) begin
                    write_full = 1;
                    $display("[Env Info] Mailbox stuck detected (FIFO Full Backpressure). Breaking loop safely.");
                    break;
                end
            end

            if(!write_full) begin
                while (scb.golden_queue.size() < gen.legal_write_cnt) begin
                    @(posedge vif.wclk);
                end
            end 
        end 

        disable fork;

        #100;
        scb.report(test_mode);
    endtask

endclass