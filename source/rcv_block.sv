// `timescale 1ns / 10ps

// module rcv_block (
//     input logic clk,
//     input logic n_rst,
//     input logic serial_in,
//     input logic data_read,
//     output logic [7:0] rx_data,
//     output logic data_ready,
//     output logic overrun_error,
//     output logic framing_error
// );

// logic sync_serial_in, new_packet_detected, shift_strobe, packet_done, enable_timer, sbc_clear, sbc_enable, load_buffer, stop_bit;
// logic [7:0] packet_data;

// sync #(.RST_VAL(1)) synchronize_serial_in(.clk(clk), .n_rst(n_rst), .async_in(serial_in), .sync_out(sync_serial_in));

// start_bit_det start_bit_det(.clk(clk), .n_rst(n_rst), .serial_in(sync_serial_in), .new_packet_detected(new_packet_detected));
// sr_9bit shift_register(.clk(clk), .n_rst(n_rst), .shift_strobe(shift_strobe), .serial_in(sync_serial_in), .packet_data(packet_data), .stop_bit(stop_bit));
// rcu reciever_unit(.clk(clk), .n_rst(n_rst), .new_packet_detected(new_packet_detected), .packet_done(packet_done), .framing_error(framing_error), .sbc_clear(sbc_clear), .sbc_enable(sbc_enable), .load_buffer(load_buffer), .enable_timer(enable_timer));
// timer timer_clock(.clk(clk), .n_rst(n_rst), .enable_timer(enable_timer), .shift_strobe(shift_strobe), .packet_done(packet_done));
// stop_bit_chk stop_checker(.clk(clk), .n_rst(n_rst), .sbc_clear(sbc_clear), .sbc_enable(sbc_enable), .stop_bit(stop_bit), .framing_error(framing_error));
// rx_data_buff buffer(.clk(clk), .n_rst(n_rst), .load_buffer(load_buffer), .packet_data(packet_data), .data_read(data_read), .rx_data(rx_data), .data_ready(data_ready), .overrun_error(overrun_error));

// endmodule

`timescale 1ns / 10ps

module rcv_block (
    input logic clk,
    input logic n_rst,
    input logic serial_in,
    input logic data_read,
    output logic [7:0] rx_data,
    output logic data_ready,
    output logic overrun_error,
    output logic framing_error,
    input logic [3:0] data_size,
    input logic [13:0] bit_period
);

logic sync_serial_in, new_packet_detected, shift_strobe, packet_done, enable_timer, sbc_clear, sbc_enable, load_buffer, stop_bit;
logic [7:0] packet_data, padded_data;

sync #(.RST_VAL(1)) synchronize_serial_in(.clk(clk), .n_rst(n_rst), .async_in(serial_in), .sync_out(sync_serial_in));
start_bit_det start_bit_det(.clk(clk), .n_rst(n_rst), .serial_in(sync_serial_in), .new_packet_detected(new_packet_detected));
rcu reciever_unit(.clk(clk), .n_rst(n_rst), .new_packet_detected(new_packet_detected), .packet_done(packet_done), .framing_error(framing_error), .sbc_clear(sbc_clear), .sbc_enable(sbc_enable), .load_buffer(load_buffer), .enable_timer(enable_timer));
stop_bit_chk stop_checker(.clk(clk), .n_rst(n_rst), .sbc_clear(sbc_clear), .sbc_enable(sbc_enable), .stop_bit(stop_bit), .framing_error(framing_error));
rx_data_buff buffer(.clk(clk), .n_rst(n_rst), .load_buffer(load_buffer), .packet_data(padded_data), .data_read(data_read), .rx_data(rx_data), .data_ready(data_ready), .overrun_error(overrun_error));

always_comb begin
    case (data_size)
    4'd5: padded_data = {3'b0, packet_data[7:3]};
    4'd7: padded_data = {1'b0, packet_data[7:1]};
    4'd8: padded_data = packet_data[7:0];
    default: padded_data = packet_data;
    endcase
end

sr_9bit shift_register(.clk(clk), .n_rst(n_rst), .shift_strobe(shift_strobe), .serial_in(sync_serial_in), .packet_data(packet_data), .stop_bit(stop_bit));
timer timer_clock(.clk(clk), .n_rst(n_rst), .data_size(data_size), .bit_period(bit_period), .enable_timer(enable_timer), .shift_strobe(shift_strobe), .packet_done(packet_done));

endmodule

