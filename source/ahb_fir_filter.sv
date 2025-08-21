`timescale 1ns / 10ps

module ahb_fir_filter (
    input logic clk,
    input logic n_rst,
    input logic hsel,
    input logic [3:0] haddr,
    input logic hsize,
    input logic [1:0] htrans,
    input logic hwrite,
    input logic [15:0] hwdata,
    output logic [15:0] hrdata,
    output logic hresp
);
  
logic [15:0] fir_out, sample_data, fir_coefficient;
logic load_coeff, err, data_ready, modwait, new_coefficient_set, clear_coeff;
logic [1:0] coefficient_num;

fir_filter filter (.clk(clk),
                   .n_rst(n_rst),
                   .sample_data(sample_data),
                   .fir_coefficient(fir_coefficient),
                   .load_coeff(load_coeff),
                   .data_ready(data_ready),
                   .one_k_samples(),
                   .modwait(modwait),
                   .fir_out(fir_out),
                   .err(err));

coefficient_loader loader (.clk(clk),
                           .n_rst(n_rst),
                           .new_coefficient_set(new_coefficient_set),
                           .modwait(modwait),
                           .load_coeff(load_coeff),
                           .coefficient_num(coefficient_num),
                           .clear_coeff(clear_coeff));

ahb_subordinate subordinate (.clk(clk),
                             .n_rst(n_rst),
                             .clear_coeff(clear_coeff),
                             .coefficient_num(coefficient_num),
                             .modwait(modwait),
                             .fir_out(fir_out),
                             .err(err),
                             .hsel(hsel),
                             .haddr(haddr),
                             .hsize(hsize),
                             .htrans(htrans),
                             .hwrite(hwrite),
                             .hwdata(hwdata),
                             .sample_data(sample_data),
                             .data_ready(data_ready),
                             .new_coefficient_set(new_coefficient_set),
                             .fir_coefficient(fir_coefficient),
                             .hrdata(hrdata),
                             .hresp(hresp));
endmodule

