`timescale 1ns / 10ps

module edge_det #(
    parameter TRIG_RISE = 1,
    parameter TRIG_FALL = 0,
    parameter RST_VAL = 0)
    (
    input logic clk,
    input logic n_rst,
    input logic async_in,
    output logic sync_out,
    output logic edge_flag
    );

    logic q;

    sync sync(.clk(clk), .n_rst(n_rst), .async_in(async_in), .sync_out(sync_out));

    always_ff @(posedge clk, negedge n_rst) begin 
        if (~n_rst) begin
            q <= RST_VAL;
        end else begin
            q <= sync_out; 
        end
    end   

    always_comb begin
        edge_flag = 1'b0;

        if (TRIG_RISE) begin 
            edge_flag = ~q & sync_out;
        end 
        if (TRIG_FALL & (~edge_flag)) begin
            edge_flag = q & ~sync_out;
        end 
    end

endmodule

