`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_clk_div_timer ();

    localparam CLK_PERIOD = 10ns;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk, n_rst;
    logic enable, clk_divided;
    logic strobe;

    clk_div_timer clk_div(.clk(clk), .n_rst(n_rst), .enable(1'b1), .clk_divided(clk_divided), .strobe(strobe));

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
        @(posedge clk);
        @(posedge clk);
    end
    endtask

    initial begin
        n_rst = 1;
        enable = 1'b0;
        reset_dut();
        enable = 1'b1;
        #(CLK_PERIOD * 100);

        $finish;
    end
endmodule

/* verilator coverage_on */

