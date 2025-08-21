`timescale 1ns / 10ps
typedef enum logic [3:0] {
IDLE_AHB,
R_FIRST_BYTE,
R_SECOND_BYTE,
R_THIRD_BYTE,
R_FOURTH_BYTE,
W_FIRST_BYTE,
W_SECOND_BYTE,
W_THIRD_BYTE,
W_FOURTH_BYTE,
RESET_AHB,
CLEAR_AHB,
HREADY,
ERROR_AHB,
ERROR_IDLE_AHB
} statet;
module usb_ahb (
//AHB
input logic clk, n_rst,
input logic hsel,
input logic [3:0] haddr,
input logic [1:0] htrans,
input logic [1:0] hsize,
input logic hwrite,
input logic [31:0] hwdata,
output logic [31:0] hrdata,
output logic hready,
output logic hresp,
output logic D_Mode,
//RX
input logic [3:0] RX_Packet,
input logic RX_Data_Ready,
input logic RX_Transfer_Active,
input logic RX_Error,
//TX_Data
input logic TX_Transfer_Active,
input logic TX_Error,
output logic [2:0] TX_Packet,
//Data Buffer
input logic [6:0] Buffer_Occupancy,
input logic [7:0] RX_Data,
output logic Clear,
output logic [7:0] TX_Data,
output logic Get_RX_Data,
output logic Store_TX_Data
);
//New_data
logic Next_New;
logic New_Data_Ready;
//FSM
statet state, next_state;
//Read Data
logic [31:0]next_hrdata;
//Pipelined Signals
logic henable_p, hwrite_p, henable;
logic [1:0] htrans_p;
logic [3:0] haddr_p, haddr1, haddr2, haddr3;
//Error Signals
logic hresp1, hresp2, hresp3, hresp_p, hresp_int, hresp_delay, hresp_e, hresp_e2;
//hready
logic hready1;
//USB ID Decoding
logic in, out, ack, Data0, Data1;




//Write logic
logic [31:0] TX_Data_AHB, Data_Buffer, next_reg0, next_regC;
logic next_regD;
logic [1:0] hsize1, hsize2, hsize3, hsize4;




always_ff @(posedge clk, negedge n_rst) begin
    if(~n_rst) begin
        //new rx data
        Next_New <= 1'b0;
        New_Data_Ready  <= 1'b0;
        //hsize
        hsize1 <= '0;
        hsize2 <= '0;
        hsize3 <= '0;
        hsize4 <= '0;
        hresp_p<= 0;
        //data & state
        state <= IDLE_AHB;
        hrdata <= '0;
        //Write registers
        Data_Buffer <= '0;
        TX_Data_AHB <= '0;
        Clear <= '0;
        //Pipelined signals
        henable_p <= '0;
        htrans_p <= '0;
        haddr_p <= '0;
        haddr1 <= '0;
        haddr2 <= '0;
        haddr3 <= '0;
        hwrite_p <= '0;
        hresp_delay <= 0;
        hresp_e2 <= '0;
    end else begin
        //new rx data
        New_Data_Ready <= RX_Transfer_Active ? 1'b0 : New_Data_Ready | (RX_Data_Ready & ~Next_New);
        Next_New <= RX_Data_Ready;
        //hsize
        hsize1 <= hsize;
        hsize2 <= hsize1;
        //data & state
        state <= next_state;
        hrdata <= next_hrdata;
        //Write registers
        Data_Buffer <= next_reg0;
        TX_Data_AHB <= next_regC;
        Clear <= next_regD;
        //Pipelined signals
        henable_p <= henable;
        htrans_p <= htrans;
        haddr_p <= haddr;
        haddr1 <= haddr_p;
        haddr2 <= haddr1;
        haddr3 <= haddr2;
        hsize2 <= hsize1;
        hsize3 <= hsize2;
        hsize4 <= hsize3;
        hwrite_p <= hwrite;
        hresp_p <= hresp1;
        hresp_delay <= hresp_int;
        hresp_e2 <= hresp_e;
    end
end




// error logic & write enable
always_comb begin
    hresp1 = 0;
    henable = 0;
    if((hsize == 3) || (((haddr == 4) || (haddr == 5) || (haddr == 6) || (haddr == 7) || (haddr == 8) || (haddr == 9)) && (hwrite && hsel && (htrans == 2)))) begin
        hresp1 = 1;
    end else if(hwrite && hsel && (htrans == 2)) begin
        henable = 1;
    end
end




assign hresp3 = hresp1 || hresp2;
assign hresp_int = hresp3 || hresp_p;
assign hresp = hresp_delay;
assign hresp_e = hresp;




//USB ID Decoding
always_comb begin
    out = 0;
    ack = 0;
    in = 0;
    Data0 = 0;
    Data1 = 0;
    case(RX_Packet)
        1: out = 1;
        2: ack = 1;
        3: Data0 = 1;
        9: in = 1;
        11: Data1 =1;
    endcase
end




// READ LOGIC
always_comb begin




next_hrdata = hrdata;
// RAW hazard
if((haddr == haddr_p) && ~hwrite && hwrite_p && hsel && (htrans == 2) && (htrans_p == 2)) begin
    case(hsize)
        0:
        begin
            case(haddr)
            0: next_hrdata = {24'b0, hwdata[7:0]};
            1: next_hrdata = {16'b0, hwdata[15:8], 8'b0};
            2: next_hrdata = {8'b0, hwdata[23:16], 16'b0};
            3: next_hrdata = {hwdata[31:24], 24'b0};
            12: next_hrdata = {24'b0, hwdata[7:0]};
            13:next_hrdata = {23'b0, hwdata[8], 8'b0};
            default: next_hrdata = hrdata;
        endcase
        end
        1:
        begin
            case(haddr)
            0: next_hrdata = {16'b0, hwdata[15:0]};
            2: next_hrdata = {hwdata[31:16], 16'b0};
            default: next_hrdata = hrdata;
        endcase
        end
        2: next_hrdata = hwdata[31:0];
        default: next_hrdata = hrdata;
    endcase
end




//Checking if reading (nonseq)
else if (hsel && ~hwrite && (htrans == 2) && hready && ~hresp) begin
    if (hsize == 0) begin // 1 byte
        case (haddr)
            4: next_hrdata = {26'b0, Data1, Data0, ack, out, in, New_Data_Ready};
            5: next_hrdata = {22'b0, TX_Transfer_Active, RX_Transfer_Active, 8'b0};
            6: next_hrdata = {15'b0, RX_Error, 16'b0};
            7: next_hrdata = {7'b0,TX_Error, 24'b0};
            8: next_hrdata = {25'b0, Buffer_Occupancy};
            12: next_hrdata = {29'b0, TX_Data_AHB[2:0]};
            13: next_hrdata = {23'b0, Clear, 8'b0};
            default: next_hrdata = hrdata;
        endcase
    end




    if (hsize == 1) begin // 2 byte
        case (haddr)
            4: next_hrdata = {22'b0, TX_Transfer_Active, RX_Transfer_Active, 2'b0, Data1, Data0, ack, out, in, New_Data_Ready};
            6: next_hrdata = {7'b0, TX_Error, 7'b0, RX_Error, 16'b0};
            default: next_hrdata = hrdata;
        endcase
    end
    end




//D mode logic
D_Mode = ~RX_Transfer_Active && TX_Transfer_Active;




//WRITE LOGIC & FSM
next_reg0 = Data_Buffer;
next_regC = TX_Data_AHB;
next_regD = Clear;
Get_RX_Data = 0;
Store_TX_Data = 0;
TX_Data = '0;
hresp2 = 0;
hready1 = 1;
next_state = state;




//FSM
case(state)
    IDLE_AHB: begin
        Get_RX_Data = 0;
        hready1 = 1;
        next_regD = 0;
        if(((haddr == 0) || (haddr == 1) || (haddr == 2) || (haddr == 3)) && hsel && (Buffer_Occupancy == 64) && hwrite && (htrans == 2) && ~hresp && ~hresp_e2) begin
            next_state = CLEAR_AHB;
        end else if(((haddr == 0) || (haddr == 1) || (haddr == 2) || (haddr == 3)) && hsel && ~hwrite && (htrans == 2) && ~hresp && ~hresp_e2) begin
            next_state = R_FIRST_BYTE;
        end else if(((haddr == 0) || (haddr == 1) || (haddr == 2) || (haddr == 3)) && hsel && hwrite && (htrans == 2) && ~hresp && ~hresp_e2) begin
            next_state = W_FIRST_BYTE;
        end
    end
    R_FIRST_BYTE: begin
        Get_RX_Data = 1;
        hready1 = 0;
        next_reg0 = {24'b0, RX_Data};
        next_state = R_SECOND_BYTE;
    end
    R_SECOND_BYTE: begin
        Get_RX_Data = 1;
        hready1 = 0;
        next_reg0[31:8] = {16'b0, RX_Data};
        next_state = R_THIRD_BYTE;
    end
    R_THIRD_BYTE: begin
        Get_RX_Data = 1;
        hready1 = 0;
        next_reg0[23:16] = RX_Data;
        next_state = R_FOURTH_BYTE;
    end
    R_FOURTH_BYTE: begin
        Get_RX_Data = 1;
        hready1 = 0;
        next_reg0[31:24] = RX_Data;
        if (hsize4 == 0) begin // 1 byte
        case (haddr3)
           0: next_hrdata =  {24'b0, Data_Buffer[7:0]};
           1: next_hrdata = {16'b0, Data_Buffer[15:8], 8'b0};
           2: next_hrdata = {8'b0, Data_Buffer[23:16],16'b0};
           3: next_hrdata = {RX_Data, 24'b0};
        endcase
        end
        if (hsize4 == 1) begin // 2 byte
        case (haddr3)
           0: next_hrdata = {16'b0, Data_Buffer[15:0]};
           2: next_hrdata = {RX_Data, Data_Buffer[23:16], 16'b0};
        endcase
        end
        if (hsize4 == 2) begin // 4 byte
        case (haddr3)
           0: next_hrdata = {RX_Data, Data_Buffer[23:0]};
        endcase
        end
        next_state = HREADY;
    end
    W_FIRST_BYTE: begin
        Store_TX_Data = 1;
        hready1 = 0;
        TX_Data = hwdata[7:0];
        if((Buffer_Occupancy == 64)) begin
            next_state = ERROR_AHB;
        end else if((hsize1 == 2'd1) || (hsize1 == 2'd2)) begin
            next_state = W_SECOND_BYTE;
        end else begin
            next_state = HREADY;
        end
    end
    W_SECOND_BYTE: begin
        Store_TX_Data = 1;
        hready1 = 0;
        TX_Data = hwdata[15:8];
        if((Buffer_Occupancy == 64)) begin
            next_state = ERROR_AHB;
        end else if(hsize2 == 2'd2) begin
            next_state = W_THIRD_BYTE;
        end else begin
            next_state = HREADY;
        end
    end
    W_THIRD_BYTE: begin
        Store_TX_Data = 1;
        hready1 = 0;
        TX_Data = hwdata[23:16];
        if((Buffer_Occupancy == 64))begin
            next_state = ERROR_AHB;
        end else begin
            next_state = W_FOURTH_BYTE;
        end
    end
    W_FOURTH_BYTE: begin
        Store_TX_Data = 1;
        hready1 = 0;
        TX_Data = hwdata[31:24];
        if((Buffer_Occupancy == 64))begin
            next_state = ERROR_AHB;
        end else begin
            next_state = HREADY;
        end
    end
    CLEAR_AHB: begin
        next_regD = 1;
        next_state = RESET_AHB;
    end
    RESET_AHB: begin
        next_regD = 0;
        next_state = HREADY;
    end
    HREADY: begin
        hready1 = 1;
        if(((haddr == 0) || (haddr == 1) || (haddr == 2) || (haddr == 3)) && hsel && (Buffer_Occupancy == 64) && hwrite && (htrans == 2)) begin
            next_state = CLEAR_AHB;
        end else if(((haddr == 0) || (haddr == 1) || (haddr == 2) || (haddr == 3)) && hsel && ~hwrite && (htrans == 2)) begin
            next_state = R_FIRST_BYTE;
        end else if(((haddr == 0) || (haddr == 1) || (haddr == 2) || (haddr == 3)) && hsel && hwrite && (htrans == 2)) begin
            next_state = W_FIRST_BYTE;
        end else begin
        next_state = IDLE_AHB;
        end
    end
    ERROR_AHB: begin
        hresp2 = 1;
        hready1 = 0;
        next_state = ERROR_IDLE_AHB;
    end
    ERROR_IDLE_AHB: begin
        hresp2 = 0;
        hready1 = 1;
        next_state = IDLE_AHB;
    end
    default: next_state = state;
endcase




//Write Logic
if(henable_p) begin




if (hsize1 == 0) begin // 1 byte
    case (haddr_p)
        0: next_reg0 =  {24'b0, hwdata[7:0]};
        1: next_reg0 = {16'b0, hwdata[15:8], 8'b0};
        2: next_reg0 = {8'b0, hwdata[23:16],16'b0};
        3: next_reg0 = {hwdata[31:24], 24'b0};
        12: next_regC = {28'b0, hwdata[3:0]};
        13: next_regD = hwdata[8];
    endcase
end




if (hsize1 == 1) begin // 2 byte
    case (haddr_p)
        0: next_reg0 = {16'b0, hwdata[15:0]};
        2: next_reg0 = {hwdata[31:16], 16'b0};
    endcase
end




if (hsize1 == 2) begin // 4 byte
    case (haddr_p)
    0: next_reg0 = hwdata;
    endcase
end
end
if(TX_Transfer_Active) begin
    next_regC = 32'b0;
end
end




assign TX_Packet = TX_Data_AHB[2:0];
assign hready = ~hresp_p && hready1;
endmodule







