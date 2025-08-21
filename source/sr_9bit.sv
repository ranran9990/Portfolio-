`timescale 1ns / 10ps

module sr_9bit (
    input logic clk,
    input logic n_rst,
    input logic shift_strobe,
    input logic serial_in,
    // input logic data_size,
    output logic [7:0] packet_data,
    output logic stop_bit
);

flex_sr #(.SIZE(9), .MSB_FIRST(0)) shift(.clk(clk), .n_rst(n_rst), .shift_enable(shift_strobe), .load_enable(1'b0), .serial_in(serial_in), .parallel_in('0), .serial_out(), .parallel_out({stop_bit, packet_data}));

endmodule

