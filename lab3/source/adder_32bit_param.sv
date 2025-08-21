`timescale 1ns / 10ps

module adder_32bit_param #() (
    input logic [31:0]a,
    input logic [31:0]b,
    input logic carry_in,
    output logic [31:0]sum,
    output logic carry_out
);
    adder_nbit #(.SIZE(32)) nbit(.a(a), .b(b), .carry_in(carry_in), .sum(sum), .carry_out(carry_out));

endmodule

