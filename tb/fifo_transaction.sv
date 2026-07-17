typedef enum {WRITE_ONLY, READ_ONLY, IDLE} trans_type_e;

class fifo_transaction #(parameter DATA_WIDTH = 32);
    rand bit [DATA_WIDTH-1:0]       data;
    rand bit [31:0]                 addr;
    rand trans_type_e               trans_type;
    rand bit [2:0]                  delay;

    constraint valid_data {
        data > 32'd0;
    }

    constraint valid_delay {
        delay inside {[0:4]};
    }

    constraint valid_address {
        addr dist {
            32'h0000_0000 := 80,
            [32'h0000_0004 : 32'h0000_000c] :/ 20
        };
    }

    function void display(string name);
        $display("[%s] Type = %s, Addr = %h, Data = %h, Delay = %0d cycles", name, trans_type.name(), addr, data, delay);
    endfunction
endclass