`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_apb_subordinate ();

    localparam CLK_PERIOD = 10ns;

    logic clk, n_rst;
    logic [7:0] rx_data;
    logic data_ready;
    logic overrun_error;
    logic framing_error;
    logic psel;
    logic [2:0] paddr;
    logic penable;
    logic pwrite;
    logic [7:0] pwdata;
    logic data_read;
    logic [7:0] prdata;
    logic psaterr;
    logic [3:0] data_size;
    logic [13:0] bit_period;


apb_subordinate sub(.clk(clk),
                    .n_rst(n_rst), 
                    .rx_data(rx_data), 
                    .data_ready(data_ready),
                    .overrun_error(overrun_error),
                    .framing_error(framing_error),
                    .psel(psel),
                    .paddr(paddr),
                    .penable(penable),
                    .pwrite(pwrite),
                    .pwdata(pwdata),
                    .data_read(data_read),
                    .prdata(prdata),
                    .psaterr(psaterr),
                    .data_size(data_size),
                    .bit_period(bit_period));


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
    logic [2:0] transaction_addr;
    logic [7:0] transaction_data;
    logic transaction_error;
    
    logic model_reset;
    logic enable_transactions;
    integer current_transaction_num;

    // logic psel;
    // logic [2:0] paddr;
    // logic penable;
    // logic pwrite;
    // logic [7:0] pwdata;
    // logic [7:0] prdata;
    // logic psaterr;

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
        input logic [2:0] address;
        input logic [7:0] data;
        input logic expected_error;
    begin
        // Make sure enqueue flag is low (will need a 0->1 pulse later)
        enqueue_transaction_en = 1'b0;
        #0.1ns;

        // Setup info about transaction
        transaction_fake  = ~for_dut;
        transaction_write = write_mode;
        transaction_addr  = address;
        transaction_data  = data;
        transaction_error = expected_error;

        // Pulse the enqueue flag
        enqueue_transaction_en = 1'b1;
        #0.1ns;
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
    
        // Process the transactions
        for(wait_var = 0; wait_var < num_transactions; wait_var++) begin
            @(posedge clk);
            @(posedge clk);
        end
    
        // Turn off the bus model
        @(negedge clk);
        enable_transactions = 1'b0;
    end
    endtask

    // bus model connections
    apb_model BFM ( .clk(clk),
        // Testing setup signals
        .enqueue_transaction(enqueue_transaction_en),
        .transaction_write(transaction_write),
        .transaction_fake(transaction_fake),
        .transaction_addr(transaction_addr),
        .transaction_data(transaction_data),
        .transaction_error(transaction_error),
        // Testing controls
        .model_reset(model_reset),
        .enable_transactions(enable_transactions),
        .current_transaction_num(current_transaction_num),
        // APB-Subordinate Side
        .psel(psel),
        .paddr(paddr),
        .penable(penable),
        .pwrite(pwrite),
        .pwdata(pwdata),
        .prdata(prdata),
        .psaterr(psaterr)
    );

    initial begin
        n_rst = 1;
        enqueue_transaction_en = 1'b0;
        transaction_fake  = 1'b0;
        transaction_write = 1'b0;
        transaction_addr  = 3'b0;
        transaction_data  = 8'b0;
        transaction_error = 1'b0;
        rx_data = 8'b0;
        data_ready = 1'b0;
        reset_model;
        reset_dut;

//                              1'b          1'b          3'b         8'b         1'b
        // enqueue_transaction(.for_dut(), .write_mode(), .address(), .data(), .expected_error());
        // execute_transactions(.num_transactions());

        rx_data = 8'hAB;
        //Read Data Buffer
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd6), .data(8'd20), .expected_error(1'b0));
        execute_transactions(.num_transactions(1));


        data_ready = 1'b1;
        //Read Data Status Register
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd0), .data(8'd1), .expected_error(1'b0));
        execute_transactions(.num_transactions(1));


        overrun_error = 1'b1;
        framing_error = 1'b1;
        //Read Error Status Register
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd1), .data(8'd1), .expected_error(1'b0));
        //Write Error Status Register
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b1), .address(3'd1), .data(8'd1), .expected_error(1'b1));
        execute_transactions(.num_transactions(2));


        //Read Bit Period Configuration Registers
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd2), .data(8'd200), .expected_error(1'b0));
        execute_transactions(.num_transactions(1));
        //Write Bit Period Configuration Registers
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b1), .address(3'd2), .data(8'd200), .expected_error(1'b0));
        execute_transactions(.num_transactions(1));


        //Read Data Size Configuration Registers
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd4), .data(8'd5), .expected_error(1'b0));
        execute_transactions(.num_transactions(1));
        //Write Data Size Configuration Registers
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b1), .address(3'd4), .data(8'd5), .expected_error(1'b0));
        execute_transactions(.num_transactions(1));


        $finish;
    end
endmodule

/* verilator coverage_on */

