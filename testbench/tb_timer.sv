`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_timer ();

    localparam CLK_PERIOD = 10ns;

    logic clk, n_rst, enable_timer, shift_strobe, packet_done;

    timer timer_clock(.clk(clk), .n_rst(n_rst), .enable_timer(enable_timer), .shift_strobe(shift_strobe), .packet_done(packet_done));

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
        enable_timer = 1'b0;
        @(negedge clk);
        @(negedge clk);
        enable_timer = 1'b1;
        #(2000);
        n_rst = 1'b0;
        #(500);
        n_rst = 1'b1;
        #(500);

        $finish;
    end
endmodule

/* verilator coverage_on */

