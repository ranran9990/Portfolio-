`timescale 1ns / 10ps

module sync_low (
  input logic clk, n_rst, async_in,
  output logic sync_out
);
    // does not touch parameter, tests for correct default value
    sync #() low (.*);

endmodule

