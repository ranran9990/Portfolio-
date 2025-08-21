// `timescale 1ns / 10ps

// module timer (
//
//     input logic clk,
//     input logic n_rst,
//     input logic enable_timer,
//     output logic shift_strobe,
//     output logic packet_done
// );


// flex_counter #(.SIZE(4)) data_packet(.clk(clk), .n_rst(n_rst), .clear(packet_done), .count_enable(enable_timer), .rollover_val(4'd10), .count_out(), .rollover_flag(shift_strobe));
// flex_counter #(.SIZE(4)) full_packet(.clk(clk), .n_rst(n_rst), .clear(packet_done), .count_enable(shift_strobe), .rollover_val(4'd9), .count_out(), .rollover_flag(packet_done));


`timescale 1ns / 10ps

module timer (
    input logic clk,
    input logic n_rst,
    input logic [3:0] data_size,
    input logic [13:0] bit_period,
    input logic enable_timer,
    output logic shift_strobe,
    output logic packet_done
);


flex_counter #(.SIZE(14)) data_packet(.clk(clk), .n_rst(n_rst), .clear(packet_done), .count_enable(enable_timer), .rollover_val(bit_period), .count_out(), .rollover_flag(shift_strobe));
flex_counter #(.SIZE(4)) full_packet(.clk(clk), .n_rst(n_rst), .clear(packet_done), .count_enable(shift_strobe), .rollover_val(data_size + 1'b1), .count_out(), .rollover_flag(packet_done));


endmodule
