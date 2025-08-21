`timescale 1ns / 10ps

// typedef enum logic [1:0] {
//     TX_IDLE, TX_RUNNING
// } TX_select;

module data_buffer (
  input logic clk,
  input logic n_rst,
  input logic Get_RX_Data,
  input logic Store_RX_Packet_Data,
  input logic Get_TX_Packet_Data,
  input logic Store_TX_Data,
  input logic Flush,  
  input logic Clear,
  input logic [7:0] TX_Data,
  input logic [7:0] RX_Packet_Data,
  output logic [6:0] Buffer_Occupancy,
  output logic [7:0] RX_Data,
  output logic [7:0] TX_Packet_Data
);

logic [6:0] write_count, next_write_count, read_count, next_read_count;
logic [511:0] storage, storage_out;
logic [7:0] next_data;
logic [7:0] TX_Packet_Data_In, TX_Data_Reg;


always_ff @(posedge clk, negedge n_rst) begin
  if (~n_rst) begin
    write_count <= '0;
    read_count <= '0;
    storage_out <= '0;
  end
  else begin
    write_count <= next_write_count;
    read_count <= next_read_count;
    storage_out <= storage;
  end
end

// TX Select Logic
always_ff @(posedge clk, negedge n_rst) begin
  if (~n_rst) begin
    TX_Data_Reg <= '0;
  end
  else if (Get_TX_Packet_Data) begin
    TX_Data_Reg <= TX_Packet_Data_In;
  end
end

always_comb begin 
    TX_Packet_Data = TX_Data_Reg;
end

//logic to decide if RX or TX data pushes into storage
always_comb begin
    next_data = '0;
    
    if (Store_RX_Packet_Data) begin
        next_data = RX_Packet_Data;
    end

    if (Store_TX_Data) begin
        next_data = TX_Data;
    end
end

//logic for pushing data into storage
always_comb begin
    storage = storage_out;

    if (Flush | Clear) begin
        storage = '0; 
    end 

    else if (Store_TX_Data | Store_RX_Packet_Data) begin
        storage[write_count * 8 +: 8] = next_data;
    end
end

//logic for popping data out of storage
always_comb begin
    RX_Data = '0;
    TX_Packet_Data_In = '0;

    if (Get_RX_Data) begin
        RX_Data = storage_out[(read_count) * 8 +: 8];
    end

    TX_Packet_Data_In = storage_out[(read_count) * 8 +: 8];


end

//counter logic
always_comb begin
    next_write_count = write_count;
    
    if (Flush | Clear) begin
        next_write_count = '0;
    end

    else if (write_count == 7'd65) begin
        next_write_count = 7'd65;
    end

    else if (Store_RX_Packet_Data | Store_TX_Data) begin
        next_write_count = write_count + 1'b1;
    end
end

//counter logic
always_comb begin
    next_read_count = read_count;   
    
    if (Flush | Clear) begin
        next_read_count = '0;
    end

    else if ((read_count == 7'd65)) begin
        next_read_count = 7'd65;
    end

    else if (Get_RX_Data | Get_TX_Packet_Data) begin
        next_read_count = read_count + 1'b1;
    end
end


//buffer occupancy logic
always_comb begin
    if (Flush | Clear) begin
        Buffer_Occupancy = '0;
    end

    Buffer_Occupancy = write_count - read_count;
end


endmodule


