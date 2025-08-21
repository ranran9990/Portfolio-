`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_pts_4bit ();

    localparam CLK_PERIOD = 2.5ns;

    logic clk, n_rst, shift_enable, load_enable, serial_out;
    logic [3:0] parallel_in;

    pts_4bit pts(.clk(clk), .n_rst(n_rst), .shift_enable(shift_enable), .load_enable(load_enable), .parallel_in(parallel_in), .serial_out(serial_out));

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
        parallel_in = 4'b1111;
        n_rst = 1;
        reset_dut();

        shift_enable = 1;
        load_enable = 1;
        parallel_in = 4'b1111;
        #(5);

        parallel_in = 4'b0000;
        #(5);
        parallel_in = 4'b1010;
        #(5);

        shift_enable = 1;
        parallel_in = 4'b1110;
        #(5);
        shift_enable = 0;
        parallel_in = 4'b1010;
        #(5);
        shift_enable = 1;
        parallel_in = 4'b1000;
        #(5);
        shift_enable = 0;
        parallel_in = 4'b0010;
        #(5);

        shift_enable = 0;
        load_enable = 0;
        parallel_in = 4'b0010;
        #(5);

        shift_enable = 0;
        load_enable = 1;
        parallel_in = 4'b1000;
        #(5);

        shift_enable = 1;
        load_enable = 0;
        parallel_in = 4'b1111;
        #(5);

        shift_enable = 1;
        load_enable = 1;
        parallel_in = 4'b0111;
        #(5);


        $finish;
    end
endmodule

/* verilator coverage_on */

