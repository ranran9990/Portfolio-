`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_fsm ();

    localparam CLK_PERIOD = 10ns;

    logic clk, n_rst, start, done, end_packet, const_select, load;
    logic [7:0] data_const, data_dyn, data_out;

    fsm state_machine(.clk(clk), .n_rst(n_rst), .start(start), .done(done), .end_packet(end_packet), .data_const(data_const), .data_dyn(data_dyn), .const_select(const_select), .load(load), .data_out(data_out));

    // Mimic the Grading TB's Constants Lookup Table
    assign data_const = const_select ? 8'hBB : 8'hAA;

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

    // input logic clk,
    // input logic n_rst,
    // input logic start,
    // input logic done,
    // input logic end_packet,
    // input logic [7:0] data_const,
    // input logic [7:0] data_dyn,
    // output logic const_select,
    // output logic load,
    // output logic [7:0] data_out


    initial begin
        n_rst = 1;
        start = 1'b0;
        done = 1'b0;
        end_packet = 1'b0;
        data_dyn = 8'b0;
        reset_dut();

        @(negedge clk);
        @(negedge clk);

        start = 1'b1;
        @(negedge clk);
        @(negedge clk);   

        done = 1'b1;
        @(negedge clk);
        @(negedge clk); 

        done = 1'b0;
        @(negedge clk);
        @(negedge clk);      

        done = 1'b1;
        @(negedge clk);
        @(negedge clk); 

        n_rst = 1'b0;
        done = 1'b0;
        @(negedge clk);
        @(negedge clk); 
        n_rst = 1'b1;
        @(negedge clk);     
        @(negedge clk);  






        start = 1'b1;
        @(negedge clk);
        @(negedge clk);   

        start = 1'b0;
        done = 1'b1;
        @(negedge clk);
        @(negedge clk); 

        done = 1'b0;
        @(negedge clk);
        @(negedge clk);      

        done = 1'b1;
        @(negedge clk);
        @(negedge clk); 

        done = 1'b0;
        end_packet = 1'b1;
        @(negedge clk);
        @(negedge clk);    

        done = 1'b1;
        @(negedge clk);
        @(negedge clk);

        done = 1'b0;
        end_packet = 1'b0;
        @(negedge clk);
        @(negedge clk);

        done = 1'b1;
        @(negedge clk);
        @(negedge clk);
        
        $finish;
    end
endmodule

/* verilator coverage_on */

