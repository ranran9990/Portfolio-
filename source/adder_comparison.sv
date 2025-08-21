module adder_comparison (
  input logic clk, n_rst,
  input logic [1:0][127:0] a, b,
  output logic [1:0][128:0] s
);

  adder_128bit comb_add (.a(a[0]), .b(b[0]), .s(s[0]));
  pipelined_adder pipe_add (.clk(clk), .n_rst(n_rst), .a(a[1]), .b(b[1]), .s(s[1]));
  
endmodule
