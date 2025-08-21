// TB for the 6-bit adder

`timescale 1ns / 10ps

module tb_adder_6bit ();

    localparam TEST_DELAY = 5;

    logic [5:0] a;
    logic [5:0] b;
    logic carry_in;
    logic [5:0] sum;
    logic carry_out;
    integer i;

    adder_6bit DUT(.a(a), .b(b), .carry_in(carry_in), 
        .sum(sum), .carry_out(carry_out));

    logic [12:0] test_inputs;

    // Connect individual test input bits to a vector for easier testing
    assign a        = test_inputs[5:0];
    assign b        = test_inputs[11:6];
    assign carry_in = test_inputs[12];

    // Test bench process
    initial
    begin
        // Initialize Inputs
        test_inputs = 13'h0;

        // Add For Loop Here! Make sure to wait #(TEST DELAY); between 
        // setting inputs and checking outputs for each iteration.
        for (i = 0; i < 8192; i++) begin
            test_inputs = i;
            #(TEST_DELAY);
            if (!(a + b + carry_in == {carry_out, sum})) begin
                $display("Incorrect output for inputs: %d", i);
            end
        end

        $finish;
    end
endmodule

