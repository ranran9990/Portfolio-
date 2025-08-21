`timescale 1ns / 10ps
typedef enum logic [1:0] { EOP_IDLE, FIRST_EOP_BIT,
                        EOP_EIDLE, EOP_GENERATE } state_e;


typedef enum logic [4:0] { RX_IDLE = 0, SHIFT_SYNC = 1, CHECK_SYNC = 2,
                        WAIT_PID = 3, CHECK_PID = 4, TOKEN_BYTE1,
                        WAIT_TOKEN1, TOKEN_BYTE2, WAIT_TOKEN2, DATA_COUNT,
                        DATA_SEND, WAIT_EOP, SEND_OUTPUTS,
                        RX_EIDLE, CRC_BYTE1, CRC_BYTE2, EIDLE_TOKEN, FLUSH_BUFFER } state_rx;


typedef enum logic [3:0] {
 RX_GET_PACKET0, RX_GET_PACKET1, RX_GET_PACKET2, RX_GET_PACKET3,
 RX_GET_PACKET4, RX_GET_PACKET5, RX_GET_PACKET6, RX_GET_PACKET7, RX_GET_PACKET8,
 RX_GET_PACKET9
} RX_state_t;


module usb_rx #(
 // parameters
) (
 input logic clk, n_rst, dp_in, dm_in,
 input logic [6:0] Buffer_Occupancy,
 output logic RX_Data_Ready, RX_Transfer_Active, RX_Error, Flush, Store_RX_Packet_Data,
 output logic [3:0] RX_Packet,
 output logic [7:0] RX_Packet_Data
);


RX_state_t new_state, new_next_state;


logic dp_sync, dm_sync, dp_edge, decoded_bit;
state_e eop_state, next_eop_state;
state_rx rx_state, next_rx_state;


always_ff @(posedge clk, negedge n_rst) begin
 if(~n_rst) begin
     eop_state <= EOP_IDLE;
     rx_state <= RX_IDLE;
 end else begin
     eop_state <= next_eop_state;
     rx_state <= next_rx_state;
 end
end


sync #(.RST_VAL(1)) dpSync(.clk(clk), .n_rst(n_rst), .async_in(dp_in), .sync_out(dp_sync));
sync #(.RST_VAL(0)) dmSync(.clk(clk), .n_rst(n_rst), .async_in(dm_in), .sync_out(dm_sync));


edge_det_updated #(.TRIG_FALL(1), .TRIG_RISE(1), .RST_VAL(1)) dpEdge(.clk(clk), .n_rst(n_rst), .async_in(dp_sync), .edge_flag(dp_edge));


logic prev_dp;
logic clk_div_high, clk_div_enable;


//clock divider 100 mhz -> 12 mhz
logic clear_clk_div;
clk_div_timer_updated clk_divider(.clk(clk), .n_rst(n_rst),
.enable(clk_div_enable), .clk_divided(), .strobe(clk_div_high),
.clear_clk_div(clear_clk_div));


always_ff @(posedge clk, negedge n_rst) begin
 if(~n_rst) begin
     prev_dp <= 1;
 end else if(clk_div_high) begin
     prev_dp <= dp_sync;
 end
end


assign decoded_bit = (prev_dp == dp_sync) ? 1 : 0;


//data shifted in
logic [7:0] rdat;
flex_sr eightbitsr(.clk(clk), .n_rst(n_rst), .shift_enable(clk_div_high), .load_enable(1'b0), .serial_in(decoded_bit), .parallel_in('0), .serial_out(), .parallel_out(rdat));


//clear when 8bits have been counted, count_enable is clock divider output signal
logic rollover_8bit_val, eop_correct;
flex_counter_updated eightbitrollovercounter(.clk(clk), .n_rst(n_rst), .clear(!clk_div_enable), .count_enable(clk_div_high), .rollover_val(4'd8), .flag_val(4'd8), .count_out(), .rollover_flag(rollover_8bit_val));


always_ff @(posedge clk, negedge n_rst) begin
 if (~n_rst) begin
     new_state <= RX_GET_PACKET0;
 end else begin
     new_state <= new_next_state;
 end
end


always_comb begin
 new_next_state = new_state;
 case (new_state)
     RX_GET_PACKET8: begin
         if (rollover_8bit_val) begin
             new_next_state = RX_GET_PACKET9;
         end
     end
     RX_GET_PACKET1: new_next_state = RX_GET_PACKET2;
     RX_GET_PACKET2: new_next_state = RX_GET_PACKET3;
     RX_GET_PACKET3: new_next_state = RX_GET_PACKET4;
     RX_GET_PACKET4: new_next_state = RX_GET_PACKET5;
     RX_GET_PACKET5: new_next_state = RX_GET_PACKET6;
     RX_GET_PACKET6: new_next_state = RX_GET_PACKET7;
     RX_GET_PACKET0: new_next_state = RX_GET_PACKET1;
     RX_GET_PACKET7: new_next_state = RX_GET_PACKET8;
     RX_GET_PACKET9: new_next_state = RX_GET_PACKET0;
     default: new_next_state = new_state;
 endcase
end


logic rollover_edge_det;
always_comb begin
 rollover_edge_det = 1'b0;
 case (new_state)
     RX_GET_PACKET8: begin
         if (rollover_8bit_val) begin
             rollover_edge_det = 1'b1;
         end
     end
     RX_GET_PACKET1,
     RX_GET_PACKET2,
     RX_GET_PACKET3,
     RX_GET_PACKET4,
     RX_GET_PACKET5,
     RX_GET_PACKET6,
     RX_GET_PACKET0,
     RX_GET_PACKET7,
     RX_GET_PACKET9: rollover_edge_det = 1'b0;
     default: rollover_edge_det = 1'b0;
 endcase
end




//EOP generator
logic eop_err, eop_complete;
always_comb begin
 next_eop_state = eop_state;
 eop_correct = 0;
 eop_err = 0;
 eop_complete = 0;


     case(eop_state)
         EOP_IDLE: begin
             if(clk_div_high) begin
                 if(~dp_sync && ~dm_sync) begin
                     next_eop_state = FIRST_EOP_BIT;
                 end
             end
         end


         FIRST_EOP_BIT: begin
             if(clk_div_high) begin
                 if(~dp_sync && ~dm_sync) begin
                     next_eop_state = EOP_GENERATE;
                 end








                 if(dp_sync) begin
                     next_eop_state = EOP_EIDLE;
                 end
             end
         end


         EOP_GENERATE: begin
             if(clk_div_high) begin
                 eop_complete = 1;


                 if(dp_sync) begin
                     next_eop_state = EOP_IDLE;
                     eop_correct = 1;
                 end


                 if(~dp_sync && ~dm_sync) begin
                     next_eop_state = EOP_EIDLE;
                     eop_correct = 0;
                 end
             end
         end


         EOP_EIDLE: begin
             eop_err = 1;
          
             if(clk_div_high) begin
                 if(~dp_sync && ~dm_sync) begin
                     next_eop_state = FIRST_EOP_BIT;
                 end
             end
         end


         default: next_eop_state = eop_state;
     endcase
end




//determining what kind of usb packet id it is and if there is a valid id
logic out_token_id, in_token_id, data_zero, data_one, ack;
logic next_out_token_id, next_in_token_id, next_data_zero, next_data_one, next_ack;
always_ff @(posedge clk, negedge n_rst) begin
 if(~n_rst) begin
     out_token_id <= 0;
     in_token_id <= 0;
     data_zero <= 0;
     data_one <= 0;
     ack <= 0;
 end else begin
     out_token_id <= next_out_token_id;
     in_token_id <= next_in_token_id;
     data_zero <= next_data_zero;
     data_one <= next_data_one;
     ack <= next_ack;
 end
end


//crc buffers
logic [7:0] crc_buffer1, crc_buffer2;
logic [3:0] next_rx_packet;


logic start_filling_1, next_start_filling_1;


logic crc_filled_2, next_crc_filled_2;
always_ff @(posedge clk, negedge n_rst) begin
 if(~n_rst) begin
     crc_buffer1 <= '0;
     crc_buffer2 <= '0;
     RX_Packet_Data <= '0;
     RX_Packet <= '0;
     crc_filled_2 <= 0;


     start_filling_1 <= 0;
 end else if(next_start_filling_1) begin
     crc_buffer1 <= rdat;
  
 end else if(next_crc_filled_2) begin
     crc_buffer1 <= rdat;
     crc_buffer2 <= crc_buffer1;
     RX_Packet_Data <= crc_buffer2;
 end
  else begin
     crc_filled_2 <= next_crc_filled_2;
     RX_Packet <= next_rx_packet;
     start_filling_1 <= next_start_filling_1;
 end
end




logic crc_filled, next_crc_filled;


always_ff @(posedge clk, negedge n_rst) begin
   if(~n_rst) begin
       crc_filled <= 0;
   end else begin
       crc_filled <= next_crc_filled;
   end
end


//RX state machine
always_comb begin
 next_rx_state = rx_state;
 next_rx_packet = RX_Packet;
 next_out_token_id = out_token_id;
 next_in_token_id = in_token_id;
 next_data_one = data_one;
 next_data_zero = data_zero;
 next_ack = ack;


 next_crc_filled = crc_filled;


 RX_Data_Ready = 0;
 RX_Transfer_Active = 0;
 RX_Error = 0;


 Flush = 0;
 Store_RX_Packet_Data = 0;


 clk_div_enable = 0;
 clear_clk_div = 0;


 next_start_filling_1 = start_filling_1;
 next_crc_filled_2 = crc_filled_2;


 if(dp_edge) begin
     clear_clk_div = 1;
 end else begin
     clear_clk_div = 0;
 end


 case(rx_state)
     RX_IDLE: begin
         if(dp_edge) begin
             next_rx_state = SHIFT_SYNC;
         end
     end


     SHIFT_SYNC: begin
         RX_Transfer_Active = 1;
         clk_div_enable = 1;
      
         if(rollover_edge_det) begin
             next_rx_state = CHECK_SYNC;
         end
     end


     CHECK_SYNC: begin
         RX_Transfer_Active = 1;
         clk_div_enable = 1;


         if((rdat == 8'b1000_0000) && !eop_correct) begin
             next_rx_state = WAIT_PID;
         end


         if((rdat != 8'b1000_0000) || eop_correct) begin
             next_rx_state = FLUSH_BUFFER;
         end
     end


     WAIT_PID: begin
         RX_Transfer_Active = 1;
         clk_div_enable = 1;


         if(eop_correct) begin
             next_rx_state = FLUSH_BUFFER;
         end


         if(rollover_edge_det) begin
             next_rx_state = CHECK_PID;
         end
     end




     CHECK_PID: begin
         RX_Transfer_Active = 1;
         clk_div_enable = 1;


         if(eop_correct || ((rdat != 8'b1110_0001) || (rdat != 8'b0110_1001) || (rdat != 8'b1100_0011) || (rdat != 8'b0100_1011) || (rdat != 8'b1101_0010))) begin
             next_rx_state = FLUSH_BUFFER;
         end




         if((rdat == 8'b1110_0001) || (rdat == 8'b0110_1001)) begin
             next_rx_state = TOKEN_BYTE1;
             next_out_token_id = rdat == 8'b1110_0001 ? 1 : 0;
             next_in_token_id = rdat == 8'b0110_1001 ? 1 : 0;
         end


         if((rdat == 8'b1100_0011) || (rdat == 8'b0100_1011)) begin
             next_rx_state = DATA_COUNT;
             Flush = 1;
             next_data_zero = rdat == 8'b1100_0011 ? 1 : 0;
             next_data_one = rdat == 8'b0100_1011 ? 1 : 0;
         end


         if(rdat == 8'b1101_0010) begin
             next_rx_state = WAIT_EOP;
             next_ack = rdat == 8'b1101_0010 ? 1 : 0;
         end
     end


     TOKEN_BYTE1: begin
         RX_Transfer_Active = 1;
         clk_div_enable = 1;


         if(eop_correct && !rollover_edge_det) begin
             next_rx_state = FLUSH_BUFFER;
         end


         if(rollover_edge_det) begin
             next_rx_state = WAIT_TOKEN1;
         end
     end




     WAIT_TOKEN1: begin ////check address and endpoint bits
         RX_Transfer_Active = 1;
         clk_div_enable = 1;


         if(eop_correct) begin
             next_rx_state = FLUSH_BUFFER;
         end else if((rdat != 8'b00000000)) begin
             next_rx_state = EIDLE_TOKEN;
         end else begin
             next_rx_state = TOKEN_BYTE2;
         end
     end


     TOKEN_BYTE2: begin
         RX_Transfer_Active = 1;
         clk_div_enable = 1;


         if(eop_correct && !rollover_edge_det) begin
             next_rx_state = FLUSH_BUFFER;
         end


         if(rollover_edge_det) begin
             next_rx_state = WAIT_TOKEN2;
         end
     end


     WAIT_TOKEN2: begin
         RX_Transfer_Active = 1;
         clk_div_enable = 1;
  
         if(eop_correct || (rdat[4:0] != 5'b11111)) begin
             next_rx_state = RX_EIDLE;
         end else if((rdat[7:5] != 3'b000) && (rdat[4:0] == 5'b11111)) begin
             next_rx_state = EIDLE_TOKEN;
         end else begin
             next_rx_state = WAIT_EOP;
         end
     end


     EIDLE_TOKEN: begin
         clk_div_enable = 1;


         if(eop_complete && eop_correct && ~eop_err) begin
           next_rx_state = RX_IDLE;
         end
     end


     DATA_COUNT: begin
         RX_Transfer_Active = 1;
         clk_div_enable = 1;


         if(rollover_edge_det && ~crc_filled) begin
             next_rx_state = CRC_BYTE1;
             next_start_filling_1 = 1;
         end


         else if(rollover_edge_det && crc_filled) begin
             next_rx_state = DATA_SEND;
             next_crc_filled_2 = 1;
         end


         else if(eop_correct && ~rollover_edge_det) begin
             next_rx_state = FLUSH_BUFFER;
         end


         else begin
           next_rx_state = DATA_COUNT;
         end
     end


     CRC_BYTE1: begin
         RX_Transfer_Active = 1;
         clk_div_enable = 1;


         if(rollover_edge_det) begin
             next_rx_state = CRC_BYTE2;
             next_start_filling_1 = 0;
             next_crc_filled_2 = 1;
         end
     end


     CRC_BYTE2: begin
         RX_Transfer_Active = 1;
         clk_div_enable = 1;
         next_crc_filled = |crc_buffer2;


         if(rollover_edge_det) begin
             next_rx_state = DATA_SEND;
             next_crc_filled_2 = 1;
         end
     end


     DATA_SEND: begin //up to 64 bytes so can buffer_occupancy be <= 64?
         clk_div_enable = 1;
         RX_Transfer_Active = 1;
         Store_RX_Packet_Data = 1;


         if(~eop_correct && ~eop_complete && (Buffer_Occupancy <= 64)) begin
             next_rx_state = DATA_COUNT;
         end


         if((Buffer_Occupancy > 64) || (eop_complete && ~eop_correct)) begin
             next_rx_state = FLUSH_BUFFER;
         end


         if(~dm_sync && ~dp_sync && (Buffer_Occupancy <= 64)) begin
             next_rx_state = WAIT_EOP;
             next_crc_filled = 0;
         end
     end




     WAIT_EOP: begin //check crc bytes
         RX_Transfer_Active = 1;
         clk_div_enable = 1;


        
         if(in_token_id || out_token_id) begin
           if(eop_err) begin
               next_rx_state = FLUSH_BUFFER;
           end else if(~eop_err && eop_correct && eop_complete) begin
               next_rx_state = SEND_OUTPUTS;
           end
         end


         if(data_zero || data_one) begin
           if(eop_err || (crc_buffer1 != 8'b11111111) || (crc_buffer2 != 8'b11111111)) begin
               next_rx_state = FLUSH_BUFFER;
           end else if(~eop_err && eop_correct && eop_complete && (crc_buffer1 == 8'b11111111) && (crc_buffer2 == 8'b11111111)) begin
               next_rx_state = SEND_OUTPUTS;
           end
         end


         if(ack) begin
           if(eop_err) begin
               next_rx_state = FLUSH_BUFFER;
           end else if(~eop_err && eop_correct && eop_complete) begin
               next_rx_state = SEND_OUTPUTS;
           end
         end
     end




     SEND_OUTPUTS: begin
         if(data_one) begin
             next_rx_packet = 4'b1011;
             next_data_one = 0;
         end else if(data_zero) begin
             next_rx_packet = 4'b0011;
             next_data_zero = 0;
         end else if(in_token_id) begin
             next_rx_packet = 4'b1001;
             next_in_token_id = 0;
         end else if(out_token_id) begin
             next_rx_packet = 4'b0001;
             next_out_token_id = 0;
         end else if(ack) begin
             next_rx_packet = 4'b0010;
             next_ack = 0;
         end


         RX_Data_Ready = 1;
         RX_Transfer_Active = 1;
         next_rx_state = RX_IDLE;
     end


     FLUSH_BUFFER: begin
         Flush = 1;
         next_rx_state = RX_EIDLE;
     end


     RX_EIDLE: begin
         RX_Error = 1;
         clk_div_enable = 1;


         if(eop_complete && eop_correct && ~eop_err) begin
             next_rx_state = RX_IDLE;
         end


         if(data_one) begin
             next_data_one = 0;
         end else if(data_zero) begin
             next_data_zero = 0;
         end else if(in_token_id) begin
             next_in_token_id = 0;
         end else if(out_token_id) begin
             next_out_token_id = 0;
         end else if(ack) begin
             next_ack = 0;
         end
     end


     default: next_rx_state = rx_state;
 endcase
end


endmodule




module edge_det_updated #(
 parameter TRIG_RISE = 1,
 parameter TRIG_FALL = 0,
 parameter RST_VAL = 0
) (
 input logic clk, n_rst, async_in,
 output logic edge_flag
);


logic initalsyncout;


always_ff @(posedge clk, negedge n_rst) begin
 if(~n_rst) begin
     initalsyncout <= RST_VAL;
 end else begin
     initalsyncout <= async_in;
 end
end


assign edge_flag = (TRIG_RISE && !initalsyncout && async_in) || (TRIG_FALL && initalsyncout && !async_in);


endmodule




typedef enum logic [1:0] {RX_COUNT_8_1, RX_COUNT_8_2, RX_COUNT_9} RX_state_clk_div;


module clk_div_timer_updated (
     input logic clk, n_rst, enable, clear_clk_div,
     output logic clk_divided, strobe
);


logic clear_counter, count_enable;
logic [3:0] rollover_val;
logic rollover_flag;
RX_state_clk_div state, next_state;


flex_counter_updated #(.SIZE(4)) counting(.clk(clk), .n_rst(n_rst), .clear(clear_counter || clear_clk_div), .count_enable(count_enable),
                                .flag_val(4'd3), .rollover_val(rollover_val), .count_out(), .rollover_flag(rollover_flag));


always_ff @(posedge clk, negedge n_rst) begin
 if (~n_rst) begin
     state <= RX_COUNT_8_1;
 end else begin
     state <= next_state;
 end
end


always_ff @(posedge clk, negedge n_rst) begin
 if (~n_rst) begin
     clk_divided <= 1'b0;
 end else if (enable) begin
     if (rollover_flag) begin
         clk_divided <= ~clk_divided;
     end
 end
end


always_comb begin
 next_state = state;
 case(state)
     RX_COUNT_8_1: begin
         if (rollover_flag) begin
             next_state = RX_COUNT_8_2;
         end
     end
     RX_COUNT_8_2: begin
         if (rollover_flag) begin
             next_state = RX_COUNT_9;
         end
     end
     RX_COUNT_9: begin
         if (rollover_flag) begin
             next_state = RX_COUNT_8_1;
         end
     end
     default: next_state = state;
 endcase
end


assign count_enable = enable;
assign clear_counter = ~enable;
assign strobe = rollover_flag;


always_comb begin
 case(state)
     RX_COUNT_8_1: rollover_val = 4'd8;
     RX_COUNT_8_2: rollover_val = 4'd8;
     RX_COUNT_9: rollover_val = 4'd9;
     default: rollover_val = 4'd8;
 endcase
end


endmodule




module flex_counter_updated #(parameter SIZE = 4)
(
 input logic clk, n_rst, clear, count_enable,
 input logic [SIZE-1:0] rollover_val,
 input logic [SIZE-1:0] flag_val,
 output logic [SIZE-1:0] count_out,
 output logic rollover_flag
);


logic [SIZE-1:0] nextCount;
logic nextFlag;


always_ff @(posedge clk, negedge n_rst) begin
 if(~n_rst) begin
     count_out <= '0;
     rollover_flag <= 0;
 end else begin
     count_out <= nextCount;
     rollover_flag <= nextFlag;
 end 
end


always_comb begin


 if(clear == 1'b1) begin
     nextCount = '0;
 end


 else if(clear == 1'b0 && count_enable == 1'b1) begin
     nextCount = count_out + 1;
     if(count_out >= rollover_val) begin
         nextCount = 'd1;
     end
 end


  else begin
     nextCount = count_out;
 end
end


always_comb begin
 if(nextCount == flag_val) begin
     nextFlag = 1'b1;
 end else begin
     nextFlag = 1'b0;
 end
end


endmodule









