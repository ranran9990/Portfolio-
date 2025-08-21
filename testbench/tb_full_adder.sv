// TB for the 1-bit adder

`timescale 1ns / 10ps

module tb_full_adder ();

    localparam TEST_DELAY = 5;

    logic a;
    logic b;
    logic carry_in;
    logic sum;
    logic carry_out;
    integer i;


    full_adder DUT(.a(a), .b(b), .carry_in(carry_in), 
        .sum(sum), .carry_out(carry_out));

    logic [2:0] test_inputs;

    // Connect individual test input bits to a vector for easier testing
    assign a        = test_inputs[0];
    assign b        = test_inputs[1];
    assign carry_in = test_inputs[2];

    // Test bench process
    initial
    begin
        // Initialize Inputs
        test_inputs = 3'b000;

        // Add For Loop Here! Make sure to wait #(TEST DELAY); between 
        // setting inputs and checking outputs for each iteration.

        for (i = 0; i < 8; i++) begin
            test_inputs = i;
            #(TEST_DELAY);
            if (!(a + b + carry_in == {carry_out, sum})) begin
                $display("Incorrect output for inputs: %d", i);
            end
        end
        $finish;
    end
endmodule

