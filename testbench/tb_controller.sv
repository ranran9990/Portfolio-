`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_controller ();

    localparam CLK_PERIOD = 10ns;

    logic clk, n_rst, dr, lc, overflow, cnt_up, clear, modwait, err;
    logic [2:0] op;
    logic [3:0] src1, src2, dest;

controller control (.clk(clk), .n_rst(n_rst), .dr(dr), .lc(lc), .overflow(overflow), .cnt_up(cnt_up), .clear(clear), .modwait(modwait), .op(op), .src1(src1), .src2(src2), .dest(dest), .err(err));

    // clockgen
    always begin
        clk = 0;
        #(CLK_PERIOD / 2.0);
        clk = 1;
        #(CLK_PERIOD / 2.0);
    end

    task reset_dut;
    begin
        n_rst = 0;
        @(posedge clk);
        @(posedge clk);
        @(negedge clk);
        n_rst = 1;
        @(negedge clk);
        @(negedge clk);
    end
    endtask

    initial begin
        n_rst = 1;
        reset_dut();
        dr = 0;
        lc = 0;
        overflow = 0;

        //go to F0
        lc = 1;
        @(negedge clk);
        @(negedge clk);
        lc = 0;
        @(negedge clk);
        @(negedge clk);

        //go to F1
        lc = 1;
        @(negedge clk);
        @(negedge clk);
        lc = 0;
        @(negedge clk);
        @(negedge clk);

        //go to F2
        lc = 1;
        @(negedge clk);
        @(negedge clk);
        lc = 0;
        @(negedge clk);
        @(negedge clk);

        //go to F3
        lc = 1;
        @(negedge clk);
        @(negedge clk);
        lc = 0;
        @(negedge clk);
        @(negedge clk);

        //go to load_sample
        dr = 1;
        @(negedge clk);

        //go to error
        dr = 0;
        @(negedge clk);
        @(negedge clk);

        //go to load_sample
        dr = 1;
        @(negedge clk);
        @(negedge clk);
        dr = 0;

        //Shift sample, operations
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);

        dr = 1;
        @(negedge clk);
        dr = 0;
        @(negedge clk);
        @(negedge clk);
        lc = 1;
        @(negedge clk);
        @(negedge clk);
        lc = 0;
        @(negedge clk);
        @(negedge clk);
        lc = 1;
        @(negedge clk);
        @(negedge clk);
        
        








        $finish;
    end
endmodule

/* verilator coverage_on */

