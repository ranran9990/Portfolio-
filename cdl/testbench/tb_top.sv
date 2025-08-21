`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_top ();

   localparam CLK_PERIOD = 10ns;
   localparam TIMEOUT = 1000;
   localparam BURST_SINGLE = 3'd0;
   localparam BURST_INCR   = 3'd1;
   localparam BURST_WRAP4  = 3'd2;
   localparam BURST_INCR4  = 3'd3;
   localparam BURST_WRAP8  = 3'd4;
   localparam BURST_INCR8  = 3'd5;
   localparam BURST_WRAP16 = 3'd6;
   localparam BURST_INCR16 = 3'd7;


   initial begin
       $dumpfile("waveform.fst");
       $dumpvars;
   end

    string label = "";
    logic clk;
    logic n_rst;
    logic hsel;
    logic [3:0] haddr;
    logic [2:0] hsize;
    logic [2:0] hburst;
    logic [1:0] htrans;
    logic hwrite;
    logic [31:0] hwdata;
    logic dp_in;
    logic dm_in;
    logic [31:0] hrdata;
    logic hresp;
    logic hready;
    logic D_Mode;
    logic dp_out;
    logic dm_out;

    //Remove
    // logic [3:0] RX_Packet;
    // logic RX_Data_Ready;
    // logic RX_Transfer_Active;
    // logic RX_Error;
    // logic Flush;
    // logic Store_RX_Packet_Data;
    // logic [7:0] RX_Packet_Data;

    top #() DUT (.*);

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
        @(posedge clk);
        @(posedge clk);
    end
    endtask

   // bus model connections
   ahb_model_updated #(
       .ADDR_WIDTH(4),
       .DATA_WIDTH(4)
   ) BFM ( .clk(clk),
       // AHB-Subordinate Side
       .hsel(hsel),
       .haddr(haddr),
       .hsize(hsize),
       .htrans(htrans),
       .hburst(hburst),
       .hwrite(hwrite),
       .hwdata(hwdata),
       .hrdata(hrdata),
       .hresp(hresp),
       .hready(hready)
   );


   // Supporting Tasks
   task reset_model;
       BFM.reset_model();
   endtask


   // Read from a register without checking the value
   task enqueue_poll ( input logic [3:0] addr, input logic [1:0] size );
   logic [31:0] data [];
       begin
           data = new [1];
           data[0] = {32'hXXXX};
           //              Fields: hsel,  R/W, addr, data, exp err,         size, burst, chk prdata or not
           BFM.enqueue_transaction(1'b1, 1'b0, addr, data,    1'b0, {1'b0, size},  3'b0,            1'b0);
       end
   endtask


   // Read from a register until a requested value is observed
   task poll_until ( input logic [3:0] addr, input logic [1:0] size, input logic [31:0] data);
       int iters;
       begin
           for (iters = 0; iters < TIMEOUT; iters++) begin
               enqueue_poll(addr, size);
               execute_transactions(1);
               if(BFM.get_last_read() == data) break;
           end
           if(iters >= TIMEOUT) begin
               $error("Bus polling timeout hit.");
           end
       end
   endtask


   // Read Transaction, verifying a specific value is read
   task enqueue_read ( input logic [3:0] addr, input logic [1:0] size, input logic [31:0] exp_read );
       logic [31:0] data [];
       begin
           data = new [1];
           data[0] = exp_read;
           BFM.enqueue_transaction(1'b1, 1'b0, addr, data, 1'b0, {1'b0, size}, 3'b0, 1'b1);
       end
   endtask


   // Write Transaction
   task enqueue_write ( input logic [3:0] addr, input logic [1:0] size, input logic [31:0] wdata );
       logic [31:0] data [];
       begin
           data = new [1];
           data[0] = wdata;
           BFM.enqueue_transaction(1'b1, 1'b1, addr, data, 1'b0, {2'b0, size}, 3'b0, 1'b0);
       end
   endtask


   // Error Transaction
   task enqueue_error_write ( input logic [3:0] addr, input logic [1:0] size, input logic [31:0] wdata );
       logic [31:0] data [];
       begin
           data = new [1];
           data[0] = wdata;
           BFM.enqueue_transaction(1'b1, 1'b1, addr, data, 1'b1, {2'b0, size}, 3'b0, 1'b0);
       end
   endtask


   task enqueue_error_read ( input logic [3:0] addr, input logic [1:0] size, input logic [31:0] wdata );
       logic [31:0] data [];
       begin
           data = new [1];
           data[0] = wdata;
           BFM.enqueue_transaction(1'b1, 1'b0, addr, data, 1'b1, {2'b0, size}, 3'b0, 1'b0);
       end
   endtask




   // Write Transaction Intended for a different subordinate from yours
   task enqueue_fakewrite ( input logic [3:0] addr, input logic [1:0] size, input logic [31:0] wdata );
       logic [31:0] data [];
       begin
           data = new [1];
           data[0] = wdata;
           BFM.enqueue_transaction(1'b0, 1'b1, addr, data, 1'b1, {1'b0, size}, 3'b0, 1'b0);
       end
   endtask


   // Create a burst read of size based on the burst type.
   // If INCR, burst size dependent on dynamic array size
   task enqueue_burst_read ( input logic [3:0] base_addr, input logic [1:0] size, input logic [2:0] burst, input logic [31:0] data [] );
       BFM.enqueue_transaction(1'b1, 1'b0, base_addr, data, 1'b0, {1'b0, size}, burst, 1'b1);
   endtask


   // Create a burst write of size based on the burst type.
   task enqueue_burst_write ( input logic [3:0] base_addr, input logic [1:0] size, input logic [2:0] burst, input logic [31:0] data [] );
       BFM.enqueue_transaction(1'b1, 1'b1, base_addr, data, 1'b0, {1'b0, size}, burst, 1'b1);
   endtask


   // Run n transactions, where a k-beat burst counts as k transactions.
   task execute_transactions (input int num_transactions);
       BFM.run_transactions(num_transactions);
   endtask


   // Finish the current transaction
   task finish_transactions();
       BFM.wait_done();
   endtask


   logic [31:0] data [];


   task read_write_basic(input logic [3:0] addr, input logic [1:0] size, input logic [31:0] wdata );
       #(CLK_PERIOD * 4);
       enqueue_write(addr, size, wdata);
       execute_transactions(1);
       finish_transactions();
       #(CLK_PERIOD * 2);
       enqueue_read(addr, size, wdata);
       execute_transactions(1);
       finish_transactions();
       #(CLK_PERIOD * 4);
   endtask


    task send_packet;
       input [7:0] data;
       input time data_period;
       integer i;
       begin
           for(i = 7; i >= 0; i = i - 1)
           begin
               #data_period;           
               dp_in = data[i];
               dm_in = ~data[i];
           end
      
       end
   endtask


    initial begin
       
       n_rst = 1;
       dp_in = 1;
       dm_in = 0;
       reset_model();
       reset_dut();


       /**********RX TESTS START**********/
       label = "(1) Ack Packet";
       send_packet(.data(8'b01010100), .data_period(83.333)); //sync byte
       send_packet(.data(8'b11011000), .data_period(83.333)); //pid byte - ack
       dp_in = 0;
       dm_in = 0;
       #(83.333 * 2);
       dp_in = 1;
       dm_in = 0;
       #(83.333 * 2);

        enqueue_read(4'h4, 2'd1, 32'h8);
        execute_transactions(1);
        finish_transactions();

        label = "(2) IN token";
       send_packet(.data(8'b01010100), .data_period(83.333)); //sync byte
       send_packet(.data(8'b01001110), .data_period(83.333)); //pid byte - in token
       send_packet(.data(8'b10101010), .data_period(83.333)); //token byte 1
       send_packet(.data(8'b00000101), .data_period(83.333)); //token byte 2
       #(83.333);
       dp_in = 0;
       dm_in = 0;
       #(83.333 * 2);
       dp_in = 1;
       dm_in = 0;
       #(83.333 * 2);

        enqueue_read(4'h4, 2'd1, 32'h3);
        execute_transactions(1);
        finish_transactions();


       label = "(3) Out token";
       send_packet(.data(8'b01010100), .data_period(83.333)); //sync byte
       send_packet(.data(8'b01010000), .data_period(83.333)); //pid byte - out token
       send_packet(.data(8'b10101010), .data_period(83.333)); //token byte 1
       send_packet(.data(8'b00000101), .data_period(83.333)); //token byte 2
       #(83.333);
       dp_in = 0;
       dm_in = 0;
       #(83.333 * 2);
       dp_in = 1;
       dm_in = 0;
       #(83.333 * 2);

       enqueue_read(4'h4, 2'd1, 32'h5);
        execute_transactions(1);
        finish_transactions();

        label = "(4) DATA0 token";
       send_packet(.data(8'b01010100), .data_period(83.333)); //sync byte
       send_packet(.data(8'b00101000), .data_period(83.333)); //pid byte - data0 token
       send_packet(.data(8'b11010101), .data_period(83.333)); //data byte 1
       send_packet(.data(8'b11000011), .data_period(83.333)); //data byte 2
       send_packet(.data(8'b01110111), .data_period(83.333)); //data byte 3
       send_packet(.data(8'b10000111), .data_period(83.333)); //data byte 4
       send_packet(.data(8'b00001111), .data_period(83.333)); //data byte 5
       send_packet(.data(8'b00110111), .data_period(83.333)); //data byte 6
       send_packet(.data(8'b00101010), .data_period(83.333)); //data byte 7
       send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8
       send_packet(.data(8'b0000000), .data_period(83.333)); //crc byte 1
       send_packet(.data(8'b0000000), .data_period(83.333)); //crc byte 2
       dp_in = 0;
       dm_in = 0;
       #(83.333 * 2);
       dp_in = 1;
       dm_in = 0;
       #(83.333 * 4);

        enqueue_read(4'h4, 2'd1, 32'h11);
        execute_transactions(1);
        finish_transactions();

        #(CLK_PERIOD * 100);
        enqueue_read(4'h0, 2'd2, 32'hddbbcc02);
        execute_transactions(1);
        finish_transactions();

        enqueue_read(4'h0, 2'd2, 32'h5502caee);
        execute_transactions(1);
        finish_transactions();

        label = "(5) DATA1 token";
       send_packet(.data(8'b01010100), .data_period(83.333)); //sync byte
       send_packet(.data(8'b00110110), .data_period(83.333)); //pid byte - data1 token


       send_packet(.data(8'b11010101), .data_period(83.333)); //data byte 1
       send_packet(.data(8'b11000011), .data_period(83.333)); //data byte 2
       send_packet(.data(8'b01110111), .data_period(83.333)); //data byte 3
       send_packet(.data(8'b10000111), .data_period(83.333)); //data byte 4
       send_packet(.data(8'b00001111), .data_period(83.333)); //data byte 5
       send_packet(.data(8'b00110111), .data_period(83.333)); //data byte 6
       send_packet(.data(8'b00101010), .data_period(83.333)); //data byte 7
       send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8
      
       send_packet(.data(8'b0000000), .data_period(83.333)); //crc byte 1
       send_packet(.data(8'b0000000), .data_period(83.333)); //crc byte 2
       dp_in = 0;
       dm_in = 0;
       #(83.333 * 2);
       dp_in = 1;
       dm_in = 0;
       #(83.333 * 2);

       enqueue_read(4'h4, 2'd1, 32'h33);
        execute_transactions(1);
        finish_transactions();

        enqueue_read(4'h0, 2'd2, 32'hddbbcc02);
        execute_transactions(1);
        finish_transactions();

        enqueue_read(4'h0, 2'd2, 32'h5502caee);
        execute_transactions(1);
        finish_transactions();


       label = "(6) Incorrect packet ID";
       send_packet(.data(8'b01010100), .data_period(83.333)); //sync byte
       send_packet(.data(8'b00111110), .data_period(83.333)); //incorrect packet id
       dp_in = 0;
       dm_in = 0;
       #(83.333 * 2);
       enqueue_read(4'h6, 2'd1, 32'h1);
        execute_transactions(1);
        finish_transactions();
       dp_in = 1;
       dm_in = 0;
       #(83.333 * 4);

        label = "Overflow data packet";
     //  64 bytes sent to data buffer
       send_packet(.data(8'b01010100), .data_period(83.333)); //sync byte  
       send_packet(.data(8'b00101000), .data_period(83.333)); //pid byte - data0 token


       send_packet(.data(8'b11010101), .data_period(83.333)); //data byte 1
       send_packet(.data(8'b11000011), .data_period(83.333)); //data byte 2
       send_packet(.data(8'b01110111), .data_period(83.333)); //data byte 3
       send_packet(.data(8'b10000111), .data_period(83.333)); //data byte 4
       send_packet(.data(8'b00001111), .data_period(83.333)); //data byte 5
       send_packet(.data(8'b00110111), .data_period(83.333)); //data byte 6
       send_packet(.data(8'b00101010), .data_period(83.333)); //data byte 7
       send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8
       send_packet(.data(8'b11010101), .data_period(83.333)); //data byte 1
       send_packet(.data(8'b11000011), .data_period(83.333)); //data byte 2
       send_packet(.data(8'b01110111), .data_period(83.333)); //data byte 3
       send_packet(.data(8'b10000111), .data_period(83.333)); //data byte 4
       send_packet(.data(8'b00001111), .data_period(83.333)); //data byte 5
       send_packet(.data(8'b00110111), .data_period(83.333)); //data byte 6
       send_packet(.data(8'b00101010), .data_period(83.333)); //data byte 7
       send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8
       send_packet(.data(8'b11010101), .data_period(83.333)); //data byte 1
       send_packet(.data(8'b11000011), .data_period(83.333)); //data byte 2
       send_packet(.data(8'b01110111), .data_period(83.333)); //data byte 3
       send_packet(.data(8'b10000111), .data_period(83.333)); //data byte 4
       send_packet(.data(8'b00001111), .data_period(83.333)); //data byte 5
       send_packet(.data(8'b00110111), .data_period(83.333)); //data byte 6
       send_packet(.data(8'b00101010), .data_period(83.333)); //data byte 7
       send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8
       send_packet(.data(8'b11010101), .data_period(83.333)); //data byte 1
       send_packet(.data(8'b11000011), .data_period(83.333)); //data byte 2
       send_packet(.data(8'b01110111), .data_period(83.333)); //data byte 3
       send_packet(.data(8'b10000111), .data_period(83.333)); //data byte 4
       send_packet(.data(8'b00001111), .data_period(83.333)); //data byte 5
       send_packet(.data(8'b00110111), .data_period(83.333)); //data byte 6
       send_packet(.data(8'b00101010), .data_period(83.333)); //data byte 7
       send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8
       send_packet(.data(8'b11010101), .data_period(83.333)); //data byte 1
       send_packet(.data(8'b11000011), .data_period(83.333)); //data byte 2
       send_packet(.data(8'b01110111), .data_period(83.333)); //data byte 3
       send_packet(.data(8'b10000111), .data_period(83.333)); //data byte 4
       send_packet(.data(8'b00001111), .data_period(83.333)); //data byte 5
       send_packet(.data(8'b00110111), .data_period(83.333)); //data byte 6
       send_packet(.data(8'b00101010), .data_period(83.333)); //data byte 7
       send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8
       send_packet(.data(8'b11010101), .data_period(83.333)); //data byte 1
       send_packet(.data(8'b11000011), .data_period(83.333)); //data byte 2
       send_packet(.data(8'b01110111), .data_period(83.333)); //data byte 3
       send_packet(.data(8'b10000111), .data_period(83.333)); //data byte 4
       send_packet(.data(8'b00001111), .data_period(83.333)); //data byte 5
       send_packet(.data(8'b00110111), .data_period(83.333)); //data byte 6
       send_packet(.data(8'b00101010), .data_period(83.333)); //data byte 7
       send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8
       send_packet(.data(8'b11010101), .data_period(83.333)); //data byte 1
       send_packet(.data(8'b11000011), .data_period(83.333)); //data byte 2
       send_packet(.data(8'b01110111), .data_period(83.333)); //data byte 3
       send_packet(.data(8'b10000111), .data_period(83.333)); //data byte 4
       send_packet(.data(8'b00001111), .data_period(83.333)); //data byte 5
       send_packet(.data(8'b00110111), .data_period(83.333)); //data byte 6
       send_packet(.data(8'b00101010), .data_period(83.333)); //data byte 7
       send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8
       send_packet(.data(8'b11010101), .data_period(83.333)); //data byte 1
       send_packet(.data(8'b11000011), .data_period(83.333)); //data byte 2
       send_packet(.data(8'b01110111), .data_period(83.333)); //data byte 3
       send_packet(.data(8'b10000111), .data_period(83.333)); //data byte 4
       send_packet(.data(8'b00001111), .data_period(83.333)); //data byte 5
       send_packet(.data(8'b00110111), .data_period(83.333)); //data byte 6
       send_packet(.data(8'b00101010), .data_period(83.333)); //data byte 7
       send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8
       send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8

       dp_in = 0;
       dm_in = 0;
       #(83.333 * 2);
       dp_in = 1;
       dm_in = 0;
       #(83.333 * 4);

      #(CLK_PERIOD * 10);
    //    /**********RX TESTS END**********/
        //Data0
        label = "(18) TX Data0";
        enqueue_write(4'h0, 2'd2, 32'habcd_efab);
        execute_transactions(1);
        finish_transactions();
        enqueue_write(4'hC, 2'd0, 32'h1);
        execute_transactions(1);
        finish_transactions();
        #(CLK_PERIOD * 700);

         //Data1
         label = "(19) TX Data1";
        enqueue_write(4'h0, 2'd2, 32'habcd_efcd);
        execute_transactions(1);
        finish_transactions();
        enqueue_write(4'hC, 2'd0, 32'h2);
        execute_transactions(1);
        finish_transactions();
        #(CLK_PERIOD * 700);

         //ACK
         label = "(20) TX ACK";
        enqueue_write(4'hC, 2'd0, 32'h3);
        execute_transactions(1);
        finish_transactions();
        #(CLK_PERIOD * 300);

         //NAK
         label = "(21) TX NAK";
        enqueue_write(4'hC, 2'd0, 32'd4);
        execute_transactions(1);
        finish_transactions();
        #(CLK_PERIOD * 300);

        //STALL
        label = "(22) TX STALL";
        enqueue_write(4'hC, 2'd0, 32'h5);
        execute_transactions(1);
        finish_transactions();
        #(CLK_PERIOD * 300);

        //TX Error
        label = "(23) TX ERROR NO DATA";
        enqueue_write(4'hd, 2'd0, 32'h1);
        execute_transactions(1);
        finish_transactions();
        enqueue_write(4'hC, 2'd0, 32'h1);
        execute_transactions(1);
        finish_transactions();
        #(CLK_PERIOD * 700);

         //Invalid TX
        label = "(24) Invalid TX Packet";
        enqueue_write(4'hC, 2'd0, 32'h7);
        execute_transactions(1);
        finish_transactions();
        #(CLK_PERIOD * 300);

        //Clear
        label = "Manually clear data buffer";
        enqueue_write(4'h0, 2'd2, 32'habcd_efab);
        execute_transactions(1);
        finish_transactions();
        enqueue_write(4'h0, 2'd2, 32'habcd_efab);
        execute_transactions(1);
        finish_transactions();
        enqueue_write(4'h0, 2'd2, 32'habcd_efab);
        execute_transactions(1);
        finish_transactions();
        enqueue_write(4'h0, 2'd2, 32'habcd_efab);
        execute_transactions(1);
        finish_transactions();
        enqueue_write(4'h0, 2'd2, 32'habcd_efab);
        execute_transactions(1);
        finish_transactions();
        enqueue_write(4'hd, 2'd0, 32'h1);
        execute_transactions(1);
        finish_transactions();
        #(CLK_PERIOD * 200);

       label = "Consecutive Read/Write and Data Buffer Full Occupancy Test";
       enqueue_write(4'd0, 2'd2, 32'habcdefab); // 4 byte tx_data
       enqueue_write(4'd0, 2'd2, 32'hffffffff); // 4 byte tx_data
       enqueue_write(4'd0, 2'd2, 32'habcdefab); // 4 byte tx_data
       enqueue_write(4'd0, 2'd2, 32'hffffffff); // 4 byte tx_data

       enqueue_write(4'd0, 2'd2, 32'habcdefab); // 4 byte tx_data
       enqueue_write(4'd0, 2'd2, 32'hffffffff); // 4 byte tx_data
       enqueue_write(4'd0, 2'd2, 32'habcdefab); // 4 byte tx_data
       enqueue_write(4'd0, 2'd2, 32'hffffffff); // 4 byte tx_data

       enqueue_write(4'd0, 2'd2, 32'habcdefab); // 4 byte tx_data
       enqueue_write(4'd0, 2'd2, 32'hffffffff); // 4 byte tx_data
       enqueue_write(4'd0, 2'd2, 32'habcdefab); // 4 byte tx_data
       enqueue_write(4'd0, 2'd2, 32'hffffffff); // 4 byte tx_data

       enqueue_write(4'd0, 2'd2, 32'habcdefab); // 4 byte tx_data
       enqueue_write(4'd0, 2'd2, 32'hffffffff); // 4 byte tx_data
       enqueue_write(4'd0, 2'd2, 32'habcdefab); // 4 byte tx_data
       enqueue_write(4'd0, 2'd2, 32'hffffffff); // 4 byte tx_data
       enqueue_write(4'd0, 2'd2, 32'hffffffff); // 4 byte tx_data
       execute_transactions(17); //34
       finish_transactions();

        #(CLK_PERIOD * 4);

        enqueue_write(4'd0, 2'd2, 32'hffffabcd); // 4 byte tx_data
        enqueue_write(4'd0, 2'd2, 32'hffffffff); // 4 byte tx_data
        execute_transactions(2); //34
         finish_transactions();
        
        label = "Consecutive Read from data buffer";
        #(CLK_PERIOD * 10);
       enqueue_read(4'd0, 2'd2, 32'habcdefab); // 4 byte tx_data
       enqueue_read(4'd0, 2'd2, 32'hffffffff); // 4 byte tx_data
       execute_transactions(2); //34
       finish_transactions();
       #(CLK_PERIOD * 100);




       $finish;
   end
  
endmodule



