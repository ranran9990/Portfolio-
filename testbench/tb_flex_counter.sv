`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_flex_counter ();

    localparam CLK_PERIOD = 10ns;

    logic clk, n_rst, clear, count_enable, rollover_flag;
    logic [3:0] rollover_val, count_out;

    flex_counter DUT(.clk(clk), .n_rst(n_rst), .clear(clear), .count_enable(count_enable), .rollover_val(rollover_val), .count_out(count_out), .rollover_flag(rollover_flag));

    // clockgen
    always begin
        clk = 0;
        #(CLK_PERIOD / 2.0);
        clk = 1;
        #(CLK_PERIOD / 2.0);
    end

    task reset_dut;
    begin
        n_rst = 0;
        @(posedge clk);
        @(posedge clk);
        @(negedge clk);
        n_rst = 1;
        @(negedge clk);
        @(negedge clk);
    end
    endtask

    initial begin
        n_rst = 1;
        rollover_val = 'd3;
        clear = 1'b0;
        count_enable = 1'b1;

        reset_dut();

        clear = 1'b0;
        count_enable = 1'b1;
        
        #(50);
        
        count_enable = 1'b0;
        #(5);

        count_enable = 1'b1;
        #(5);

        clear = 1'b1;
        #(5);

        clear = 1'b0;
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        count_enable = 1'b0;
        #(20);
        clear = 1'b1;
        @(negedge clk);
        @(negedge clk);



        $finish;
    end
endmodule

/* verilator coverage_on */

