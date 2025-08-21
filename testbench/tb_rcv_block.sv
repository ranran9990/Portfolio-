`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_rcv_block ();

    localparam CLK_PERIOD = 10ns;

    logic stop_bit; 

    logic clk, n_rst, serial_in, data_read, data_ready, overrun_error, framing_error;
    logic [7:0] rx_data;

    rcv_block block (.clk(clk), .n_rst(n_rst), .serial_in(serial_in), .data_read(data_read), .rx_data(rx_data), .data_ready(data_ready), .overrun_error(overrun_error), .framing_error(framing_error));

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
        n_rst = 1;
        @(negedge clk);
        @(negedge clk);
    end
    endtask

task send_packet;

    input [7:0] data;
    input stop_bit;
    input time data_period;
    integer i;

    begin
        // First synchronize to away from clock ’ s rising edge
        @(negedge clk)

        // Send start bit
        serial_in = 1'b0;
        #data_period;

        // Send data bits
        for ( i = 0; i < 8; i = i + 1)
        begin
        serial_in = data [i];
        #data_period;
        end

        // Send stop bit
        serial_in = stop_bit;
        #data_period;
    end
endtask


    initial begin
        n_rst = 1;
        serial_in = 1'b0;
        data_read = 1'b0;
        reset_dut();

        send_packet(.data(8'd5), .stop_bit(1'b1), .data_period(100));
        #(CLK_PERIOD * 10);
        data_read = 1'b1;
        @(negedge clk);
        @(negedge clk);  
        data_read = 1'b0;

        send_packet(.data(8'd10), .stop_bit(1'b1), .data_period(96));
        #(CLK_PERIOD * 10);
        data_read = 1'b1;
        @(negedge clk);
        @(negedge clk);  
        data_read = 1'b0;

        send_packet(.data(8'd50), .stop_bit(1'b1), .data_period(104));
        #(CLK_PERIOD * 10);
        data_read = 1'b1;
        @(negedge clk);
        @(negedge clk);  
        data_read = 1'b0;

        send_packet(.data(8'd227), .stop_bit(1'b0), .data_period(100));
        #(CLK_PERIOD * 10);
        data_read = 1'b1;
        @(negedge clk);
        @(negedge clk);  
        data_read = 1'b0;
        
        @(negedge clk);
        serial_in = 1'b1;
        @(negedge clk);
        @(negedge clk);


        send_packet(.data(8'd50), .stop_bit(1'b1), .data_period(100));
        #(CLK_PERIOD * 10);
        data_read = 1'b0;
        @(negedge clk);
        @(negedge clk); 

        send_packet(.data(8'd51), .stop_bit(1'b1), .data_period(100));
        #(CLK_PERIOD * 10);
        data_read = 1'b1;
        @(negedge clk);
        @(negedge clk);
        data_read = 1'b0;  

        $finish;
    end
endmodule

/* verilator coverage_on */

