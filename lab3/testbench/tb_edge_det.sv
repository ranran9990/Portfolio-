// 337 TA Provided Lab 4 Starter Testbench

// 0.5um D-FlipFlop Timing Data Estimates:
// Data Propagation delay (clk->Q): 670ps
// Setup time for data relative to clock: 190ps
// Hold time for data relative to clock: 10ps

`timescale 1ns / 10ps

module tb_edge_det();

  parameter edge_type = 0;

  localparam COLNRM = "\x1B[0m";
  localparam COLRED = "\x1B[31m";
  localparam COLGRN = "\x1B[32m";
  localparam COLCYA = "\x1B[36m";

  // Define local parameters used by the test bench
  localparam  CLK_PERIOD    = 1;
  localparam  FF_SETUP_TIME = 0.190;
  localparam  FF_HOLD_TIME  = 0.100;
  // Propagation Delay clk->q is 0.57ns or 0.65ns per Tech Lib, l->h, h->l
  localparam  CHECK_DELAY   = (CLK_PERIOD - FF_SETUP_TIME); // Check right before the setup time starts
  
  string test_name;
  logic check_pulse;

  // Declare DUT portmap signals
  logic clk, n_rst;
  logic async_in, sync_out, edge_flag;

  /* verilator lint_off GENUNNAMED */
  generate
    if(edge_type == 1)      edge_rise DUT (.clk(clk), .n_rst(n_rst), .async_in(async_in), .sync_out(sync_out), .edge_flag(edge_flag));
    else if(edge_type == 2) edge_dual DUT (.clk(clk), .n_rst(n_rst), .async_in(async_in), .sync_out(sync_out), .edge_flag(edge_flag));
    else initial begin
      $display("ERROR: Incorrect sync type specified: %d", edge_type);
      $stop;
    end
  endgenerate
  /* verilator lint_on GENUNNAMED */

  // Clock generation block
  always
  begin
    // Start with clock low to avoid false rising edge events at t=0
    clk = 1'b0;
    // Wait half of the clock period before toggling clock value (maintain 50% duty cycle)
    #(CLK_PERIOD/2.0);
    clk = 1'b1;
    // Wait half of the clock period before toggling clock value via rerunning the block (maintain 50% duty cycle)
    #(CLK_PERIOD/2.0);
  end
  
  // Task for standard DUT reset procedure
  task reset_dut;
  begin
    // Activate the reset
    n_rst = 1'b0;

    // Maintain the reset for more than one cycle
    @(posedge clk);
    @(posedge clk);

    // Wait until safely away from rising edge of the clock before releasing
    @(negedge clk);
    n_rst = 1'b1;

    // Leave out of reset for a couple cycles before allowing other stimulus
    // Wait for negative clock edges, 
    // since inputs to DUT should normally be applied away from rising clock edges
    @(negedge clk);
    @(negedge clk);
  end
  endtask

  task reset_inputs;
    async_in = 0;
  endtask

  task init;
    reset_inputs();
    n_rst = 1'b1;
    test_name = "";
    check_pulse = 0;
    #(0.1); // Wait for first Test Case
  endtask
  
  // Test bench main process
  integer i;

  initial
  begin
    async_in = 1'b0;
    reset_dut();
    init();
    async_in = 1'b1;
    @(negedge clk);
    @(negedge clk);
    
    async_in = 1'b0;
    @(negedge clk);
    @(negedge clk);

    async_in = 1'b1;
    @(negedge clk);
    @(negedge clk);
    
    $finish;
  end
endmodule
