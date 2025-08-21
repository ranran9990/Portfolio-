`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_coefficient_loader ();

    localparam CLK_PERIOD = 10ns;

    logic clk, n_rst;

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

        reset_dut();

        $finish;
    end
endmodule

/* verilator coverage_on */

