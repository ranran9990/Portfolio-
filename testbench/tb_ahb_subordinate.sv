`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_ahb_subordinate ();

    localparam CLK_PERIOD = 2ns;

    logic clk, n_rst;
    logic clear_coeff;
    logic [1:0] coefficient_num;
    logic modwait;
    logic [15:0] fir_out;
    logic err;
    logic hsel;
    logic [3:0] haddr;
    logic hsize;
    logic [1:0] htrans;
    logic hwrite;
    logic [15:0] hwdata;
    logic [15:0] sample_data;
    logic data_ready;
    logic new_coefficient_set;
    logic [15:0] fir_coefficient;
    logic [15:0] hrdata;
    logic hresp;

    ahb_subordinate subordinate (.clk(clk),
                             .n_rst(n_rst),
                             .clear_coeff(clear_coeff),
                             .coefficient_num(coefficient_num),
                             .modwait(modwait),
                             .fir_out(fir_out),
                             .err(err),
                             .hsel(hsel),
                             .haddr(haddr),
                             .hsize(hsize),
                             .htrans(htrans),
                             .hwrite(hwrite),
                             .hwdata(hwdata),
                             .sample_data(sample_data),
                             .data_ready(data_ready),
                             .new_coefficient_set(new_coefficient_set),
                             .fir_coefficient(fir_coefficient),
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
        fir_out = '0;
        modwait = '0;
        err = '0;
        clear_coeff = '0;
        coefficient_num = '0;

        reset_model();
        reset_dut();

        //Write/Read Result Register
        fir_out = 16'habcd;
        #(CLK_PERIOD * 10);
       // enqueue_transaction(.for_dut(1'b1), .size(1'b1), .write_mode(1'b1), .address(4'd2), .data(16'hbbbb), .expected_error(1'b1));
       // execute_transactions(.num_transactions(1));
       // #(CLK_PERIOD * 100);
        enqueue_transaction(.for_dut(1'b1), .size(1'b1), .write_mode(1'b0), .address(4'd2), .data(16'habcd), .expected_error(1'b0));
        execute_transactions(.num_transactions(1));
        #(CLK_PERIOD * 20);

        //Write Status Register
        #(CLK_PERIOD * 10);
        enqueue_transaction(.for_dut(1'b1), .size(1'b1), .write_mode(1'b1), .address(4'd0), .data(16'd1), .expected_error(1'b1));
        execute_transactions(.num_transactions(1));
        modwait = 1;
        #(CLK_PERIOD * 100);
        enqueue_transaction(.for_dut(1'b1), .size(1'b1), .write_mode(1'b0), .address(4'd2), .data(16'd0), .expected_error(1'b0));
        execute_transactions(.num_transactions(1));
        #(CLK_PERIOD * 20);

        //Read Status Register
        err = 1;
        #(CLK_PERIOD * 10);
        enqueue_transaction(.for_dut(1'b1), .size(1'b1), .write_mode(1'b1), .address(4'd0), .data(16'd1), .expected_error(1'b1));
        execute_transactions(.num_transactions(1));
        #(CLK_PERIOD * 100);
        enqueue_transaction(.for_dut(1'b1), .size(1'b1), .write_mode(1'b0), .address(4'd0), .data(16'habcd), .expected_error(1'b0));
        execute_transactions(.num_transactions(1));
        #(CLK_PERIOD * 20);

        //Read/Write sample Register
        #(CLK_PERIOD * 10);
        enqueue_transaction(.for_dut(1'b1), .size(1'b1), .write_mode(1'b1), .address(4'd4), .data(16'd1), .expected_error(1'b0));
        execute_transactions(.num_transactions(1));
        #(CLK_PERIOD * 100);
        enqueue_transaction(.for_dut(1'b1), .size(1'b1), .write_mode(1'b0), .address(4'd4), .data(16'habcd), .expected_error(1'b0));
        execute_transactions(.num_transactions(1));
        #(CLK_PERIOD * 20);

        //Read/write F0 Coefficient Register
        #(CLK_PERIOD * 10);
        enqueue_transaction(.for_dut(1'b1), .size(1'b1), .write_mode(1'b1), .address(4'd6), .data(16'd1), .expected_error(1'b0));
        execute_transactions(.num_transactions(1));
        #(CLK_PERIOD * 100);
        enqueue_transaction(.for_dut(1'b1), .size(1'b1), .write_mode(1'b0), .address(4'd6), .data(16'habcd), .expected_error(1'b0));
        execute_transactions(.num_transactions(1));
        #(CLK_PERIOD * 20);

        //Read/write F1 Coefficient Register
        #(CLK_PERIOD * 10);
        enqueue_transaction(.for_dut(1'b1), .size(1'b1), .write_mode(1'b1), .address(4'd8), .data(16'd1), .expected_error(1'b0));
        execute_transactions(.num_transactions(1));
        #(CLK_PERIOD * 100);
        enqueue_transaction(.for_dut(1'b1), .size(1'b1), .write_mode(1'b0), .address(4'd8), .data(16'habcd), .expected_error(1'b0));
        execute_transactions(.num_transactions(1));
        #(CLK_PERIOD * 20);

        //Read/write F2 Coefficient Register
        #(CLK_PERIOD * 10);
        enqueue_transaction(.for_dut(1'b1), .size(1'b1), .write_mode(1'b1), .address(4'd10), .data(16'd1), .expected_error(1'b0));
        execute_transactions(.num_transactions(1));
        #(CLK_PERIOD * 100);
        enqueue_transaction(.for_dut(1'b1), .size(1'b1), .write_mode(1'b0), .address(4'd10), .data(16'habcd), .expected_error(1'b0));
        execute_transactions(.num_transactions(1));
        #(CLK_PERIOD * 20);

        //Read/write F3 Coefficient Register
        #(CLK_PERIOD * 10);
        enqueue_transaction(.for_dut(1'b1), .size(1'b1), .write_mode(1'b1), .address(4'd12), .data(16'd1), .expected_error(1'b0));
        execute_transactions(.num_transactions(1));
        #(CLK_PERIOD * 100);
        enqueue_transaction(.for_dut(1'b1), .size(1'b1), .write_mode(1'b0), .address(4'd12), .data(16'habcd), .expected_error(1'b0));
        execute_transactions(.num_transactions(1));
        #(CLK_PERIOD * 20);

        //Read/write New Coefficient Register
        #(CLK_PERIOD * 10);
        enqueue_transaction(.for_dut(1'b1), .size(1'b1), .write_mode(1'b1), .address(4'd12), .data(16'd1), .expected_error(1'b0));
        execute_transactions(.num_transactions(1));
        #(CLK_PERIOD * 100);
        enqueue_transaction(.for_dut(1'b1), .size(1'b1), .write_mode(1'b0), .address(4'd12), .data(16'habcd), .expected_error(1'b0));
        execute_transactions(.num_transactions(1));
        #(CLK_PERIOD * 20);


        enqueue_transaction(.for_dut(1'b1), .size(1'b1), .write_mode(1'b1), .address(4'd10), .data(16'hffff), .expected_error(1'b0));
        enqueue_transaction(.for_dut(1'b1), .size(1'b1), .write_mode(1'b0), .address(4'd10), .data(16'hffff), .expected_error(1'b0));
        execute_transactions(.num_transactions(2));

        $finish;
    end
endmodule

/* verilator coverage_on */

