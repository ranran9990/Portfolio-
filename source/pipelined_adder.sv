`timescale 1ns / 10ps

module pipelined_adder (
  input logic clk,
  input logic n_rst,
  input logic [127:0] a,
  input logic [127:0] b,
  output logic [128:0] s
);

  // ********************************
  // Course-Provided Pipeline Latches
  // 
  // These are oversized, so not every bit may be actually used.
  // Make sure to set unused bits to 0. "End" signifies the end
  // of a stage when all the compute has finished, and "beg"
  // signifies the beginning, coming right out of the FF and
  // representing the FF block in hdl code.
  // ********************************
  
  struct packed {
    logic [127:0] a, b;
    logic c;
    logic [128:0] s;
  } end_s1, beg_s2, end_s2, beg_s3, end_s3, beg_s4;

  always_ff @(posedge clk, negedge n_rst) begin
    if(~n_rst) begin
      beg_s2 <= '0;
      beg_s3 <= '0;
      beg_s4 <= '0;
    end
    else begin
      beg_s2 <= end_s1;
      beg_s3 <= end_s2;
      beg_s4 <= end_s3;
    end
  end

  adder_nbit #(.SIZE(32)) stage1 (.a(a[31:0]), .b(b[31:0]), .carry_in(1'b0), .sum(end_s1.s[31:0]), .carry_out(end_s1.c));
  adder_nbit #(.SIZE(32)) stage2 (.a(beg_s2.a[63:32]), .b(beg_s2.b[63:32]), .carry_in(beg_s2.c), .sum(end_s2.s[63:32]), .carry_out(end_s2.c));
  adder_nbit #(.SIZE(32)) stage3 (.a(beg_s3.a[95:64]), .b(beg_s3.b[95:64]), .carry_in(beg_s3.c), .sum(end_s3.s[95:64]), .carry_out(end_s3.c));
  adder_nbit #(.SIZE(32)) stage4 (.a(beg_s4.a[127:96]), .b(beg_s4.b[127:96]), .carry_in(beg_s4.c), .sum(s[127:96]), .carry_out(s[128]));

  always_comb begin

    end_s1.a = a;
    end_s1.b = b;
    end_s2.a = beg_s2.a;
    end_s2.b = beg_s2.b;
    end_s3.a = beg_s3.a;
    end_s3.b = beg_s3.b;

    end_s1.s[127:32] = '0;
    end_s2.s[31:0] = beg_s2.s[31:0];

    end_s2.s[127:64] = '0;
    end_s3.s[63:0] = beg_s3.s[63:0];

    end_s3.s[127:96] = '0;
    s[95:0] = beg_s4.s[95:0];
  end

endmodule

