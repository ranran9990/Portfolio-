`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_rcu ();

    localparam CLK_PERIOD = 10ns;

    logic clk, n_rst, new_packet_detected, packet_done, framing_error, sbc_clear, sbc_enable, load_buffer, enable_timer;

    rcu reciever(.clk(clk), .n_rst(n_rst), .new_packet_detected(new_packet_detected), .packet_done(packet_done), .framing_error(framing_error), .sbc_clear(sbc_clear), .sbc_enable(sbc_enable), .load_buffer(load_buffer), .enable_timer(enable_timer));

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
        new_packet_detected = 1'b0;
        packet_done = 1'b0;
        framing_error = 1'b1;
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        new_packet_detected = 1'b1;
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        new_packet_detected = 1'b0;
        packet_done = 1'b1;
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        framing_error = 1'b0;
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);

        new_packet_detected = 1'b1;
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        new_packet_detected = 1'b0;
        @(negedge clk);
        @(negedge clk);

        new_packet_detected = 1'b1;
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        n_rst = 1'b0;
        @(negedge clk);
        @(negedge clk);
        n_rst = 1'b1;
        @(negedge clk);
        @(negedge clk);
              

        $finish;
    end
endmodule

/* verilator coverage_on */

