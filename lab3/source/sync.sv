`timescale 1ns / 10ps

module sync #(parameter RST_VAL = 0)(
    input logic clk,
    input logic n_rst,
    input logic async_in,
    output logic sync_out
);

logic state1, state2;

always_ff @(posedge clk, negedge n_rst) begin 
    if (~n_rst) begin
        state1 <= RST_VAL;
        state2 <= RST_VAL;
    end else begin
        state1 <= async_in; 
        state2 <= state1;
    end
end   

always_comb begin
    sync_out = state2;
end

endmodule

