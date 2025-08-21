`timescale 1ns / 10ps

typedef enum logic [6:0] {
    IDLE, ERROR,
    SYNC_BYTE0, SYNC_BYTE1, SYNC_BYTE2, SYNC_BYTE3, SYNC_BYTE4, SYNC_BYTE5, SYNC_BYTE6, SYNC_BYTE7,
    DATA0, DATA1, DATA2, DATA3, DATA4, DATA5, DATA6, DATA7,
    DATA_ONE0, DATA_ONE1, DATA_ONE2, DATA_ONE3, DATA_ONE4, DATA_ONE5, DATA_ONE6, DATA_ONE7,
    ACK0, ACK1, ACK2, ACK3, ACK4, ACK5, ACK6, ACK7,
    NAK0, NAK1, NAK2, NAK3, NAK4, NAK5, NAK6, NAK7,
    STALL0, STALL1, STALL2, STALL3, STALL4, STALL5, STALL6, STALL7,
    BIT0, BIT1, BIT2, BIT3, BIT4, BIT5, BIT6, BIT7, BIT8, BIT9, BIT10, BIT11, BIT12, BIT13, BIT14, BIT15,
    CRC0, CRC1, CRC2, CRC3, CRC4, CRC5, CRC6, CRC7, CRC8, CRC9, CRC10, CRC11, CRC12, CRC13, CRC14, CRC15,
    END_PACKET0, END_PACKET1, END_PACKET2,
    NEW_PACKET0, NEW_PACKET1, NEW_PACKET2, NEW_PACKET3,
    GET_TX_PACKET_DATA0, GET_TX_PACKET_DATA1

} state_t;

typedef enum logic [3:0] {
    GET_PACKET0, GET_PACKET1, GET_PACKET2, GET_PACKET3, GET_PACKET4, GET_PACKET5, GET_PACKET6, GET_PACKET7, GET_PACKET8, GET_PACKET9
} new_state_t;


module usb_tx (
    input logic clk, 
    input logic n_rst,
    input logic [6:0] Buffer_Occupancy,
    input logic [7:0] TX_Packet_Data,
    input logic [2:0] TX_Packet,
    output logic Get_TX_Packet_Data,
    output logic TX_Transfer_Active,
    output logic TX_Error,
    output logic dp_out,
    output logic dm_out
);

state_t state, next_state;
new_state_t new_state, new_next_state;
logic strobe;
logic get_packet;
// logic [7:0] internal_TX_Packet_Data, next_internal_TX_Packet_Data;
// logic encoding;
// logic [6:0] Buffer_Occupancy_new;
logic [2:0] TX_Packet_Reg;


clk_div_timer clk_div(.clk(clk), .n_rst(n_rst), .enable(1'b1), .clk_divided(), .strobe(strobe));


always_ff @(posedge clk, negedge n_rst) begin
  if (~n_rst) begin
    TX_Packet_Reg <= '0;
  end
  else if(state == ERROR || state == IDLE) begin
    TX_Packet_Reg <= TX_Packet;
  end
end



always_ff @(posedge clk, negedge n_rst) begin
    if (~n_rst) begin
        state <= IDLE;
        new_state <= GET_PACKET0;
    end else begin
        if (strobe) begin
        state <= next_state;
        end
        new_state <= new_next_state;
    end
end

always_comb begin
    new_next_state = new_state;

    case (new_state) 
        GET_PACKET0: begin
            if (get_packet) begin
                new_next_state = GET_PACKET1;   
            end
        end
        GET_PACKET1: new_next_state = GET_PACKET2;
        GET_PACKET2: new_next_state = GET_PACKET3;
        GET_PACKET3: new_next_state = GET_PACKET4;
        GET_PACKET4: new_next_state = GET_PACKET5;
        GET_PACKET5: new_next_state = GET_PACKET6;
        GET_PACKET6: new_next_state = GET_PACKET7;
        GET_PACKET7: new_next_state = GET_PACKET8;
        GET_PACKET8: new_next_state = GET_PACKET9;
        GET_PACKET9: new_next_state = GET_PACKET0;
        default: new_next_state = new_state;
    endcase
end

always_comb begin
    Get_TX_Packet_Data = 1'b0;

    case (new_state) 
        GET_PACKET0: begin 
            if (get_packet) begin
                Get_TX_Packet_Data = 1'b1;
            end
        end
        GET_PACKET1,
        GET_PACKET2,
        GET_PACKET3,
        GET_PACKET4,
        GET_PACKET5,
        GET_PACKET6,
        GET_PACKET7,
        GET_PACKET8,
        GET_PACKET9: Get_TX_Packet_Data = 1'b0;
        default: Get_TX_Packet_Data = 1'b0;
    endcase
end


//next_state logic
always_comb begin
    next_state = state;

    case (state) 
        IDLE: begin
                if ((TX_Packet_Reg == 3'b001 | TX_Packet_Reg == 3'b010) & Buffer_Occupancy == '0) begin
                    next_state = ERROR;
                end
                
                else if (TX_Packet_Reg != '0) begin
                    next_state = SYNC_BYTE0;
                end
        end

        SYNC_BYTE0: begin
            next_state = SYNC_BYTE1;
            end
        SYNC_BYTE1: begin
            next_state = SYNC_BYTE2;
            end
        SYNC_BYTE2: begin
            next_state = SYNC_BYTE3;
            end
        SYNC_BYTE3: begin
            next_state = SYNC_BYTE4;
            end
        SYNC_BYTE4: begin
            next_state = SYNC_BYTE5;
            end
        SYNC_BYTE5: begin
            next_state = SYNC_BYTE6;
            end
        SYNC_BYTE6: begin
            next_state = SYNC_BYTE7;
            end

        SYNC_BYTE7: begin
                    if ((TX_Packet_Reg != 3'b001) & (TX_Packet_Reg != 3'b010) & (TX_Packet_Reg != 3'b011) & (TX_Packet_Reg != 3'b100) & (TX_Packet_Reg != 3'b101)) begin
                        next_state = ERROR;
                    end

                    else begin
                        case (TX_Packet_Reg)
                        3'b001: begin
                            if (Buffer_Occupancy != '0) begin
                                next_state = DATA0;
                            end
                            else begin
                                next_state = IDLE;
                            end
                        end
                        3'b010: begin
                            if (Buffer_Occupancy != '0) begin
                                next_state = DATA_ONE0;
                            end
                            else begin
                                next_state = IDLE;
                            end
                        end
                        3'b011: next_state = ACK0;
                        3'b100: next_state = NAK0;
                        3'b101: next_state = STALL0;
                        default: begin
                            next_state = IDLE;
                        end
                        endcase
                    end
        end

        ERROR: begin
                // if (TX_Packet_Reg != 3'b000) begin
                //     next_state = IDLE;
                // end

                if (((TX_Packet_Reg == 3'b001 | TX_Packet_Reg == 3'b010) & Buffer_Occupancy != '0) | (TX_Packet_Reg == 3'd3) | (TX_Packet_Reg == 3'd4) | (TX_Packet_Reg == 3'd5)) begin
                    next_state = IDLE;
                end
        end

        //DATA0
        DATA0: next_state = DATA1;
        DATA1: next_state = DATA2;
        DATA2: next_state = DATA3;
        DATA3: next_state = DATA4;
        DATA4: next_state = DATA5;
        DATA5: next_state = DATA6;
        DATA6: next_state = DATA7;
        DATA7: begin
            if (!TX_Packet_Data[0]) begin
                next_state = BIT1;
                // next_state = GET_TX_PACKET_DATA1;
            end

            if (TX_Packet_Data[0]) begin
                next_state = BIT0;
                // next_state = GET_TX_PACKET_DATA0;
            end
        end

        GET_TX_PACKET_DATA0: next_state = BIT0;
        GET_TX_PACKET_DATA1: next_state = BIT1;

        //DATA1
        DATA_ONE0: next_state = DATA_ONE1;
        DATA_ONE1: next_state = DATA_ONE2;
        DATA_ONE2: next_state = DATA_ONE3;
        DATA_ONE3: next_state = DATA_ONE4;
        DATA_ONE4: next_state = DATA_ONE5;
        DATA_ONE5: next_state = DATA_ONE6;
        DATA_ONE6: next_state = DATA_ONE7;
        DATA_ONE7: begin
            if (!TX_Packet_Data[0]) begin
                next_state = BIT1; 
                // next_state = GET_TX_PACKET_DATA1;                
            end

            if (TX_Packet_Data[0]) begin
                next_state = BIT0; 
                // next_state = GET_TX_PACKET_DATA0;
            end
        end

        //ACK
        ACK0: next_state = ACK1;
        ACK1: next_state = ACK2;
        ACK2: next_state = ACK3;
        ACK3: next_state = ACK4;
        ACK4: next_state = ACK5;
        ACK5: next_state = ACK6;
        ACK6: next_state = ACK7;
        ACK7: next_state = END_PACKET0;

        //NAK
        NAK0: next_state = NAK1;
        NAK1: next_state = NAK2;
        NAK2: next_state = NAK3;
        NAK3: next_state = NAK4;
        NAK4: next_state = NAK5;
        NAK5: next_state = NAK6;
        NAK6: next_state = NAK7;
        NAK7: next_state = END_PACKET0;
    
        //STALL
        STALL0: next_state = STALL1;
        STALL1: next_state = STALL2;
        STALL2: next_state = STALL3;
        STALL3: next_state = STALL4;
        STALL4: next_state = STALL5;
        STALL5: next_state = STALL6;
        STALL6: next_state = STALL7;
        STALL7: next_state = END_PACKET0;

        //END_PACKET
        END_PACKET0: next_state = END_PACKET1;
        END_PACKET1: next_state = END_PACKET2;
        END_PACKET2: next_state = IDLE;

        BIT0: begin
            if (TX_Packet_Data[1]) begin
                next_state = BIT2;
            end

            if (!TX_Packet_Data[1]) begin
                next_state = BIT3;
            end
        end

        BIT1: begin
            if (TX_Packet_Data[1]) begin
                next_state = BIT3;
            end

            if (!TX_Packet_Data[1]) begin
                next_state = BIT2;
            end
        end

        BIT2: begin
            if (TX_Packet_Data[2]) begin
                next_state = BIT4;
            end

            if (!TX_Packet_Data[2]) begin
                next_state = BIT5;
            end
        end

        BIT3: begin
            if (TX_Packet_Data[2]) begin
                next_state = BIT5;
            end

            if (!TX_Packet_Data[2]) begin
                next_state = BIT4;
            end
        end

        BIT4: begin
            if (TX_Packet_Data[3]) begin
                next_state = BIT6;
            end

            if (!TX_Packet_Data[3]) begin
                next_state = BIT7;
            end
        end

        BIT5: begin
            if (TX_Packet_Data[3]) begin
                next_state = BIT7;
            end

            if (!TX_Packet_Data[3]) begin
                next_state = BIT6;
            end
        end

        BIT6: begin
            if (TX_Packet_Data[4]) begin
                next_state = BIT8;
            end

            if (!TX_Packet_Data[4]) begin
                next_state = BIT9;
            end
        end

        BIT7: begin
            if (TX_Packet_Data[4]) begin
                next_state = BIT9;
            end

            if (!TX_Packet_Data[4]) begin
                next_state = BIT8;
            end
        end

        BIT8: begin
            if (TX_Packet_Data[5]) begin
                next_state = BIT10;
            end

            if (!TX_Packet_Data[5]) begin
                next_state = BIT11;
            end
        end

        BIT9: begin
            if (TX_Packet_Data[5]) begin
                next_state = BIT11;
            end

            if (!TX_Packet_Data[5]) begin
                next_state = BIT10;
            end
        end

        BIT10: begin
            if (TX_Packet_Data[6]) begin
                next_state = BIT12;
            end

            if (!TX_Packet_Data[6]) begin
                next_state = BIT13;
            end
        end

        BIT11: begin
            if (TX_Packet_Data[6]) begin
                next_state = BIT13;
            end

            if (!TX_Packet_Data[6]) begin
                next_state = BIT12;
            end
        end

        BIT12: begin
            if (TX_Packet_Data[7]) begin
                next_state = BIT14;
            end

            if (!TX_Packet_Data[7]) begin
                next_state = BIT15;
            end
        end

        BIT13: begin
            if (TX_Packet_Data[7]) begin
                next_state = BIT15;
            end

            if (!TX_Packet_Data[7]) begin
                next_state = BIT14;
            end
        end

        BIT14: begin
            if (Buffer_Occupancy > '0) begin
                if (TX_Packet_Data[0]) begin
                    next_state = BIT0;
                end

                if (!TX_Packet_Data[0]) begin
                    next_state = BIT1;
                end
            end
            if (Buffer_Occupancy == '0) begin
                next_state = CRC0;
            end
        end

        BIT15: begin
            if (Buffer_Occupancy > '0) begin
                if (TX_Packet_Data[0]) begin
                    next_state = BIT1;
                end

                if (!TX_Packet_Data[0]) begin
                    next_state = BIT0;
                end
            end
            if (Buffer_Occupancy == '0) begin
                next_state = CRC0;
            end
        end

        NEW_PACKET0: next_state = BIT1;
        NEW_PACKET1: next_state = BIT1;
        NEW_PACKET2: next_state = BIT1;
        NEW_PACKET3: next_state = BIT1;

        CRC0: next_state = CRC1;
        CRC1: next_state = CRC2;
        CRC2: next_state = CRC3;
        CRC3: next_state = CRC4;
        CRC4: next_state = CRC5;
        CRC5: next_state = CRC6;
        CRC6: next_state = CRC7;
        CRC7: next_state = CRC8;
        CRC8: next_state = CRC9;
        CRC9: next_state = CRC10;
        CRC10: next_state = CRC11;
        CRC11: next_state = CRC12;
        CRC12: next_state = CRC13;
        CRC13: next_state = CRC14;
        CRC14: next_state = CRC15;
        CRC15: next_state = END_PACKET0;
        default: next_state = IDLE;
    endcase
end

//State Logic
always_comb begin
    TX_Transfer_Active = 1'b0;
    TX_Error = 1'b0;
    dp_out = 1'b1;
    dm_out = 1'b0;
    get_packet = 1'b0;
    

    case (state) 
        GET_TX_PACKET_DATA0: begin
            get_packet = 1'b1;
        end

        GET_TX_PACKET_DATA1: begin
            get_packet = 1'b1;
        end

        IDLE: begin
            dp_out = 1'b1;
            TX_Error = 1'b1;
        end

        ERROR: begin
            TX_Error = 1'b1;
            TX_Transfer_Active = 1'b0;
        end

        SYNC_BYTE0: begin
            dp_out = 1'b0;
            dm_out = 1'b1;
            TX_Transfer_Active = 1'b1;
        end
        SYNC_BYTE1: begin
            dp_out = 1'b1;
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        SYNC_BYTE2: begin
            dp_out = 1'b0;
            dm_out = 1'b1;
            TX_Transfer_Active = 1'b1;
        end
        SYNC_BYTE3: begin
            dp_out = 1'b1;
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        SYNC_BYTE4: begin
            dp_out = 1'b0;
            dm_out = 1'b1;
            TX_Transfer_Active = 1'b1;
        end
        SYNC_BYTE5: begin
            dp_out = 1'b1;
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        SYNC_BYTE6: begin
            dp_out = 1'b0;
            dm_out = 1'b1;
            TX_Transfer_Active = 1'b1;
        end
        SYNC_BYTE7: begin
            dp_out = 1'b0;
            dm_out = 1'b1;
            TX_Transfer_Active = 1'b1;
            
        end

        //DATA0  1100_0011
        DATA0: begin
            dp_out = 1'b0;
            dm_out = 1'b1;
            TX_Transfer_Active = 1'b1;
        end
        DATA1: begin
            dp_out = 1'b0;
            dm_out = 1'b1;
            TX_Transfer_Active = 1'b1;
        end
        DATA2: begin
            dp_out = 1'b1;
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        DATA3: begin
            dp_out = 1'b0;
            dm_out = 1'b1;
            TX_Transfer_Active = 1'b1;
        end
        DATA4: begin
            dp_out = 1'b1;
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        DATA5: begin
            dp_out = 1'b0;
            dm_out = 1'b1;
            TX_Transfer_Active = 1'b1;
        end
        DATA6: begin
            dp_out = 1'b0;
            dm_out = 1'b1;
            TX_Transfer_Active = 1'b1;
        end
        DATA7: begin
            dp_out = 1'b0;
            dm_out = 1'b1;
            TX_Transfer_Active = 1'b1;
            get_packet = 1'b1;
        end


        //DATA_ONE0  1101_0010
        DATA_ONE0: begin
            dp_out = 1'b0;
            dm_out = 1'b1;
            TX_Transfer_Active = 1'b1;
        end
        DATA_ONE1: begin
            dp_out = 1'b0;
            dm_out = 1'b1;
            TX_Transfer_Active = 1'b1;
        end
        DATA_ONE2: begin
            dp_out = 1'b1;
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        DATA_ONE3: begin
            dp_out = 1'b1;
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        DATA_ONE4: begin
            dp_out = 1'b0;
            dm_out = 1'b1;
            TX_Transfer_Active = 1'b1;
        end
        DATA_ONE5: begin
            dp_out = 1'b1;
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        DATA_ONE6: begin
            dp_out = 1'b1;
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        DATA_ONE7: begin
            dp_out = 1'b0;
            dm_out = 1'b1;
            TX_Transfer_Active = 1'b1;
            get_packet = 1'b1;
        end


        //ACK  0100_1011
        ACK0: begin
            dp_out = 1'b1;
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        ACK1: begin
            dp_out = 1'b1;
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        ACK2: begin
            dp_out = 1'b0;
            dm_out = 1'b1;
            TX_Transfer_Active = 1'b1;
        end
        ACK3: begin
            dp_out = 1'b1;
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        ACK4: begin
            dp_out = 1'b1;
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        ACK5: begin
            dp_out = 1'b0;
            dm_out = 1'b1;
            TX_Transfer_Active = 1'b1;
        end
        ACK6: begin
            dp_out = 1'b0;
            dm_out = 1'b1;
            TX_Transfer_Active = 1'b1;
        end
        ACK7: begin
            dp_out = 1'b0;
            dm_out = 1'b1;
            TX_Transfer_Active = 1'b1;
        end

        //NAK  0101_1010
        NAK0: begin
            dp_out = 1'b1; 
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        NAK1: begin
            dp_out = 1'b1;
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        NAK2: begin
            dp_out = 1'b0;
            dm_out = 1'b1;
            TX_Transfer_Active = 1'b1;
        end
        NAK3: begin
            dp_out = 1'b0;
            dm_out = 1'b1;
            TX_Transfer_Active = 1'b1;
        end
        NAK4: begin
            dp_out = 1'b0;
            dm_out = 1'b1;
            TX_Transfer_Active = 1'b1;
        end
        NAK5: begin
            dp_out = 1'b1;
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        NAK6: begin
            dp_out = 1'b1;
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        NAK7: begin
            dp_out = 1'b0;
            dm_out = 1'b1;
            TX_Transfer_Active = 1'b1;
        end

        //STALL 0111_1000
        STALL0: begin
            dp_out = 1'b1;
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1; 
        end
        STALL1: begin
            dp_out = 1'b1;
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        STALL2: begin
            dp_out = 1'b1;
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        STALL3: begin
            dp_out = 1'b1;
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        STALL4: begin
            dp_out = 1'b1;
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        STALL5: begin
            dp_out = 1'b0;
            dm_out = 1'b1;
            TX_Transfer_Active = 1'b1;
        end
        STALL6: begin
            dp_out = 1'b1;
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        STALL7: begin
            dp_out = 1'b0;
            dm_out = 1'b1;
            TX_Transfer_Active = 1'b1;
        end


        //ENCODED_BITS
        BIT0: begin
            dp_out = 1'b0;
            dm_out = 1'b1;
            TX_Transfer_Active = 1'b1;
            
        end
        BIT1: begin
            dp_out = 1'b1;
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
            
        end
        BIT2: begin
            dp_out = 1'b0;
            dm_out = 1'b1;
            TX_Transfer_Active = 1'b1;
            
        end
        BIT3: begin
            dp_out = 1'b1;
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
            
        end
        BIT4: begin
            dp_out = 1'b0;
            dm_out = 1'b1;
            TX_Transfer_Active = 1'b1;
            
        end
        BIT5: begin
            dp_out = 1'b1;
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
            
        end
        BIT6: begin
            dp_out = 1'b0;
            dm_out = 1'b1;
            TX_Transfer_Active = 1'b1;
            
        end
        BIT7: begin
            dp_out = 1'b1;
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
            
        end
        BIT8: begin
            dp_out = 1'b0;
            dm_out = 1'b1;
            TX_Transfer_Active = 1'b1;
            
        end
        BIT9: begin
            dp_out = 1'b1;
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
            
        end
        BIT10: begin
            dp_out = 1'b0;
            dm_out = 1'b1;
            TX_Transfer_Active = 1'b1;
            
        end
        BIT11: begin
            dp_out = 1'b1;
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
            
        end
        BIT12: begin
            dp_out = 1'b0;
            dm_out = 1'b1;
            TX_Transfer_Active = 1'b1;
            
        end
        BIT13: begin
            dp_out = 1'b1;
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
            
        end
        BIT14: begin
            dp_out = 1'b0;
            dm_out = 1'b1;
            TX_Transfer_Active = 1'b1;
            get_packet = 1'b1;
            
        end
        BIT15: begin
            dp_out = 1'b1;
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
            get_packet = 1'b1;
            
        end

        //NEW_PACKET
        NEW_PACKET0: begin
            get_packet = 1'b1;
        end
        NEW_PACKET1: begin
            get_packet = 1'b1;
        end
        NEW_PACKET2: begin
            get_packet = 1'b1;
        end
        NEW_PACKET3: begin
            get_packet = 1'b1;
        end

        //END_PACKET
        END_PACKET0: begin
            dp_out = 1'b0;
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end

        END_PACKET1: begin
            dp_out = 1'b0;
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end

        END_PACKET2: begin
            dp_out = 1'b1;
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end

        //CRC
        CRC0: begin
            dp_out = 1'b1;
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        CRC1: begin
            dp_out = 1'b1; 
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        CRC2: begin
            dp_out = 1'b1; 
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        CRC3: begin
            dp_out = 1'b1; 
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        CRC4: begin
            dp_out = 1'b1; 
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        CRC5: begin
            dp_out = 1'b1; 
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        CRC6: begin
            dp_out = 1'b1; 
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        CRC7: begin
            dp_out = 1'b1; 
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        CRC8: begin
            dp_out = 1'b1; 
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        CRC9: begin
            dp_out = 1'b1; 
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        CRC10: begin
            dp_out = 1'b1; 
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        CRC11: begin
            dp_out = 1'b1; 
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        CRC12: begin
            dp_out = 1'b1; 
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        CRC13: begin
            dp_out = 1'b1; 
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        CRC14: begin
            dp_out = 1'b1; 
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        CRC15: begin
            dp_out = 1'b1; 
            dm_out = 1'b0;
            TX_Transfer_Active = 1'b1;
        end
        default: begin
            TX_Transfer_Active = 1'b0;
            TX_Error = 1'b0;
            dp_out = 1'b1;
            dm_out = 1'b0;
        end
    endcase
end

endmodule

