`timescale 1ns / 10ps

module apb_subordinate #(
    // parameters
) (
    input logic clk,
    input logic n_rst,
    input logic [7:0] rx_data,
    input logic data_ready,
    input logic overrun_error,
    input logic framing_error,
    input logic psel,
    input logic [2:0] paddr,
    input logic penable,
    input logic pwrite,
    input logic [7:0] pwdata,
    output logic data_read,
    output logic [7:0] prdata,
    output logic psaterr,
    output logic [3:0] data_size,
    output logic [13:0] bit_period
);

logic [7:0] next_write2, 
            next_write3, 
            next_write4, 
            next_prdata,
            bit_period1,
            bit_period2;

always_ff @(posedge clk, negedge n_rst) begin
    if (~n_rst) begin
        prdata <= 8'b0;
        bit_period1 <= 8'd10;
        bit_period2 <= 8'b0;
        data_size <= 4'b0;
    end else begin
        prdata <= next_prdata;
        bit_period1 <= next_write2;
        bit_period2 <= next_write3;
        data_size <= next_write4[3:0];
    end
end

//next_state logic
always_comb begin
    next_write2 = bit_period1;
    next_write3 =  bit_period2;
    next_write4 = {4'b0, data_size};
    next_prdata = 8'b0;
    data_read = 1'b0;
    psaterr = 1'b0;

    if ((((paddr == 3'd0) || (paddr == 3'd1) || (paddr == 3'd6)) && pwrite) || ((paddr == 3'd5) || (paddr == 3'd7))) begin
        psaterr = 1'b1;
    end

    if (psel && ~pwrite) begin
        case (paddr) 
            3'd0: begin
                next_prdata = {7'b0, data_ready};
                data_read = 1'b0;
            end

            3'd1: begin
                next_prdata = {6'b0, overrun_error, framing_error};
                data_read = 1'b0;
            end

            3'd6: begin
                next_prdata = rx_data;
                data_read = 1'b1;
            end

            3'd2: begin
                next_prdata = bit_period1;
                data_read = 1'b0;
            end

            3'd3: begin
                next_prdata = bit_period2;
                data_read = 1'b0;
            end

            3'd4: begin
                next_prdata = {4'b0, data_size};
                data_read = 1'b0;
            end

            default: begin
                next_prdata = 8'b0;  
                data_read = 1'b0;  
            end             
        endcase
    end

    if (psel && penable && pwrite) begin
        case (paddr)
            3'd2: next_write2 = pwdata;
            3'd3: next_write3 = pwdata;
            3'd4: next_write4 = pwdata;

            default: begin
                next_write2 = bit_period1;
                next_write3 = bit_period2;
                next_write4 = {4'b0, data_size};
            end
        endcase
    end
end

//output logic
always_comb begin
    bit_period = {bit_period2[5:0], bit_period1};
end


endmodule

