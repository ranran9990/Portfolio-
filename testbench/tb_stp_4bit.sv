`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_stp_4bit ();

    localparam CLK_PERIOD = 2.5ns;

    logic clk, n_rst, shift_enable, serial_in;
    logic [3:0] parallel_out;

    stp_4bit stp(.clk(clk), .n_rst(n_rst), .shift_enable(shift_enable), .serial_in(serial_in), .parallel_out(parallel_out));

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
        shift_enable = 1;
        serial_in = 1;
        reset_dut();
        #(5);

        shift_enable = 1;
        #(5);

        serial_in = 1'b0;
        @(negedge clk);
        serial_in = 1'b0;
        @(negedge clk);
        serial_in = 1'b0;
        @(negedge clk);
        serial_in = 1'b0;
        @(negedge clk);
        #(5);

        shift_enable = 0;
        #(5);

        serial_in = 1'b1;
        @(negedge clk);
        serial_in = 1'b1;
        @(negedge clk);
        serial_in = 1'b0;
        @(negedge clk);
        serial_in = 1'b1;
        @(negedge clk);       

        shift_enable = 1;
        #(5);
        
        serial_in = 1'b1;
        @(negedge clk);
        serial_in = 1'b1;
        @(negedge clk);
        serial_in = 1'b0;
        @(negedge clk);
        serial_in = 1'b1;
        @(negedge clk);   

        shift_enable = 0;
        #(5);

        serial_in = 1'b0;
        @(negedge clk);
        serial_in = 1'b1;
        @(negedge clk);
        serial_in = 1'b1;
        @(negedge clk);
        serial_in = 1'b1;
        @(negedge clk);       

        shift_enable = 1;
        #(5);
        
        serial_in = 1'b1;
        @(negedge clk);
        serial_in = 1'b1;
        @(negedge clk);
        serial_in = 1'b0;
        @(negedge clk);
        serial_in = 1'b1;
        @(negedge clk);   
        $finish;
    end
endmodule

/* verilator coverage_on */

