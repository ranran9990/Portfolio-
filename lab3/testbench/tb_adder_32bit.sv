`timescale 1ns / 10ps

module tb_adder_32bit ();

    // -- allows the testbench to have different DUTs. DO NOT MODIFY --
    parameter adder_type = 0;

    logic [31:0] a;
    logic [31:0] b;
    logic carry_in;
    logic [31:0] sum;
    logic carry_out;

    /* verilator lint_off GENUNNAMED */
    generate
        if(adder_type == 1)      adder_32bit_param #() DUT (.a(a), .b(b), .carry_in(carry_in), .sum(sum), .carry_out(carry_out));
        else if(adder_type == 2) adder_32bit_auto  #() DUT (.a(a), .b(b), .carry_in(carry_in), .sum(sum), .carry_out(carry_out));
        else initial begin
            $display("ERROR: Incorrect adder type specified: %d", adder_type);
            $stop;
        end
    endgenerate
    /* verilator lint_on GENUNNAMED */
    
    // -- student code below this line --

    localparam TEST_DELAY = 5ns;

    localparam NUM_TEST_CASES = 9;

    typedef struct {
        logic [31:0] a ;
        logic [31:0] b ;
        logic carry_in ;
        logic [31:0] exp_sum ;
        logic exp_carry_out ; 
        } testVector_t ;
        
        testVector_t test_vec [ NUM_TEST_CASES ];
        
        task set_tv ;
            input logic [31:0] tv_a ;
            input logic [31:0] tv_b ;
            input logic tv_cin ;
            input integer idx ;
        begin
            automatic logic [32:0] tv_sum ;
            tv_sum = tv_a + tv_b + tv_cin ;

            test_vec [ idx ]. a = tv_a ;
            test_vec [ idx ]. b = tv_b ;
            test_vec [ idx ]. carry_in = tv_cin ;
            test_vec [ idx ]. exp_sum = tv_sum [31:0];
            test_vec [ idx ]. exp_carry_out = tv_sum [32];
        end
        endtask
    
        integer i;

    initial begin
        #(1ns);
        
        set_tv(.tv_a(32'hFFFFFFFF), .tv_b(32'hFFFFFFFF), .tv_cin(1), .idx(0));
        set_tv(.tv_a(32'h00000000), .tv_b(32'h00000000), .tv_cin(0), .idx(1));
        set_tv(.tv_a(32'hFFFFFFFF), .tv_b(32'h00000000), .tv_cin(1), .idx(2));
        set_tv(.tv_a(32'h00000000), .tv_b(32'hFFFFFFFF), .tv_cin(0), .idx(3));
        set_tv(.tv_a(32'hFFFFFFFF), .tv_b(32'h00000000), .tv_cin(0), .idx(4));
        set_tv(.tv_a(32'h00000000), .tv_b(32'hFFFFFFFF), .tv_cin(1), .idx(5));
        set_tv(.tv_a(32'h00000000), .tv_b(32'hFFFFFFFF), .tv_cin(1), .idx(6));
        set_tv(.tv_a(32'hFFFFFFFF), .tv_b(32'hFFFFFFFF), .tv_cin(0), .idx(7));

        for(i = 0; i < 8; i++) begin
            a = test_vec[i].a;
            b = test_vec[i].b;
            carry_in = test_vec[i].carry_in;
            #(TEST_DELAY);
            if(test_vec[i].exp_sum != sum || test_vec[i].exp_carry_out != carry_out) begin
                $display("Expected carryout: %d, expected sum: %d. actual carryout: %d, actual sum: %d", test_vec[i].exp_carry_out, test_vec[i].exp_sum, carry_out, sum);
            end
        end

        $finish;
    end

endmodule

