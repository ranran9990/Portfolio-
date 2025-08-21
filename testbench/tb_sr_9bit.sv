`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_sr_9bit ();

    localparam CLK_PERIOD = 10ns;

    logic clk, n_rst, shift_strobe, serial_in, stop_bit;
    logic [7:0] packet_data;

    sr_9bit shift(.clk(clk), .n_rst(n_rst), .shift_strobe(shift_strobe), .serial_in(serial_in), .packet_data(packet_data), .stop_bit(stop_bit));

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
        shift_strobe = 1'b0;
        serial_in = 1'b0;
        @(negedge clk);
        @(negedge clk);
        shift_strobe = 1'b1;
        @(negedge clk);
        @(negedge clk);
        serial_in = 1'b0;
        @(negedge clk);
        serial_in = 1'b1;
        @(negedge clk);
        serial_in = 1'b0;
        @(negedge clk);
        @(negedge clk);
        serial_in = 1'b0;
        @(negedge clk);
        @(negedge clk);
        serial_in = 1'b0;
        @(negedge clk);
        @(negedge clk);
        serial_in = 1'b0;
        @(negedge clk);
        @(negedge clk);
        serial_in = 1'b0;
        @(negedge clk);
        @(negedge clk);
        serial_in = 1'b0;
        @(negedge clk);
        @(negedge clk);
        serial_in = 1'b0;
        @(negedge clk);
        @(negedge clk);
        serial_in = 1'b0;
        @(negedge clk);
        @(negedge clk);
        serial_in = 1'b1;
        @(negedge clk);
        @(negedge clk);
        shift_strobe = 1'b0;
        serial_in = 1'b0;
        @(negedge clk);
        @(negedge clk);
        serial_in = 1'b1;
        @(negedge clk);
        @(negedge clk);
        n_rst = 1'b0;
        @(negedge clk);
        @(negedge clk);
        shift_strobe = 1'b1;
        serial_in = 1'b0;
        @(negedge clk);
        @(negedge clk);
        serial_in = 1'b1;
        @(negedge clk);
        @(negedge clk);
        n_rst = 1'b1;
        @(negedge clk);
        @(negedge clk);
        

        $finish;
    end
endmodule

/* verilator coverage_on */

