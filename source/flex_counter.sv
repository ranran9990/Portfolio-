`timescale 1ns / 10ps

module flex_counter #(
    parameter SIZE = 4
) (
    input logic clk,
    input logic n_rst,
    input logic clear,
    input logic count_enable,
    input logic [SIZE-1:0] rollover_val,
    output logic [SIZE-1:0] count_out,
    output logic rollover_flag
);

    logic [SIZE-1:0] count_next;
    logic rollover_next;

    always_ff @(posedge clk, negedge n_rst) begin
        if (~n_rst) begin
            count_out <= 'b0;
            rollover_flag <= 1'b0;
        end else begin
            count_out <= count_next;
            rollover_flag <= rollover_next;
        end
    end

    always_comb begin
        count_next = count_out;

        if (clear) begin
            count_next = 'b0;
        end else if (count_enable) begin
            count_next = count_out + 1'b1;

            if ((count_out >= rollover_val)) begin
                count_next = 'b1;
            end
        end
    end

    // always_comb begin
    //     if (count_out >= rollover_val) begin
    //         rollover_flag = 1'b1;
    //     end else begin
    //         rollover_flag = 1'b0;
    //     end
    // end

    always_comb begin
        if (count_next >= rollover_val) begin
            rollover_next = 1'b1;
        end else begin
            rollover_next = 1'b0;
        end
    end


endmodule


