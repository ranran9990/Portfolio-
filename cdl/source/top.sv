`timescale 1ns / 10ps


module top #(
   // parameters
) (
   input logic clk,
   input logic n_rst,
   input logic hsel,
   input logic [3:0] haddr,
   input logic [1:0] hsize,
   input logic [1:0] htrans,
   input logic hwrite,
   input logic [31:0] hwdata,
   input logic dp_in,
   input logic dm_in,
   output logic [31:0] hrdata,
   output logic hresp,
   output logic hready,
   output logic D_Mode,
   output logic dp_out,
   output logic dm_out

   //  input logic [3:0] RX_Packet,
   //  input logic RX_Data_Ready,
   //  input logic RX_Transfer_Active,
   //  input logic RX_Error,
   //  input logic Flush,
   //  input logic Store_RX_Packet_Data,
   //  input logic [7:0] RX_Packet_Data
   
);

   logic Store_RX_Packet_Data;
   logic Get_TX_Packet_Data;
   logic [7:0] RX_Packet_Data;
   logic [7:0] TX_Packet_Data;
   logic Flush;

   //RX
   logic [3:0] RX_Packet;
   logic RX_Data_Ready;
   logic RX_Transfer_Active;
   logic RX_Error;

   //TX_Data
   logic TX_Transfer_Active;
   logic TX_Error;
   logic [2:0] TX_Packet;

   //Data Buffer
   logic [6:0] Buffer_Occupancy;
   logic [7:0] RX_Data;
   logic Clear;
   logic [7:0] TX_Data;
   logic Get_RX_Data;
   logic Store_TX_Data;

   usb_rx rx (.clk(clk),
              .n_rst(n_rst),
              .dp_in(dp_in),
              .dm_in(dm_in),
              .RX_Packet(RX_Packet),
              .RX_Data_Ready(RX_Data_Ready),
              .RX_Transfer_Active(RX_Transfer_Active),
              .RX_Packet_Data(RX_Packet_Data),
              .Buffer_Occupancy(Buffer_Occupancy),
              .Store_RX_Packet_Data(Store_RX_Packet_Data),
              .Flush(Flush),
              .RX_Error(RX_Error));

   data_buffer data_buffer (.clk(clk),
                        .n_rst(n_rst),
                        .Get_RX_Data(Get_RX_Data),
                        .Store_RX_Packet_Data(Store_RX_Packet_Data),
                        .Get_TX_Packet_Data(Get_TX_Packet_Data),
                        .Store_TX_Data(Store_TX_Data),
                        .Flush(Flush),
                        .Clear(Clear),
                        .TX_Data(TX_Data),
                        .RX_Packet_Data(RX_Packet_Data),
                        .Buffer_Occupancy(Buffer_Occupancy),
                        .RX_Data(RX_Data),
                        .TX_Packet_Data(TX_Packet_Data));

   usb_tx tx (.clk(clk),
                   .n_rst(n_rst),
                   .Buffer_Occupancy(Buffer_Occupancy),
                   .TX_Packet_Data(TX_Packet_Data),
                   .TX_Packet(TX_Packet),
                   .Get_TX_Packet_Data(Get_TX_Packet_Data),
                   .TX_Transfer_Active(TX_Transfer_Active),
                   .TX_Error(TX_Error),
                   .dp_out(dp_out),
                   .dm_out(dm_out));  

   usb_ahb ahb1(
           .clk(clk),
           .n_rst(n_rst),
           .hsel(hsel),
           .haddr(haddr),
           .htrans(htrans),
           .hsize(hsize[1:0]),
           .hwrite(hwrite),
           .hwdata(hwdata),
           .hrdata(hrdata),
           .hready(hready),
           .hresp(hresp),
           .D_Mode(D_Mode),
           .RX_Packet(RX_Packet),
           .RX_Data_Ready(RX_Data_Ready),
           .RX_Transfer_Active(RX_Transfer_Active),
           .RX_Error(RX_Error),
           .TX_Transfer_Active(TX_Transfer_Active),
           .TX_Error(TX_Error),
           .TX_Packet(TX_Packet),
           .Buffer_Occupancy(Buffer_Occupancy),
           .RX_Data(RX_Data),
           .Clear(Clear),
           .TX_Data(TX_Data),
           .Get_RX_Data(Get_RX_Data),
           .Store_TX_Data(Store_TX_Data));
endmodule
