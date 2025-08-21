module edge_dual(
  input logic clk, n_rst, async_in,
  output logic sync_out, edge_flag
);

  edge_det #(.RST_VAL(1'b0), .TRIG_RISE(1'b1), .TRIG_FALL(1'b1)) dual (.*);
  
endmodule
