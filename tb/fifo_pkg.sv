package fifo_pkg;
    `include "fifo_transaction.sv"
    `include "fifo_generator.sv"

    `include "fifo_write_driver.sv"
    `include "fifo_read_driver.sv"
    
    `include "fifo_write_monitor.sv"
    `include "fifo_read_monitor.sv"
    
    `include "fifo_scoreboard.sv"
    `include "fifo_env.sv"

endpackage