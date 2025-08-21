`timescale 1ns / 10ps
/* verilator coverage_off */


module tb_usb_rx ();


   localparam CLK_PERIOD = 10ns;


   initial begin
       $dumpfile("waveform.vcd");
       $dumpvars;
   end




   logic clk, n_rst, dp_in, dm_in;
   logic [6:0] Buffer_Occupancy;
   logic RX_Data_Ready, RX_Transfer_Active, RX_Error, Flush, Store_RX_Packet_Data, RX_Packet, RX_Packet_Data;
   logic [3:0] rx_packet;
   logic [7:0] rx_packet_data;


   string test_case = "";


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


   usb_rx #() DUT (.*);


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
       Buffer_Occupancy = 0;
       reset_dut();
       @(negedge clk);
       @(negedge clk);
       @(negedge clk);


       Buffer_Occupancy = 16;
       // @(negedge clk);
       // @(negedge clk);


    //    test_case = "ACK Packet ID";
    //    send_packet(.data(8'b01010100), .data_period(83.333)); //sync byte
    //    send_packet(.data(8'b11011000), .data_period(83.333)); //pid byte - ack
    //    dp_in = 0;
    //    dm_in = 0;
    //    #(83.333 * 2);
    //    dp_in = 1;
    //    dm_in = 0;
    //    #(83.333 * 2);


    //    test_case = "OUT Token ID";
    //    send_packet(.data(8'b01010100), .data_period(83.333)); //sync byte
    //    send_packet(.data(8'b01010000), .data_period(83.333)); //pid byte - out token
    //    send_packet(.data(8'b10101010), .data_period(83.333)); //token byte 1
    //    send_packet(.data(8'b00000101), .data_period(83.333)); //token byte 2
    //    #(83.333);
    //    dp_in = 0;
    //    dm_in = 0;
    //    #(83.333 * 2);
    //    dp_in = 1;
    //    dm_in = 0;
    //    #(83.333 * 2);


    //    test_case = "IN Token ID";
    //    send_packet(.data(8'b01010100), .data_period(83.333)); //sync byte
    //    send_packet(.data(8'b01001110), .data_period(83.333)); //pid byte - in token
    //    send_packet(.data(8'b10101010), .data_period(83.333)); //token byte 1
    //    send_packet(.data(8'b00000101), .data_period(83.333)); //token byte 2
    //    #(83.333);
    //    dp_in = 0;
    //    dm_in = 0;
    //    #(83.333 * 2);
    //    dp_in = 1;
    //    dm_in = 0;
    //    #(83.333 * 2);


       test_case = "DATA0 Packet ID";
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


       test_case = "DATA1 Packet ID";
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
       #(83.333 * 4);


    //    test_case = "IN Token ID w/ Incorrect Address/Endpoint";
    //    send_packet(.data(8'b01010100), .data_period(83.333)); //sync byte
    //    send_packet(.data(8'b01001110), .data_period(83.333)); //pid byte - in token, but incorrect addresses/endpoints
    //    send_packet(.data(8'b10111010), .data_period(83.333)); //incorrect token byte 1
    //    send_packet(.data(8'b00111100), .data_period(83.333)); //token byte 2
    //    #(83.333);
    //    dp_in = 0;
    //    dm_in = 0;
    //    #(83.333 * 2);
    //    dp_in = 1;
    //    dm_in = 0;
    //    #(83.333 * 2);


    //    test_case = "IN Token ID w/ Incorrect CRC";
    //    send_packet(.data(8'b01010100), .data_period(83.333)); //sync byte
    //    send_packet(.data(8'b01001110), .data_period(83.333)); //pid byte - in token, but incorrect addresses/endpoints
    //    send_packet(.data(8'b10101010), .data_period(83.333)); //token byte 1
    //    send_packet(.data(8'b00100101), .data_period(83.333)); //incorrect token byte 2, incorrect crc
    //    #(83.333);
    //    dp_in = 0;
    //    dm_in = 0;
    //    #(83.333 * 2);
    //    dp_in = 1;
    //    dm_in = 0;
    //    #(83.333 * 2);




    //    test_case = "DATA1 Packet ID w/ Invalid CRC Fields";
    //    send_packet(.data(8'b01010100), .data_period(83.333)); //sync byte
    //    send_packet(.data(8'b00110110), .data_period(83.333)); //pid byte - data1 token, but invalid crc fields


    //    send_packet(.data(8'b11010101), .data_period(83.333)); //data byte 1
    //    send_packet(.data(8'b11000011), .data_period(83.333)); //data byte 2
    //    send_packet(.data(8'b01110111), .data_period(83.333)); //data byte 3
    //    send_packet(.data(8'b10000111), .data_period(83.333)); //data byte 4
    //    send_packet(.data(8'b00001111), .data_period(83.333)); //data byte 5
    //    send_packet(.data(8'b00110111), .data_period(83.333)); //data byte 6
    //    send_packet(.data(8'b00101010), .data_period(83.333)); //data byte 7
    //    send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8
      
    //    send_packet(.data(8'b0001100), .data_period(83.333)); //crc byte 1 - invalid
    //    send_packet(.data(8'b0011100), .data_period(83.333)); //crc byte 2 - invalid


    //    dp_in = 0;
    //    dm_in = 0;
    //    #(83.333 * 2);
    //    dp_in = 1;
    //    dm_in = 0;
    //    #(83.333 * 4);


    //    test_case = "Incorrect Packet ID";
    //    send_packet(.data(8'b01010100), .data_period(83.333)); //sync byte
    //    send_packet(.data(8'b00111110), .data_period(83.333)); //incorrect packet id
      
    //    dp_in = 0;
    //    dm_in = 0;
    //    #(83.333 * 2);
    //    dp_in = 1;
    //    dm_in = 0;
    //    #(83.333 * 4);    




    //    test_case = "Incorrect Sync Byte";
    //    send_packet(.data(8'b01011100), .data_period(83.333)); //incorrect sync byte


    //    dp_in = 0;
    //    dm_in = 0;
    //    #(83.333 * 2);
    //    dp_in = 1;
    //    dm_in = 0;
    //    #(83.333 * 4);


    //    test_case = "Incorrect EOP Signal";
    //    send_packet(.data(8'b01010100), .data_period(83.333)); //sync byte
    //    send_packet(.data(8'b11011000), .data_period(83.333)); //pid byte - ack
    //    dp_in = 0;
    //    dm_in = 0;
    //    #(83.333 * 3);
    //    dp_in = 0;
    //    dm_in = 0;
    //    #(83.333 * 2);
    //    dp_in = 1;
    //    dm_in = 0;
    //    #(83.333 * 2);


       // Testbenches used to verify data payload buffering functionality must have test cases that verify correct be-
// havior during small, large, and max-sized data payload filling from the USB RX module


//buffer_occupancy = 32;
       // send_packet(.data(8'b01010100), .data_period(83.333)); //sync byte
       // send_packet(.data(8'b00101000), .data_period(83.333)); //pid byte - data0 token


       // send_packet(.data(8'b11010101), .data_period(83.333)); //data byte 1
       // send_packet(.data(8'b11000011), .data_period(83.333)); //data byte 2
       // send_packet(.data(8'b01110111), .data_period(83.333)); //data byte 3
       // send_packet(.data(8'b10000111), .data_period(83.333)); //data byte 4
       // send_packet(.data(8'b00001111), .data_period(83.333)); //data byte 5
       // send_packet(.data(8'b00110111), .data_period(83.333)); //data byte 6
       // send_packet(.data(8'b00101010), .data_period(83.333)); //data byte 7
       // send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8
       // send_packet(.data(8'b11010101), .data_period(83.333)); //data byte 1
       // send_packet(.data(8'b11000011), .data_period(83.333)); //data byte 2
       // send_packet(.data(8'b01110111), .data_period(83.333)); //data byte 3
       // send_packet(.data(8'b10000111), .data_period(83.333)); //data byte 4
       // send_packet(.data(8'b00001111), .data_period(83.333)); //data byte 5
       // send_packet(.data(8'b00110111), .data_period(83.333)); //data byte 6
       // send_packet(.data(8'b00101010), .data_period(83.333)); //data byte 7
       // send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8
       // send_packet(.data(8'b11010101), .data_period(83.333)); //data byte 1
       // send_packet(.data(8'b11000011), .data_period(83.333)); //data byte 2
       // send_packet(.data(8'b01110111), .data_period(83.333)); //data byte 3
       // send_packet(.data(8'b10000111), .data_period(83.333)); //data byte 4
       // send_packet(.data(8'b00001111), .data_period(83.333)); //data byte 5
       // send_packet(.data(8'b00110111), .data_period(83.333)); //data byte 6
       // send_packet(.data(8'b00101010), .data_period(83.333)); //data byte 7
       // send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8
       // send_packet(.data(8'b11010101), .data_period(83.333)); //data byte 1
       // send_packet(.data(8'b11000011), .data_period(83.333)); //data byte 2
       // send_packet(.data(8'b01110111), .data_period(83.333)); //data byte 3
       // send_packet(.data(8'b10000111), .data_period(83.333)); //data byte 4
       // send_packet(.data(8'b00001111), .data_period(83.333)); //data byte 5
       // send_packet(.data(8'b00110111), .data_period(83.333)); //data byte 6
       // send_packet(.data(8'b00101010), .data_period(83.333)); //data byte 7
       // send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8
       // send_packet(.data(8'b11010101), .data_period(83.333)); //data byte 1
       // send_packet(.data(8'b11000011), .data_period(83.333)); //data byte 2
       // send_packet(.data(8'b01110111), .data_period(83.333)); //data byte 3
       // send_packet(.data(8'b10000111), .data_period(83.333)); //data byte 4
       // send_packet(.data(8'b00001111), .data_period(83.333)); //data byte 5
       // send_packet(.data(8'b00110111), .data_period(83.333)); //data byte 6
       // send_packet(.data(8'b00101010), .data_period(83.333)); //data byte 7
       // send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8
       // send_packet(.data(8'b11010101), .data_period(83.333)); //data byte 1
       // send_packet(.data(8'b11000011), .data_period(83.333)); //data byte 2
       // send_packet(.data(8'b01110111), .data_period(83.333)); //data byte 3
       // send_packet(.data(8'b10000111), .data_period(83.333)); //data byte 4
       // send_packet(.data(8'b00001111), .data_period(83.333)); //data byte 5
       // send_packet(.data(8'b00110111), .data_period(83.333)); //data byte 6
       // send_packet(.data(8'b00101010), .data_period(83.333)); //data byte 7
       // send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8
       // send_packet(.data(8'b11010101), .data_period(83.333)); //data byte 1
       // send_packet(.data(8'b11000011), .data_period(83.333)); //data byte 2
       // send_packet(.data(8'b01110111), .data_period(83.333)); //data byte 3
       // send_packet(.data(8'b10000111), .data_period(83.333)); //data byte 4
       // send_packet(.data(8'b00001111), .data_period(83.333)); //data byte 5
       // send_packet(.data(8'b00110111), .data_period(83.333)); //data byte 6
       // send_packet(.data(8'b00101010), .data_period(83.333)); //data byte 7
       // send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8
       // send_packet(.data(8'b11010101), .data_period(83.333)); //data byte 1
       // send_packet(.data(8'b11000011), .data_period(83.333)); //data byte 2
       // send_packet(.data(8'b01110111), .data_period(83.333)); //data byte 3
       // send_packet(.data(8'b10000111), .data_period(83.333)); //data byte 4
       // send_packet(.data(8'b00001111), .data_period(83.333)); //data byte 5
       // send_packet(.data(8'b00110111), .data_period(83.333)); //data byte 6
       // send_packet(.data(8'b00101010), .data_period(83.333)); //data byte 7
       // send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8
       // send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8


       // send_packet(.data(8'b0000000), .data_period(83.333)); //crc byte 1
       // send_packet(.data(8'b0000000), .data_period(83.333)); //crc byte 2
       // dp_in = 0;
       // dm_in = 0;
       // #(83.333 * 2);
       // dp_in = 1;
       // dm_in = 0;
       // #(83.333 * 2);


//buffer_occupancy = 64;
       // send_packet(.data(8'b01010100), .data_period(83.333)); //sync byte
       // send_packet(.data(8'b00101000), .data_period(83.333)); //pid byte - data0 token


       // send_packet(.data(8'b11010101), .data_period(83.333)); //data byte 1
       // send_packet(.data(8'b11000011), .data_period(83.333)); //data byte 2
       // send_packet(.data(8'b01110111), .data_period(83.333)); //data byte 3
       // send_packet(.data(8'b10000111), .data_period(83.333)); //data byte 4
       // send_packet(.data(8'b00001111), .data_period(83.333)); //data byte 5
       // send_packet(.data(8'b00110111), .data_period(83.333)); //data byte 6
       // send_packet(.data(8'b00101010), .data_period(83.333)); //data byte 7
       // send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8
       // send_packet(.data(8'b11010101), .data_period(83.333)); //data byte 1
       // send_packet(.data(8'b11000011), .data_period(83.333)); //data byte 2
       // send_packet(.data(8'b01110111), .data_period(83.333)); //data byte 3
       // send_packet(.data(8'b10000111), .data_period(83.333)); //data byte 4
       // send_packet(.data(8'b00001111), .data_period(83.333)); //data byte 5
       // send_packet(.data(8'b00110111), .data_period(83.333)); //data byte 6
       // send_packet(.data(8'b00101010), .data_period(83.333)); //data byte 7
       // send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8
       // send_packet(.data(8'b11010101), .data_period(83.333)); //data byte 1
       // send_packet(.data(8'b11000011), .data_period(83.333)); //data byte 2
       // send_packet(.data(8'b01110111), .data_period(83.333)); //data byte 3
       // send_packet(.data(8'b10000111), .data_period(83.333)); //data byte 4
       // send_packet(.data(8'b00001111), .data_period(83.333)); //data byte 5
       // send_packet(.data(8'b00110111), .data_period(83.333)); //data byte 6
       // send_packet(.data(8'b00101010), .data_period(83.333)); //data byte 7
       // send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8
       // send_packet(.data(8'b11010101), .data_period(83.333)); //data byte 1
       // send_packet(.data(8'b11000011), .data_period(83.333)); //data byte 2
       // send_packet(.data(8'b01110111), .data_period(83.333)); //data byte 3
       // send_packet(.data(8'b10000111), .data_period(83.333)); //data byte 4
       // send_packet(.data(8'b00001111), .data_period(83.333)); //data byte 5
       // send_packet(.data(8'b00110111), .data_period(83.333)); //data byte 6
       // send_packet(.data(8'b00101010), .data_period(83.333)); //data byte 7
       // send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8
       // send_packet(.data(8'b11010101), .data_period(83.333)); //data byte 1
       // send_packet(.data(8'b11000011), .data_period(83.333)); //data byte 2
       // send_packet(.data(8'b01110111), .data_period(83.333)); //data byte 3
       // send_packet(.data(8'b10000111), .data_period(83.333)); //data byte 4
       // send_packet(.data(8'b00001111), .data_period(83.333)); //data byte 5
       // send_packet(.data(8'b00110111), .data_period(83.333)); //data byte 6
       // send_packet(.data(8'b00101010), .data_period(83.333)); //data byte 7
       // send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8
       // send_packet(.data(8'b11010101), .data_period(83.333)); //data byte 1
       // send_packet(.data(8'b11000011), .data_period(83.333)); //data byte 2
       // send_packet(.data(8'b01110111), .data_period(83.333)); //data byte 3
       // send_packet(.data(8'b10000111), .data_period(83.333)); //data byte 4
       // send_packet(.data(8'b00001111), .data_period(83.333)); //data byte 5
       // send_packet(.data(8'b00110111), .data_period(83.333)); //data byte 6
       // send_packet(.data(8'b00101010), .data_period(83.333)); //data byte 7
       // send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8
       // send_packet(.data(8'b11010101), .data_period(83.333)); //data byte 1
       // send_packet(.data(8'b11000011), .data_period(83.333)); //data byte 2
       // send_packet(.data(8'b01110111), .data_period(83.333)); //data byte 3
       // send_packet(.data(8'b10000111), .data_period(83.333)); //data byte 4
       // send_packet(.data(8'b00001111), .data_period(83.333)); //data byte 5
       // send_packet(.data(8'b00110111), .data_period(83.333)); //data byte 6
       // send_packet(.data(8'b00101010), .data_period(83.333)); //data byte 7
       // send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8
       // send_packet(.data(8'b11010101), .data_period(83.333)); //data byte 1
       // send_packet(.data(8'b11000011), .data_period(83.333)); //data byte 2
       // send_packet(.data(8'b01110111), .data_period(83.333)); //data byte 3
       // send_packet(.data(8'b10000111), .data_period(83.333)); //data byte 4
       // send_packet(.data(8'b00001111), .data_period(83.333)); //data byte 5
       // send_packet(.data(8'b00110111), .data_period(83.333)); //data byte 6
       // send_packet(.data(8'b00101010), .data_period(83.333)); //data byte 7
       // send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8


  
       // send_packet(.data(8'b0000000), .data_period(83.333)); //crc byte 1
       // send_packet(.data(8'b0000000), .data_period(83.333)); //crc byte 2
       // dp_in = 0;
       // dm_in = 0;
       // #(83.333 * 2);
       // dp_in = 1;
       // dm_in = 0;
       // #(83.333 * 2);


//buffer_occupancy = 66;
// send_packet(.data(8'b01010100), .data_period(83.333)); //sync byte
       // send_packet(.data(8'b00101000), .data_period(83.333)); //pid byte - data0 token


       // send_packet(.data(8'b11010101), .data_period(83.333)); //data byte 1
       // send_packet(.data(8'b11000011), .data_period(83.333)); //data byte 2
       // send_packet(.data(8'b01110111), .data_period(83.333)); //data byte 3
       // send_packet(.data(8'b10000111), .data_period(83.333)); //data byte 4
       // send_packet(.data(8'b00001111), .data_period(83.333)); //data byte 5
       // send_packet(.data(8'b00110111), .data_period(83.333)); //data byte 6
       // send_packet(.data(8'b00101010), .data_period(83.333)); //data byte 7
       // send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8
       // send_packet(.data(8'b11010101), .data_period(83.333)); //data byte 1
       // send_packet(.data(8'b11000011), .data_period(83.333)); //data byte 2
       // send_packet(.data(8'b01110111), .data_period(83.333)); //data byte 3
       // send_packet(.data(8'b10000111), .data_period(83.333)); //data byte 4
       // send_packet(.data(8'b00001111), .data_period(83.333)); //data byte 5
       // send_packet(.data(8'b00110111), .data_period(83.333)); //data byte 6
       // send_packet(.data(8'b00101010), .data_period(83.333)); //data byte 7
       // send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8
       // send_packet(.data(8'b11010101), .data_period(83.333)); //data byte 1
       // send_packet(.data(8'b11000011), .data_period(83.333)); //data byte 2
       // send_packet(.data(8'b01110111), .data_period(83.333)); //data byte 3
       // send_packet(.data(8'b10000111), .data_period(83.333)); //data byte 4
       // send_packet(.data(8'b00001111), .data_period(83.333)); //data byte 5
       // send_packet(.data(8'b00110111), .data_period(83.333)); //data byte 6
       // send_packet(.data(8'b00101010), .data_period(83.333)); //data byte 7
       // send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8
       // send_packet(.data(8'b11010101), .data_period(83.333)); //data byte 1
       // send_packet(.data(8'b11000011), .data_period(83.333)); //data byte 2
       // send_packet(.data(8'b01110111), .data_period(83.333)); //data byte 3
       // send_packet(.data(8'b10000111), .data_period(83.333)); //data byte 4
       // send_packet(.data(8'b00001111), .data_period(83.333)); //data byte 5
       // send_packet(.data(8'b00110111), .data_period(83.333)); //data byte 6
       // send_packet(.data(8'b00101010), .data_period(83.333)); //data byte 7
       // send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8
       // send_packet(.data(8'b11010101), .data_period(83.333)); //data byte 1
       // send_packet(.data(8'b11000011), .data_period(83.333)); //data byte 2
       // send_packet(.data(8'b01110111), .data_period(83.333)); //data byte 3
       // send_packet(.data(8'b10000111), .data_period(83.333)); //data byte 4
       // send_packet(.data(8'b00001111), .data_period(83.333)); //data byte 5
       // send_packet(.data(8'b00110111), .data_period(83.333)); //data byte 6
       // send_packet(.data(8'b00101010), .data_period(83.333)); //data byte 7
       // send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8
       // send_packet(.data(8'b11010101), .data_period(83.333)); //data byte 1
       // send_packet(.data(8'b11000011), .data_period(83.333)); //data byte 2
       // send_packet(.data(8'b01110111), .data_period(83.333)); //data byte 3
       // send_packet(.data(8'b10000111), .data_period(83.333)); //data byte 4
       // send_packet(.data(8'b00001111), .data_period(83.333)); //data byte 5
       // send_packet(.data(8'b00110111), .data_period(83.333)); //data byte 6
       // send_packet(.data(8'b00101010), .data_period(83.333)); //data byte 7
       // send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8
       // send_packet(.data(8'b11010101), .data_period(83.333)); //data byte 1
       // send_packet(.data(8'b11000011), .data_period(83.333)); //data byte 2
       // send_packet(.data(8'b01110111), .data_period(83.333)); //data byte 3
       // send_packet(.data(8'b10000111), .data_period(83.333)); //data byte 4
       // send_packet(.data(8'b00001111), .data_period(83.333)); //data byte 5
       // send_packet(.data(8'b00110111), .data_period(83.333)); //data byte 6
       // send_packet(.data(8'b00101010), .data_period(83.333)); //data byte 7
       // send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8
       // send_packet(.data(8'b11010101), .data_period(83.333)); //data byte 1
       // send_packet(.data(8'b11000011), .data_period(83.333)); //data byte 2
       // send_packet(.data(8'b01110111), .data_period(83.333)); //data byte 3
       // send_packet(.data(8'b10000111), .data_period(83.333)); //data byte 4
       // send_packet(.data(8'b00001111), .data_period(83.333)); //data byte 5
       // send_packet(.data(8'b00110111), .data_period(83.333)); //data byte 6
       // send_packet(.data(8'b00101010), .data_period(83.333)); //data byte 7
       // send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8
       // send_packet(.data(8'b00101010), .data_period(83.333)); //data byte 7
       // send_packet(.data(8'b01100110), .data_period(83.333)); //data byte 8


       // send_packet(.data(8'b0000000), .data_period(83.333)); //crc byte 1
       // send_packet(.data(8'b0000000), .data_period(83.333)); //crc byte 2
       // dp_in = 0;
       // dm_in = 0;
       // #(83.333 * 2);
       // dp_in = 1;
       // dm_in = 0;
       // #(83.333 * 2);


//buffer_occupancy = 16;
    //    test_case = "Premature EOP Signal";
    //    send_packet(.data(8'b01010100), .data_period(83.333)); //sync byte
    //    send_packet(.data(8'b00110110), .data_period(83.333)); //pid byte - data1 token


    //    send_packet(.data(8'b11010101), .data_period(83.333)); //data byte 1
    //    send_packet(.data(8'b11000011), .data_period(83.333)); //data byte 2
    //    send_packet(.data(8'b01110111), .data_period(83.333)); //data byte 3
    //    send_packet(.data(8'b10000111), .data_period(83.333)); //data byte 4


    //    dp_in = 1;
    //    dm_in = 0;
    //    #(83.333);
    //    dp_in = 1;
    //    dm_in = 0;
    //    #(83.333);




    //    dp_in = 0; //start of premature eop
    //    dm_in = 0;
    //    #(83.333 * 2);
    //    dp_in = 1;
    //    dm_in = 0;
    //    #(83.333 * 2);


    //    dp_in = 0; //new eop to get rid of premature eop
    //    dm_in = 0;
    //    #(83.333 * 2);
    //    dp_in = 1;
    //    dm_in = 0;
    //    #(83.333 * 2);     




       $finish;
   end


endmodule  




      


/* verilator coverage_on */




