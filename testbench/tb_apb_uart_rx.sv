`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_apb_uart_rx ();

    // localparam CLK_PERIOD = 10ns;
    localparam CLK_PERIOD = 2ns;

    logic clk, n_rst;
    logic serial_in;
    logic psel;
    logic [2:0] paddr;
    logic penable;
    logic pwrite;
    logic [7:0] pwdata;
    logic [7:0] prdata;
    logic psaterr;


    apb_uart_rx uart(.clk(clk), 
                .n_rst(n_rst),
                .serial_in(serial_in),
                .psel(psel),
                .paddr(paddr),
                .penable(penable),
                .pwrite(pwrite),
                .pwdata(pwdata),
                .prdata(prdata),
                .psaterr(psaterr));

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
        // APB-Satellite Side
        .psel(psel),
        .paddr(paddr),
        .penable(penable),
        .pwrite(pwrite),
        .pwdata(pwdata),
        .prdata(prdata),
        .psaterr(psaterr)
    );

    task configure_design;
        input logic [13:0] bit_per;
        input logic [3:0] data_sz;
        begin
            enqueue_transaction(.for_dut(1'b1), .write_mode(1'b1), .address(3'd2), .data(bit_per[7:0]), .expected_error(1'b0));
            enqueue_transaction(.for_dut(1'b1), .write_mode(1'b1), .address(3'd3), .data({2'b0, bit_per[13:8]}), .expected_error(1'b0));
            enqueue_transaction(.for_dut(1'b1), .write_mode(1'b1), .address(3'd4), .data({4'b0, data_sz}), .expected_error(1'b0));
            execute_transactions(.num_transactions(3));

        end
    endtask


task send_packet;

    input [7:0] data;
    input stop_bit;
    input time data_period;
    input [3:0] data_size;

    integer i;

    begin
        // First synchronize to away from clock ’ s rising edge
        @(negedge clk)

        // Send start bit
        serial_in = 1'b0;
        #data_period;

        // Send data bits
        for ( i = 0; i < data_size; i = i + 1)
        begin
        serial_in = data [i];
        #data_period;
        end

        // Send stop bit
        serial_in = stop_bit;
        #data_period;
    end
endtask

    initial begin
        n_rst = 1;
        enqueue_transaction_en = 1'b0;
        enable_transactions = 1'b0;
        transaction_fake  = 1'b0;
        transaction_write = 1'b0;
        transaction_addr  = 3'b0;
        transaction_data  = 8'b0;
        transaction_error = 1'b0;
        // serial_in = 1'b0;
        reset_model();
        reset_dut();
        
        // serial_in = 1'b1;

        //UART Packet Handling (Same Configurations)
        configure_design(.bit_per(10), .data_sz(8)); 

        // //4% Tolerance
        // send_packet(.data(8'd5), .stop_bit(1'b1), .data_period(19), .data_size(8));
        // //Read Data Buffer
        // enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd6), .data(8'd20), .expected_error(1'b0));
        // //Read Bit Period
        // enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd0), .data(8'd1), .expected_error(1'b0));
        // execute_transactions(.num_transactions(2));
        // #(CLK_PERIOD * 10);

        // send_packet(.data(8'd5), .stop_bit(1'b1), .data_period(20), .data_size(8));
        // //Read Data Buffer
        // enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd6), .data(8'd20), .expected_error(1'b0));
        // //Read Bit Period
        // enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd0), .data(8'd1), .expected_error(1'b0));
        // execute_transactions(.num_transactions(2));
        // #(CLK_PERIOD * 10);

        // send_packet(.data(8'd5), .stop_bit(1'b1), .data_period(21), .data_size(8));
        // //Read Data Buffer
        // enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd6), .data(8'd20), .expected_error(1'b0));
        // //Read Bit Period
        // enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd0), .data(8'd1), .expected_error(1'b0));
        // execute_transactions(.num_transactions(2));
        // #(CLK_PERIOD * 10);



        //2 Normal
        send_packet(.data(8'd10), .stop_bit(1'b1), .data_period(20), .data_size(8));
        //Read Data Status 1
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd0), .data(8'd1), .expected_error(1'b0));
        //Read Data Buffer
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd6), .data(8'd10), .expected_error(1'b0));
        //Read Data Status 0
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd0), .data(8'd0), .expected_error(1'b0));
        execute_transactions(.num_transactions(3));
        #(CLK_PERIOD * 100);

        //3 Fast
        send_packet(.data(8'd50), .stop_bit(1'b1), .data_period(21), .data_size(8));
        //Read Data Status 1
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd0), .data(8'd1), .expected_error(1'b0));
        //Read Data Buffer
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd6), .data(8'd50), .expected_error(1'b0));
        //Read Data Status 0
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd0), .data(8'd0), .expected_error(1'b0));
        execute_transactions(.num_transactions(3));
        #(CLK_PERIOD * 100);

        //5 Slow
        send_packet(.data(8'd227), .stop_bit(1'b1), .data_period(19), .data_size(8));
        //Read Data Status 1
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd0), .data(8'd1), .expected_error(1'b0));
        //Read Data Buffer
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd6), .data(8'd227), .expected_error(1'b0));
        //Read Data Status 0
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd0), .data(8'd0), .expected_error(1'b0));
        execute_transactions(.num_transactions(3));
        #(CLK_PERIOD * 100);

        //4
        //Framing Error
        send_packet(.data(8'd227), .stop_bit(1'b0), .data_period(20), .data_size(8));
        //Read Data Status 1
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd0), .data(8'd1), .expected_error(1'b0));
        //Read Data Buffer
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd6), .data(8'd227), .expected_error(1'b0));
        //Read Data Status 0
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd0), .data(8'd0), .expected_error(1'b0));
        execute_transactions(.num_transactions(3));
        #(CLK_PERIOD * 100);

        //6
        send_packet(.data(8'd51), .stop_bit(1'b1), .data_period(20), .data_size(8));
        //Read Data Status 1
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd0), .data(8'd1), .expected_error(1'b0));
        //Read Data Buffer
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd6), .data(8'd51), .expected_error(1'b0));
        //Read Data Status 0
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd0), .data(8'd0), .expected_error(1'b0));
        execute_transactions(.num_transactions(3));
        #(CLK_PERIOD * 10);

        // 1
        //Overrun Error
        send_packet(.data(8'hf), .stop_bit(1'b1), .data_period(20), .data_size(8));
        #(CLK_PERIOD * 50);
        send_packet(.data(8'hf), .stop_bit(1'b1), .data_period(20), .data_size(8));
        //Read Data Status 1
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd0), .data(8'd1), .expected_error(1'b0));
        //Read Data Buffer
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd6), .data(8'd10), .expected_error(1'b0));
        //Read Data Status 0
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd0), .data(8'd0), .expected_error(1'b0));
        execute_transactions(.num_transactions(3));
        #(CLK_PERIOD * 100);





        //UART Packet Handling (Different Configurations)
        configure_design(.bit_per(500), .data_sz(8)); 
        send_packet(.data(8'd10), .stop_bit(1'b1), .data_period(1000), .data_size(8));
        //Read Data Status 1
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd0), .data(8'd1), .expected_error(1'b0));
        //Read Data Buffer
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd6), .data(8'd51), .expected_error(1'b0));
        //Read Data Status 0
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd0), .data(8'd0), .expected_error(1'b0));
        execute_transactions(.num_transactions(3));
        #(CLK_PERIOD * 10);

        configure_design(.bit_per(1000), .data_sz(5)); 
        send_packet(.data(8'd50), .stop_bit(1'b1), .data_period(2000), .data_size(5));
        //Read Data Status 1
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd0), .data(8'd1), .expected_error(1'b0));
        //Read Data Buffer
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd6), .data(8'd51), .expected_error(1'b0));
        //Read Data Status 0
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd0), .data(8'd0), .expected_error(1'b0));
        execute_transactions(.num_transactions(3));
        #(CLK_PERIOD * 10);

        configure_design(.bit_per(5000), .data_sz(7)); 
        send_packet(.data(8'd227), .stop_bit(1'b0), .data_period(10000), .data_size(7));
        //Read Data Status 1
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd0), .data(8'd1), .expected_error(1'b0));
        //Read Data Buffer
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd6), .data(8'd51), .expected_error(1'b0));
        //Read Data Status 0
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd0), .data(8'd0), .expected_error(1'b0));
        execute_transactions(.num_transactions(3));
        #(CLK_PERIOD * 10);

        configure_design(.bit_per(10000), .data_sz(8)); 
        send_packet(.data(8'd50), .stop_bit(1'b1), .data_period(20000), .data_size(8));
        //Read Data Status 1
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd0), .data(8'd1), .expected_error(1'b0));
        //Read Data Buffer
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd6), .data(8'd51), .expected_error(1'b0));
        //Read Data Status 0
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd0), .data(8'd0), .expected_error(1'b0));
        execute_transactions(.num_transactions(3));
        #(CLK_PERIOD * 10);

        configure_design(.bit_per(16000), .data_sz(5)); 
        send_packet(.data(8'd51), .stop_bit(1'b1), .data_period(32000), .data_size(5));
        //Read Data Status 1
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd0), .data(8'd1), .expected_error(1'b0));
        //Read Data Buffer
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd6), .data(8'd51), .expected_error(1'b0));
        //Read Data Status 0
        enqueue_transaction(.for_dut(1'b1), .write_mode(1'b0), .address(3'd0), .data(8'd0), .expected_error(1'b0));
        execute_transactions(.num_transactions(3));
        #(CLK_PERIOD * 10);

        $finish;
    end
endmodule

/* verilator coverage_on */

