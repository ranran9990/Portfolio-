`timescale 1ns / 10ps

module adder_128bit (
    input logic [127:0]a,
    input logic [127:0]b,
    output logic [128:0]s
);
    adder_nbit #(.SIZE(128)) nbit(.a(a), .b(b), .carry_in(1'b0), .sum(s[127:0]), .carry_out(s[128]));

endmodule

