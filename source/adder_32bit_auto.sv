`timescale 1ns / 10ps

module adder_32bit_auto #() (
    input logic [31:0]a,
    input logic [31:0]b,
    input logic carry_in,
    output logic [31:0]sum,
    output logic carry_out
);

assign {carry_out, sum} = a + b + carry_in;

endmodule

