`timescale 1ns / 10ps

module full_adder #()(
    input logic a,
    input logic b,
    input logic carry_in,
    output logic sum,
    output logic carry_out
);

    assign sum = carry_in ^ a ^ b;
    assign carry_out = (carry_in & a) | (carry_in & b) | (a & b) | (carry_in & a & b);

endmodule

