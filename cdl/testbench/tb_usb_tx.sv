`timescale 1ns / 10ps
/* verilator coverage_off */ 

module tb_usb_tx ();

    localparam CLK_PERIOD = 10ns;

    string label = "";

    logic clk, 
          n_rst,
          Get_TX_Packet_Data,
          TX_Transfer_Active,
          TX_Error,
          dp_out,
          dm_out;

    logic [6:0] Buffer_Occupancy;
    logic [7:0] TX_Packet_Data;
    logic [2:0] TX_Packet;

    usb_tx #() DUT (.clk(clk),
                    .n_rst(n_rst),
                    .Buffer_Occupancy(Buffer_Occupancy),
                    .TX_Packet_Data(TX_Packet_Data),
                    .TX_Packet(TX_Packet),
                    .Get_TX_Packet_Data(Get_TX_Packet_Data),
                    .TX_Transfer_Active(TX_Transfer_Active),
                    .TX_Error(TX_Error),
                    .dp_out(dp_out),
                    .dm_out(dm_out));

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

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

//DATA0
    task test1;
    begin
        n_rst = 1;
        Buffer_Occupancy = 7'b1;
        TX_Packet_Data = 8'b0;
        TX_Packet = 3'b0;
        reset_dut();

        TX_Packet = 3'b001;
        TX_Packet_Data = 8'b1011_0110;
        #(CLK_PERIOD * 230);
        TX_Packet = '0;
    end
    endtask

//DATA1
    task test2;
    begin
        n_rst = 1;
        Buffer_Occupancy = 7'b1;
        TX_Packet_Data = 8'b0;
        TX_Packet = 3'b0;
        reset_dut();

        TX_Packet = 3'b010;
        TX_Packet_Data = 8'b1011_0110;
        #(CLK_PERIOD * 230);
        TX_Packet = '0;
    end
    endtask

//ACK
    task test3;
    begin
        n_rst = 1;
        Buffer_Occupancy = 7'b1;
        TX_Packet_Data = 8'b0;
        TX_Packet = 3'b0;
        reset_dut();

        TX_Packet = 3'b011;
        TX_Packet_Data = 8'b1011_0110;
        #(CLK_PERIOD * 160);
        TX_Packet = '0;
    end
    endtask

//NAK
    task test4;
    begin
        n_rst = 1;
        Buffer_Occupancy = 7'b1;
        TX_Packet_Data = 8'b0;
        TX_Packet = 3'b0;
        reset_dut();

        TX_Packet = 3'b100;
        TX_Packet_Data = 8'b1011_0110;
        #(CLK_PERIOD * 160);
        TX_Packet = '0;
    end
    endtask

//STALL
    task test5;
    begin
        n_rst = 1;
        Buffer_Occupancy = 7'b1;
        TX_Packet_Data = 8'b0;
        TX_Packet = 3'b0;
        reset_dut();

        TX_Packet = 3'b101;
        TX_Packet_Data = 8'b1011_0110;
        #(CLK_PERIOD * 160);
        TX_Packet = '0;
    end
    endtask


// 1: DATA0: 4'b0011
// 2: DfATA1: 4'b1011
// 3: ACK: 4'b0010
// 4: NAK: 4'b1010
// 5: STALL: 4'b1110

    initial begin

        label = "(39) DATA0 ID";
        test1();

        label = "(40) DATA1 ID";
        test2();

        label = "(41) ACK ID";
        test3();

        label = "(42) NAK ID";
        test4();

        label = "(43) STALL ID";
        test5();

        label = "(44) DATA0: Occupancy > 0";
        Buffer_Occupancy = 7'd2;
        n_rst = 1;
        TX_Packet_Data = 8'b0;
        TX_Packet = '0;
        reset_dut();

        TX_Packet = 3'b001;
        TX_Packet_Data = 8'b1011_0110;
        #(CLK_PERIOD * 400);        


        label = "(45) DATA0: Occupancy = 0";
        Buffer_Occupancy = 7'd0;
        n_rst = 1;
        TX_Packet_Data = 8'b0;
        TX_Packet = '0;
        reset_dut();

        TX_Packet = 3'b001;
        TX_Packet_Data = 8'b1011_0110;
        #(CLK_PERIOD * 200);        

        label = "EXIT ERROR STATE (DATA0 & Buffer Occupancy != 0)";
        Buffer_Occupancy = 7'd0;
        n_rst = 1;
        TX_Packet_Data = 8'b0;
        TX_Packet = '0;
        reset_dut();

        TX_Packet = 3'b001;
        TX_Packet_Data = 8'b1011_0110;
        #(CLK_PERIOD * 20);
        Buffer_Occupancy = 1'b1; 
        #(CLK_PERIOD * 200);


        label = "EXIT ERROR STATE (ACK)";
        Buffer_Occupancy = 7'd0;
        n_rst = 1;
        TX_Packet_Data = 8'b0;
        TX_Packet = '0;
        reset_dut();

        TX_Packet = 3'b001;
        TX_Packet_Data = 8'b1011_0110;
        #(CLK_PERIOD * 20);

        TX_Packet = 3'd3;
        #(CLK_PERIOD * 160);

        label = "EXIT ERROR STATE (NAK)";
        Buffer_Occupancy = 7'd0;
        n_rst = 1;
        TX_Packet_Data = 8'b0;
        TX_Packet = '0;
        reset_dut();

        TX_Packet = 3'b001;
        TX_Packet_Data = 8'b1011_0110;
        #(CLK_PERIOD * 20);

        TX_Packet = 3'd4;
        #(CLK_PERIOD * 160);


        label = "EXIT ERROR STATE (STALL)";
        Buffer_Occupancy = 7'd0;
        n_rst = 1;
        TX_Packet_Data = 8'b0;
        TX_Packet = '0;
        reset_dut();

        TX_Packet = 3'b001;
        TX_Packet_Data = 8'b1011_0110;
        #(CLK_PERIOD * 20);

        TX_Packet = 3'd5;
        #(CLK_PERIOD * 160);

        label = "Invalid ID";
        Buffer_Occupancy = 7'd0;
        n_rst = 1;
        TX_Packet_Data = 8'b0;
        TX_Packet = '0;
        reset_dut();

        TX_Packet = 3'b001;
        TX_Packet_Data = 8'b1011_0110;
        #(CLK_PERIOD * 20);

        TX_Packet = 3'd6;
        #(CLK_PERIOD * 160);


        label = "(46) CHECK ENCODER";
        Buffer_Occupancy = 7'd1;
        n_rst = 1;
        TX_Packet_Data = 8'b0;
        TX_Packet = '0;
        reset_dut();

        TX_Packet = 3'b001;
        TX_Packet_Data = 8'b0000_0000;
        #(CLK_PERIOD * 250);

        label = "(46) CHECK ENCODER";
        Buffer_Occupancy = 7'd1;
        n_rst = 1;
        TX_Packet_Data = 8'b0;
        TX_Packet = '0;
        reset_dut();

        TX_Packet = 3'b001;
        TX_Packet_Data = 8'b1111_1111;
        #(CLK_PERIOD * 250);



        




        $finish;
    end
endmodule

/* verilator coverage_on */

