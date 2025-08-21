`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_ahb_fir_filter ();

    localparam CLK_PERIOD = 2ns;

    logic clk, n_rst;
    logic hsel;
    logic [3:0] haddr;
    logic hsize;
    logic [1:0] htrans;
    logic hwrite;
    logic [15:0] hwdata;
    logic [15:0] hrdata;
    logic hresp;

ahb_fir_filter filter (.clk(clk),
                       .n_rst(n_rst),
                       .hsel(hsel),
                       .haddr(haddr),
                       .hsize(hsize),
                       .htrans(htrans),
                       .hwrite(hwrite),
                       .hwdata(hwdata),
                       .hrdata(hrdata),
                       .hresp(hresp));


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

    // bus model signals
    logic enqueue_transaction_en;
    logic transaction_write;
    logic transaction_fake;
    logic [3:0] transaction_addr;
    logic [15:0] transaction_data;
    logic transaction_error;
    logic [2:0] transaction_size;

    logic model_reset;
    logic enable_transactions;
    integer current_transaction_num;
    logic current_transaction_error;

    ahb_model BFM (.clk(clk),
        // Testing setup signals
        .enqueue_transaction(enqueue_transaction_en),
        .transaction_write(transaction_write),
        .transaction_fake(transaction_fake),
        .transaction_addr(transaction_addr),
        .transaction_data(transaction_data),
        .transaction_error(transaction_error),
        .transaction_size(transaction_size),
        // Testing controls
        .model_reset(model_reset),
        .enable_transactions(enable_transactions),
        .current_transaction_num(current_transaction_num),
        .current_transaction_error(current_transaction_error),
        // AHB-Subordinate Side
        .hsel(hsel),
        .htrans(htrans),
        .haddr(haddr),
        .hsize(hsize),
        .hwrite(hwrite),
        .hwdata(hwdata),
        .hrdata(hrdata),
        .hresp(hresp)
    );

    // bus model tasks
    task reset_model;
    begin
        model_reset = 1'b1;
        #(0.1);
        model_reset = 1'b0;
    end
    endtask
    
    task enqueue_transaction;
        input logic for_dut;
        input logic write_mode;
        input logic [3:0] address;
        input logic [15:0] data;
        input logic expected_error;
        input logic size;
    begin
        // Make sure enqueue flag is low (will need a 0->1 pulse later)
        enqueue_transaction_en = 1'b0;
        #(0.1ns);
    
        // Setup info about transaction
        transaction_fake  = ~for_dut;
        transaction_write = write_mode;
        transaction_addr  = address;
        transaction_data  = data;
        transaction_error = expected_error;
        transaction_size  = {2'b00,size};
    
        // Pulse the enqueue flag
        enqueue_transaction_en = 1'b1;
        #(0.1ns);
        enqueue_transaction_en = 1'b0;
    end
    endtask
    
    task execute_transactions;
        input integer num_transactions;
        integer wait_var;
    begin
        // Activate the bus model
        enable_transactions = 1'b1;
        @(posedge clk);
    
        // Process the transactions (all but last one overlap 1 out of 2 cycles
        for(wait_var = 0; wait_var < num_transactions; wait_var++) begin
            @(posedge clk);
        end
    
        // Run out the last one (currently in data phase)
        @(posedge clk);
    
        // Turn off the bus model
        @(negedge clk);
        enable_transactions = 1'b0;
    end
    endtask

    initial begin
        n_rst = 1;

        model_reset = 1'b0;
        enable_transactions = 1'b0;
        enqueue_transaction_en = 1'b0;
        transaction_write = 1'b0;
        transaction_fake = 1'b0;
        transaction_addr = '0;
        transaction_data = '0;
        transaction_error = 1'b0;
        transaction_size = 3'd0;

        reset_model();
        reset_dut();

        // send_packet(.data(8'hf), .stop_bit(1'b1), .data_period(20), .data_size(8));
        // fir_coefficient = 16'h8000;
        // fir_coefficient = 16'hC000;
        // fir_coefficient = 16'h4000;
        // fir_coefficient = 16'h2000;

        enqueue_transaction(.for_dut(1'b1), .size(1'b0), .write_mode(1'b1), .address(4'd14), .data(1'b1), .expected_error(1'b0));
        enqueue_transaction(.for_dut(1'b1), .size(1'b1), .write_mode(1'b1), .address(4'd6), .data(16'h8000), .expected_error(1'b0));
        execute_transactions(.num_transactions(2)); 
        #(CLK_PERIOD * 25);  

        enqueue_transaction(.for_dut(1'b1), .size(1'b0), .write_mode(1'b1), .address(4'd14), .data(1'b1), .expected_error(1'b0));
        enqueue_transaction(.for_dut(1'b1), .size(1'b1), .write_mode(1'b1), .address(4'd8), .data(16'hC000), .expected_error(1'b0));
        execute_transactions(.num_transactions(2)); 
        #(CLK_PERIOD * 25);  
    
        enqueue_transaction(.for_dut(1'b1), .size(1'b0), .write_mode(1'b1), .address(4'd14), .data(1'b1), .expected_error(1'b0));
        enqueue_transaction(.for_dut(1'b1), .size(1'b1), .write_mode(1'b1), .address(4'd10), .data(16'h4000), .expected_error(1'b0));
        execute_transactions(.num_transactions(2));   
        #(CLK_PERIOD * 25);  

        enqueue_transaction(.for_dut(1'b1), .size(1'b0), .write_mode(1'b1), .address(4'd14), .data(1'b1), .expected_error(1'b0));
        enqueue_transaction(.for_dut(1'b1), .size(1'b1), .write_mode(1'b1), .address(4'd12), .data(16'h2000), .expected_error(1'b0));
        execute_transactions(.num_transactions(2));   
        #(CLK_PERIOD * 25); 

        //Samples
        enqueue_transaction(.for_dut(1'b1), .size(1'b1), .write_mode(1'b1), .address(4'd4), .data(16'h1234), .expected_error(1'b0)); 
        execute_transactions(.num_transactions(1)); 
        #(CLK_PERIOD * 100);  
        enqueue_transaction(.for_dut(1'b1), .size(1'b1), .write_mode(1'b0), .address(4'd4), .data(16'h1234), .expected_error(1'b0));
        execute_transactions(.num_transactions(1)); 

        enqueue_transaction(.for_dut(1'b1), .size(1'b1), .write_mode(1'b1), .address(4'd4), .data(16'h2345), .expected_error(1'b0)); 
        execute_transactions(.num_transactions(1)); 
        #(CLK_PERIOD * 100);  
        enqueue_transaction(.for_dut(1'b1), .size(1'b1), .write_mode(1'b0), .address(4'd4), .data(16'h2345), .expected_error(1'b0));
        execute_transactions(.num_transactions(1)); 

        enqueue_transaction(.for_dut(1'b1), .size(1'b1), .write_mode(1'b1), .address(4'd4), .data(16'h4321), .expected_error(1'b0)); 
        execute_transactions(.num_transactions(1)); 
        #(CLK_PERIOD * 100);  
        enqueue_transaction(.for_dut(1'b1), .size(1'b1), .write_mode(1'b0), .address(4'd4), .data(16'h4321), .expected_error(1'b0));
        execute_transactions(.num_transactions(1)); 

        enqueue_transaction(.for_dut(1'b1), .size(1'b1), .write_mode(1'b1), .address(4'd4), .data(16'h3241), .expected_error(1'b0)); 
        execute_transactions(.num_transactions(1)); 
        #(CLK_PERIOD * 100);  
        enqueue_transaction(.for_dut(1'b1), .size(1'b1), .write_mode(1'b0), .address(4'd4), .data(16'h3241), .expected_error(1'b0));
        execute_transactions(.num_transactions(1)); 

        enqueue_transaction(.for_dut(1'b1), .size(1'b1), .write_mode(1'b1), .address(4'd4), .data(16'hFFFF), .expected_error(1'b0)); 
        execute_transactions(.num_transactions(1)); 
        #(CLK_PERIOD * 100);  
        enqueue_transaction(.for_dut(1'b1), .size(1'b1), .write_mode(1'b0), .address(4'd4), .data(16'hFFFF), .expected_error(1'b0));
        execute_transactions(.num_transactions(1)); 

        enqueue_transaction(.for_dut(1'b1), .size(1'b1), .write_mode(1'b1), .address(4'd4), .data(16'h8888), .expected_error(1'b0)); 
        execute_transactions(.num_transactions(1)); 
        #(CLK_PERIOD * 100);  
        enqueue_transaction(.for_dut(1'b1), .size(1'b1), .write_mode(1'b0), .address(4'd4), .data(16'h8888), .expected_error(1'b0));
        execute_transactions(.num_transactions(1)); 


        $finish;
    end
endmodule

/* verilator coverage_on */

