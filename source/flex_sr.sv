`timescale 1ns / 10ps

module flex_sr #(
    parameter SIZE = 8,
    parameter MSB_FIRST = 0
)(
    input logic clk,
    input logic n_rst,
    input logic shift_enable,
    input logic load_enable,
    input logic serial_in,
    input logic [SIZE-1:0] parallel_in,
    output logic serial_out,
    output logic [SIZE-1:0] parallel_out
);

logic [SIZE-1:0] parallel_next;

always_ff @(posedge clk, negedge n_rst) begin
    if (~n_rst) begin
        parallel_out <= '1;
        serial_out <= parallel_out[0];
    end else begin
        parallel_out <= parallel_next;
        serial_out <= parallel_next[0];
    end
end

always_comb begin
    parallel_next = parallel_out;

    if ((load_enable & shift_enable) | (load_enable & ~shift_enable)) begin
        parallel_next = parallel_in;
    end else if (shift_enable & ~load_enable) begin
        if (MSB_FIRST) begin
            parallel_next = {parallel_out[SIZE-2:0], serial_in};
        end else begin
            parallel_next = {serial_in, parallel_out[SIZE-1:1]};
        end
    end
end
endmodule


