
class fifo_generator #(parameter DATA_WIDTH = 32);
    mailbox #(fifo_transaction #(DATA_WIDTH)) gen2wdrv;
    mailbox #(fifo_transaction #(DATA_WIDTH)) gen2rdrv;
    int num_transactions;
    int legal_write_cnt;
    string test_mode;

    event drv_done;

    function new(mailbox #(fifo_transaction #(DATA_WIDTH)) gen2wdrv, 
                 mailbox #(fifo_transaction #(DATA_WIDTH)) gen2rdrv,
                 int num_transactions, 
                 string test_mode = "RANDOM");
        this.gen2wdrv = gen2wdrv;
        this.gen2rdrv = gen2rdrv;
        this.num_transactions = num_transactions;
        this.test_mode = test_mode;
    endfunction

    task run();
        fifo_transaction #(DATA_WIDTH) tr_w;
        fifo_transaction #(DATA_WIDTH) tr_r;
        $display("Generator starts, mode = %s, total = %0d", test_mode, num_transactions);
        legal_write_cnt = 0;

        for(int i = 0; i < num_transactions; i++) begin
            tr_w = new();
            tr_r = new();

            if (test_mode == "WRITE_ONLY") begin
                if (tr_w.randomize() with { trans_type == WRITE_ONLY; }) begin
                    if (tr_w.addr[4:2] == 3'd0) begin
                        legal_write_cnt++;
                    end
                end else begin
                    $error("W error");
                end
                if (!tr_r.randomize() with {trans_type == IDLE;}) $error("R error");
            end else if (test_mode == "READ_BACK") begin
                if (i < (num_transactions / 2)) begin
                    // Write the first half
                    if (!tr_w.randomize() with { trans_type == WRITE_ONLY; addr[4:2] == 3'd0; }) $error("W error");
                    if (!tr_r.randomize() with { trans_type == IDLE; }) $error("R error");
                end else begin
                    // Read for the rest
                    if (!tr_w.randomize() with { trans_type == IDLE; }) $error("W error");
                    if (!tr_r.randomize() with { trans_type == READ_ONLY; addr[4:2] == 3'd0; }) $error("R error");
                end
            end else if (test_mode == "READ_WRITE") begin
                if (!tr_w.randomize() with {trans_type == WRITE_ONLY;}) $error("W error");
                if (!tr_r.randomize() with {trans_type == READ_ONLY;}) $error("R error");
            end else if (test_mode == "RANDOM") begin
                if (!tr_w.randomize()) $error("W error");
                if (!tr_r.randomize()) $error("R error");
            end else begin
                $error("[Generator] Unknown test_mode: %s", test_mode);
            end
            gen2wdrv.put(tr_w);
            gen2rdrv.put(tr_r);
        end
        
        $display("[Generator] All transactions generated. Triggering drv_done.");
        -> drv_done;
    endtask
endclass