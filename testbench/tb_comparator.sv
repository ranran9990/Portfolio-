`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_comparator ();
    logic [7:0] a;
    logic [7:0] b;
    logic gt;
    logic lt;
    logic eq;

    comparator DUT (.a(a), .b(b), .gt(gt), .lt(lt), .eq(eq));

    initial begin
        a = 8'h0;
        b = 8'h0;
        #(5ns);
        a = 8'h1;
        b = 8'h0;
        #(5ns);
        a = 8'h0;
        b = 8'h1;
        #(5ns);
        $finish;
    end
endmodule

/* verilator coverage_on */

