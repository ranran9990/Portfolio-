`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_magnitude ();

logic [16:0] outreg_data;
logic [15:0] fir_out;

magnitude mag (.in(outreg_data), .out(fir_out));

    initial begin
        outreg_data = '0;
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        outreg_out = 17'b10101010101010101;
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        outreg_out = 17'b01101011010110101;
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);



        $finish;
    end
endmodule

/* verilator coverage_on */

