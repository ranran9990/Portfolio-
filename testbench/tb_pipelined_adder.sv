`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_pipelined_adder ();

  localparam COLNRM = "\x1B[0m";
  localparam COLRED = "\x1B[31m";
  localparam COLGRN = "\x1B[32m";
  localparam COLBLUE = "\x1B[34m";

  localparam DFF_SETUP_TIME = 0.6ns;
  localparam DFF_HOLD_TIME = 0.6ns;
  localparam TIME_MARGIN = 0.2ns;

  //***** Student Fill-In *****//
  localparam COMB_PATH = 47.65; // Report says 63.96
  localparam PIPELINE_PATH = 12.83; // Report says 16.61
  //***** Student Fill-In *****//

  localparam COMB_DELAY = COMB_PATH + TIME_MARGIN;
  localparam PIPELINE_DELAY = PIPELINE_PATH + TIME_MARGIN;
  localparam PIPELINE_PERIOD = DFF_HOLD_TIME + PIPELINE_DELAY + DFF_SETUP_TIME;

  localparam MAX32 = 32'hFFFF_FFFF;
  localparam bit[127:0] MAX128 = '1;

  logic clk, n_rst;
  logic [128:0] comb_sum, pipe_sum;
  logic [127:0] comb_a, comb_b, pipe_a, pipe_b;

  // clockgen
  always begin
    clk = 0;
    #(PIPELINE_PERIOD / 2.0);
    clk = 1;
    #(PIPELINE_PERIOD / 2.0);
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

  task init;
  begin
    n_rst = 1;
    comb_a = 128'b0;
    comb_b = 128'b0;
    pipe_a = 128'b0;
    pipe_b = 128'b0;
  end
  endtask

  logic comb_pulse = 0;
  logic pipe_pulse = 0;

  task check_comb;
    input logic [128:0] exp_comb_sum;
    input string tc_disp;
  begin
    comb_pulse = 1;
    if(comb_sum == exp_comb_sum) $write("%sSuccess%s for the ", COLGRN, COLNRM);
    else                         $write("%sFailure%s for the ", COLRED, COLNRM);
    $write("%s test case for the combinational adder.", tc_disp);
    if(comb_sum != exp_comb_sum) $write("\n\tExpected %s %0d %s, got %s %0d %s.", COLGRN, exp_comb_sum[15:0], COLNRM, COLRED, comb_sum[15:0], COLNRM);
    if(comb_sum != exp_comb_sum) $write("\n\tTime: %0d ns.", $stime);
    $display(); // \n

    #0.1;
    comb_pulse = 0;
  end
  endtask

  task check_pipe;
    input logic [128:0] exp_pipe_sum;
    input string tc_disp;
  begin
    pipe_pulse = 1;
    if(pipe_sum == exp_pipe_sum) $write("%cking synthesis log for errors and warnings...
Warning: In design 'adder_128bit', a pin on submodule 'nbit' is connected to logic 1 or logic 0. (LINT-32)
Storing the netlist for the u337mg136:ece337:adder_128bit design...
sSuccess%s for the ", COLGRN, COLNRM);
    else                         $write("%sFailure%s for the ", COLRED, COLNRM);
    $write("%s test case for the pipelined adder", tc_disp);
    if(pipe_sum != exp_pipe_sum) $write("\n\tExpected %s %0d %s, got %s %0d %s.", COLGRN, exp_pipe_sum[15:0], COLNRM, COLRED, pipe_sum[15:0], COLNRM);
    if(pipe_sum != exp_pipe_sum) $write("\n\tTime: %0d ns.", $stime);
    $display(); // \n
    
    #0.1;
    pipe_pulse = 0;
  end
  endtask

  task comb_set;
    input logic [127:0] csa;
    input logic [127:0] csb;
  begin
    n_rst = 1;
    comb_a = csa;
    comb_b = csb;
  end
  endtask

  task pipe_set;
    input logic [127:0] psa;
    input logic [127:0] psb;
  begin
    n_rst = 1;
    pipe_a = psa;
    pipe_b = psb;
  end
  endtask

  adder_comparison DUT (.clk(clk), .n_rst(n_rst), .a({pipe_a, comb_a}), .b({pipe_b, comb_b}), .s({pipe_sum, comb_sum}));

  initial begin
    $display(); // Easy newline character to print terminal space
    init();

    $display("%sCombinational Accumulator:%s %3.2f ns in->out path delay.", COLGRN, COLNRM, COMB_PATH);
    $display("%sPipelined Accumulator:    %s %3.2f ns FF->FF  path delay.", COLBLUE, COLNRM, PIPELINE_PERIOD);
    $display();

    // Reset Case
    reset_dut();
    fork
      begin: COMB_A
        check_comb(129'd0, "reset DUT");
      end
      begin: PIPELINE_A
        check_pipe(129'd0, "reset DUT");
      end
    join

    // Low Magnitude Add
    init();
    reset_dut();
    fork
      begin: COMB_B
        comb_set(128'd2, 128'd5);
        #(COMB_DELAY);
        check_comb(129'd7, "low magnitude add");
      end
      begin: PIPELINE_B
        pipe_set(128'd3, 128'd6);
        @(negedge clk); // Latch 1
        @(negedge clk); // Latch 2
        @(negedge clk); // Latch 3
        #(PIPELINE_DELAY); // Flow all values through
        check_pipe(129'd9, "low magnitude add");
      end
    join
    @(negedge clk);

    // Large Magnitude Mult
    init();
    reset_dut();
    fork
      begin: COMB_C
        comb_set(MAX128, MAX128);
        #(COMB_DELAY);
        check_comb({MAX128,1'b0}, "max add");
      end
      begin: PIPELINE_C
        pipe_set(MAX128, MAX128);
        @(negedge clk); // Latch 1
        @(negedge clk); // Latch 2
        @(negedge clk); // Latch 3
        #(PIPELINE_DELAY); // Flow all values through
        check_pipe({MAX128,1'b0}, "max add");
      end
    join
    @(negedge clk);

    // Multi-Add
    init();
    reset_dut();
    fork
      begin: COMB_D
        comb_set(128'd2, 128'd5);
        #(COMB_DELAY);
        check_comb(129'd7, "Add #1");
        comb_set(128'd8, 128'd12);
        #(COMB_DELAY);
        check_comb(129'd20, "Add #2");
        comb_set(128'd45, 128'd59);
        #(COMB_DELAY);
        check_comb(129'd104, "Add #3");
        comb_set(128'd13, 128'd0);
        #(COMB_DELAY);
        check_comb(129'd13, "Add #4");
      end
      begin: PIPELINE_D
        pipe_set(128'd2, 128'd5);
        @(negedge clk);
        pipe_set(128'd8, 128'd12);
        @(negedge clk);
        pipe_set(128'd45, 128'd59);
        @(negedge clk);
        pipe_set(128'd13, 128'd0);
        @(negedge clk);
      end
      begin: PIPELINE_D_CHECK
        @(posedge clk); // latch 1
        @(posedge clk); // latch 2
        @(posedge clk); // latch 3
        #(PIPELINE_DELAY);
        check_pipe(129'd7, "Add #1");
        @(posedge clk);
        #(PIPELINE_DELAY);
        check_pipe(129'd20, "Add #2");
        @(posedge clk);
        #(PIPELINE_DELAY);
        check_pipe(129'd104, "Add #3");
        @(posedge clk);
        #(PIPELINE_DELAY);
        check_pipe(129'd13, "Add #4");
      end
    join
    @(negedge clk);

    $display();
    $finish();
  end
endmodule

/* verilator coverage_on */

