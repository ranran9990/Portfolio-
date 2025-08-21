`timescale 1ns / 10ps

module adder_6bit #()(
    input logic a[5:0],
    input logic b[5:0],
    input logic carry_in,
    output logic sum[5:0],
    output logic carry_out
);

logic carry_out1, carry_out2, carry_out3, carry_out4, carry_out5;

    full_adder fa1(.a(a[0]), .b(b[0]), .carry_in(carry_in), .sum(sum[0]), .carry_out(carry_out1));
    full_adder fa2(.a(a[1]), .b(b[1]), .carry_in(carry_out1), .sum(sum[1]), .carry_out(carry_out2));
    full_adder fa3(.a(a[2]), .b(b[2]), .carry_in(carry_out2), .sum(sum[2]), .carry_out(carry_out3));
    full_adder fa4(.a(a[3]), .b(b[3]), .carry_in(carry_out3), .sum(sum[3]), .carry_out(carry_out4));
    full_adder fa5(.a(a[4]), .b(b[4]), .carry_in(carry_out4), .sum(sum[4]), .carry_out(carry_out5));
    full_adder fa6(.a(a[5]), .b(b[5]), .carry_in(carry_out5), .sum(sum[5]), .carry_out(carry_out));
endmodule

