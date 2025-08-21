// 337 TA Provided Lab 4 Testbench

// 0.5um D-FlipFlop Timing Data Estimates:
// Data Propagation delay (clk->Q): 670ps
// Setup time for data relative to clock: 190ps
// Hold time for data relative to clock: 10ps

`timescale 1ns / 10ps

module tb_sync();

  parameter sync_type = 0;

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
  logic async_in, sync_out;

  /* verilator lint_off GENUNNAMED */
  generate
    if(sync_type == 1)      sync_low DUT (.clk(clk), .n_rst(n_rst), .async_in(async_in), .sync_out(sync_out));
    else if(sync_type == 2) sync_high DUT (.clk(clk), .n_rst(n_rst), .async_in(async_in), .sync_out(sync_out));
    else initial begin
      $display("ERROR: Incorrect sync type specified: %d", sync_type);
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

  // Task to cleanly and consistently check DUT output values
  task check_output;
    input logic expected_out; // Expected output for DUT
    input logic meta; // If a setup/hold violation was intentionally triggered
    input string case_info;
    begin
      check_pulse = 1;
      if((expected_out == sync_out) || (meta && (sync_out == 1'b0 || sync_out == 1'b1))) $write("%sPassed %s: ", COLGRN, COLNRM);
      else $write("%sFailed %s: ", COLRED, COLNRM);
      $display("%s", case_info);
      #(0.1ns);
      check_pulse = 0;
    end
  endtask

  task reset_inputs;
    async_in = (sync_type == 2);
  endtask

  task init;
    reset_inputs();
    n_rst = 1'b1;
    test_name = "";
    check_pulse = 0;
    #(0.1); // Wait for first Test Case
  endtask
  
  // Test bench main process
  initial
  begin
    $display("%sTiming Violations Errors are Expected on Synthesized Simulation%s", COLCYA, COLNRM);
    init();
    
    // *******************
    // Manual Reset
    // *******************
    
    n_rst = 1'b0;
    @(negedge clk);
    @(negedge clk);
    n_rst = 1'b1;
    @(negedge clk);

    // Check after reset hits, cycle of reset held, and pre-clock cycle after released
    check_output((sync_type == 2), 1'b0, "Manual Reset");
    
    // ************************************************************************
    // Test Case 2: Normal Operation with Input as a '0'
    // ************************************************************************
    test_name = "Normal Operation with Input as a '0'";
    reset_inputs();
    reset_dut();
    async_in = 1'b0;
    @(negedge clk);
    @(posedge clk);
    #(CHECK_DELAY);
    check_output(1'b0, 1'b0, "Normal Input 0");

    @(posedge clk);
    // ************************************************************************
    // Test Case 2.5: Normal Operation with Input as a '1'
    // ************************************************************************
    test_name = "Normal Operation with Input as a '1'";
    reset_inputs();
    reset_dut();
    async_in = 1'b1;
    @(negedge clk);
    @(posedge clk);
    #(CHECK_DELAY);
    check_output(1'b1, 1'b0, "Normal Input 1");

    @(posedge clk);
    // ************************************************************************
    // Test Case 3: Setup Violation with Input as a '0'
    // ************************************************************************
    test_name = "Setup Violation with Input as a '0'";
    reset_inputs();
    reset_dut();
    async_in = 1'b1;
    @(posedge clk)
    #(CLK_PERIOD - (FF_SETUP_TIME / 2))
    async_in = 1'b0;
    @(negedge clk);
    @(posedge clk);
    #(CHECK_DELAY);
    check_output(1'b0, 1'b1, "Setup Violation 0");

    @(posedge clk)
    // ************************************************************************
    // Test Case 3.5: Setup Violation with Input as a '1'
    // ************************************************************************
    test_name = "Setup Violation with Input as a '1'";
    reset_inputs();
    reset_dut();
    async_in = 1'b0;
    @(posedge clk)
    #(CLK_PERIOD - (FF_SETUP_TIME / 2))
    async_in = 1'b1;
    @(negedge clk);
    @(posedge clk);
    #(CHECK_DELAY);
    check_output(1'b1, 1'b1, "Setup Violation 1");
  
    @(posedge clk)
    // ************************************************************************
    // Test Case 4: Hold Violation with Input as a '0'
    // ************************************************************************
    test_name = "Hold Violation with Input as a '0'";
    reset_inputs();
    reset_dut();
    async_in = 1'b1;
    @(posedge clk)
    #(CLK_PERIOD + (FF_HOLD_TIME / 2))
    async_in = 1'b0;
    @(negedge clk);
    @(posedge clk);
    #(CHECK_DELAY);
    check_output(1'b0, 1'b1, "Hold Violation 0");

    @(posedge clk)
    // ************************************************************************
    // Test Case 4.5: Hold Violation with Input as a '1'
    // ************************************************************************
    test_name = "Hold Violation with Input as a '1'";
    reset_inputs();
    reset_dut();
    async_in = 1'b0;
    @(posedge clk)
    #(CLK_PERIOD + (FF_HOLD_TIME / 2))
    async_in = 1'b1;
    @(negedge clk);
    @(posedge clk);
    #(CHECK_DELAY);
    check_output(1'b1, 1'b1, "Hold Violation 1");
    
    $finish;
  end
endmodule
