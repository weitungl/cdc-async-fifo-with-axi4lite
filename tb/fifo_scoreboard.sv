class fifo_scoreboard #(parameter DATA_WIDTH = 32);
    mailbox #(fifo_transaction #(DATA_WIDTH)) wmon2scb;
    mailbox #(fifo_transaction #(DATA_WIDTH)) rmon2scb;

    bit [DATA_WIDTH-1:0] golden_queue[$];   // Queue for input data

    int match_cnt = 0;
    int error_cnt = 0;

    localparam bit [2:0] ADDR_FIFO_DATA = 3'd0;

    function new(mailbox #(fifo_transaction #(DATA_WIDTH)) wmon2scb, mailbox #(fifo_transaction #(DATA_WIDTH)) rmon2scb);
        this.wmon2scb = wmon2scb;
        this.rmon2scb = rmon2scb;
    endfunction 

    int real_w_cnt;
    int real_r_cnt;

    task run();
        real_w_cnt = 0;
        real_r_cnt = 0;
        $display("Scoreboard started");
        fork
            // First thread: from wrtie monitor
            forever begin
                fifo_transaction #(DATA_WIDTH) w_tr;
                wmon2scb.get(w_tr);
                if(w_tr.addr[4:2] == ADDR_FIFO_DATA) begin
                    real_w_cnt ++;
                    golden_queue.push_back(w_tr.data);      // write into the golden queue
                end
            end
            // Second thread: from read monitor
            forever begin
                fifo_transaction #(DATA_WIDTH) r_tr;
                bit [DATA_WIDTH-1:0] correct_data;  
                rmon2scb.get(r_tr);                     // Blocks until get something through the mailbox

                if(r_tr.addr[4:2] == ADDR_FIFO_DATA) begin
                    real_r_cnt ++;
                    if(golden_queue.size() == 0) begin
                        $error("[ERROR] The golden queue is empty but read out %0h", r_tr.data);
                        error_cnt ++;
                    end else begin
                        correct_data = golden_queue.pop_front();
                        if(correct_data === r_tr.data)
                            match_cnt ++;
                        else begin
                            $error("[SCB ERROR] Data Mismatch! Expected: %0h, Got: %0h at time %0t", correct_data, r_tr.data, $time);
                            error_cnt ++;
                        end
                    end
                end else begin
                    if (r_tr.data === 32'hDEAD_BEEF) begin
                        match_cnt ++; // Correctly detect the wrong data
                    end else begin
                        error_cnt ++;
                    end
                end
            end
        join_none
    endtask
    // Print out the report
    function void report(string test_mode = "RANDOM");
        $display("-----------------------------------------");
        $display("Scoreboard Report (%s Mode)", test_mode);
        $display("FIFO Real Writes : %0d", real_w_cnt); 
        $display("FIFO Real Reads  : %0d", real_r_cnt);
        $display("Matched: %0d", match_cnt);
        $display("Errors:  %0d", error_cnt);

        if(test_mode == "WRITE_ONLY") begin
            $display("WRITE_ONLY mode: %0d items put into golden queue.", golden_queue.size());
        end else if (golden_queue.size() > 0) begin
            $display("Warning: %0d items left in golden queue.", golden_queue.size());
        end
        $display("-----------------------------------------");
    endfunction
endclass