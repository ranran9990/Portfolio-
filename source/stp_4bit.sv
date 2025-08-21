`timescale 1ns / 10ps

module stp_4bit (
    input logic clk,
    input logic n_rst,
    input logic shift_enable,
    input logic serial_in,
    output logic [3:0] parallel_out
);

logic [3:0] parallel_next;

always_ff @(posedge clk, negedge n_rst) begin
    if (~n_rst) begin
        parallel_out[3:0] <= 4'b1111;
    end else begin
        parallel_out <= parallel_next;
    end
end

always_comb begin
    if (shift_enable) begin
        parallel_next = {serial_in, parallel_out[3], parallel_out[2], parallel_out[1]};
    end else begin
        parallel_next = parallel_out;
    end    
end
endmodule

