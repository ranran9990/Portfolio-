`timescale 1ns / 10ps

module adder_nbit #(parameter SIZE = 16) (
    input logic [SIZE - 1:0] a,
    input logic [SIZE - 1:0] b,
    input logic carry_in,
    output logic [SIZE - 1:0] sum,
    output logic carry_out
);

    logic [SIZE:0] carry;

    assign carry[0] = carry_in;

    generate
        genvar i;
        for ( i = 0; i < SIZE ;  i ++) begin : gen_for_loop
            full_adder fa(.a(a[i]), .b(b[i]), .carry_in(carry[i]), .sum(sum[i]), .carry_out(carry[i + 1]));
        end
    endgenerate

    assign carry_out = carry[SIZE];

endmodule 

