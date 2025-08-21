`timescale 1ns / 10ps

module fir_filter (
    input logic clk,
    input logic n_rst,
    input logic [15:0] sample_data,
    input logic [15:0] fir_coefficient,
    input logic load_coeff,
    input logic data_ready,
    output logic one_k_samples,
    output logic modwait,
    output logic [15:0] fir_out,
    output logic err
);

logic cnt_up, clear, overflow;
logic [2:0] op;
logic [3:0] src1, src2, dest;
logic [16:0] outreg_data;

// sync synchronizer1 (.clk(clk), .n_rst(n_rst), .async_in(data_ready), .sync_out(dr));
// sync synchronizer2 (.clk(clk), .n_rst(n_rst), .async_in(load_coeff), .sync_out(lc));
controller control (.clk(clk), .n_rst(n_rst), .dr(data_ready), .lc(load_coeff), .overflow(overflow), .cnt_up(cnt_up), .clear(clear), .modwait(modwait), .op(op), .src1(src1), .src2(src2), .dest(dest), .err(err));
counter count (.clk(clk), .n_rst(n_rst), .cnt_up(cnt_up), .clear(clear), .one_k_samples(one_k_samples));
datapath path (.clk(clk), .n_reset(n_rst), .op(op), .src1(src1), .src2(src2), .dest(dest), .ext_data1(sample_data), .ext_data2(fir_coefficient), .outreg_data(outreg_data), .overflow(overflow));
magnitude mag (.in(outreg_data), .out(fir_out));

endmodule



