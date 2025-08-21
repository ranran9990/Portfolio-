`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_data_buffer ();

    localparam CLK_PERIOD = 10ns;

    string label = "";
    logic clk,
        n_rst,
        Get_RX_Data,
        Store_RX_Packet_Data,
        Get_TX_Packet_Data,
        Store_TX_Data,
        Flush,  
        Clear;

    logic [7:0] TX_Data,
                RX_Packet_Data,
                RX_Data,
                TX_Packet_Data;

    logic [6:0] Buffer_Occupancy;


    data_buffer #() DUT (.clk(clk), 
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

    task get_TX;
    begin
        Get_TX_Packet_Data = 1'b1;
        #(CLK_PERIOD)
        Get_TX_Packet_Data = 1'b0;
        #(CLK_PERIOD * 20);
    end
    endtask



    initial begin
        //Pushing and Popping RX
        label = "(32) Pushing and Popping RX (Small)";
        n_rst = 1;
        Flush = 1'b0;
        Clear = 1'b0;
        Get_RX_Data = 1'b0;
        Store_RX_Packet_Data = 1'b0;
        Get_TX_Packet_Data = 1'b0;
        Store_TX_Data = 1'b0;
        TX_Data = 8'b0;
        reset_dut();

        RX_Packet_Data = 8'd44;

        Store_RX_Packet_Data = 1'b1;
        #(CLK_PERIOD);
        RX_Packet_Data = 8'd77;
        #(CLK_PERIOD);
        RX_Packet_Data = 8'd88;
        #(CLK_PERIOD);
        RX_Packet_Data = 8'd99;
        #(CLK_PERIOD);
        Store_RX_Packet_Data = 1'b0;

        Get_RX_Data = 1'b1;
        #(CLK_PERIOD * 4);
        Get_RX_Data = 1'b0;
        #(CLK_PERIOD * 10);

        label = "(33) Pushing and Popping RX (Large)";
        n_rst = 1;
        Flush = 1'b0;
        Clear = 1'b0;
        Get_RX_Data = 1'b0;
        Store_RX_Packet_Data = 1'b0;
        Get_TX_Packet_Data = 1'b0;
        Store_TX_Data = 1'b0;
        TX_Data = 8'b0;
        reset_dut();

        RX_Packet_Data = 8'd44;

        Store_RX_Packet_Data = 1'b1;
        #(CLK_PERIOD);
        RX_Packet_Data = 8'd77;
        #(CLK_PERIOD * 10);
        RX_Packet_Data = 8'd88;
        #(CLK_PERIOD * 10);
        RX_Packet_Data = 8'd99;
        #(CLK_PERIOD * 10);
        Store_RX_Packet_Data = 1'b0;

        Get_RX_Data = 1'b1;
        #(CLK_PERIOD * 4);
        Get_RX_Data = 1'b0;
        #(CLK_PERIOD * 10);

        label = "(34) Pushing and Popping RX (MAX)";
        n_rst = 1;
        Flush = 1'b0;
        Clear = 1'b0;
        Get_RX_Data = 1'b0;
        Store_RX_Packet_Data = 1'b0;
        Get_TX_Packet_Data = 1'b0;
        Store_TX_Data = 1'b0;
        TX_Data = 8'b0;
        reset_dut();

        RX_Packet_Data = 8'd44;

        Store_RX_Packet_Data = 1'b1;
        #(CLK_PERIOD);
        RX_Packet_Data = 8'd77;
        #(CLK_PERIOD * 25);
        RX_Packet_Data = 8'd88;
        #(CLK_PERIOD * 25);
        RX_Packet_Data = 8'd99;
        #(CLK_PERIOD * 25);
        Store_RX_Packet_Data = 1'b0;

        Get_RX_Data = 1'b1;
        #(CLK_PERIOD * 4);
        Get_RX_Data = 1'b0;
        #(CLK_PERIOD * 25);

////////////////////////////////////////////////////

        //Pushing and Popping TX
        label = "(35) Pushing and Popping TX (Small)";
        n_rst = 1;
        Flush = 1'b0;
        Clear = 1'b0;
        Get_RX_Data = 1'b0;
        Store_RX_Packet_Data = 1'b0;
        Get_TX_Packet_Data = 1'b0;
        Store_TX_Data = 1'b0;
        RX_Packet_Data = 8'd0;
        reset_dut();

        TX_Data = 8'd88;

        Store_TX_Data = 1'b1;
        #(CLK_PERIOD);
        TX_Data = 8'd77;
        #(CLK_PERIOD);
        TX_Data = 8'd88;
        #(CLK_PERIOD);
        TX_Data = 8'd99;
        #(CLK_PERIOD);
        Store_TX_Data = 1'b0;

        Get_TX_Packet_Data = 1'b1;
        #(CLK_PERIOD)
        Get_TX_Packet_Data = 1'b0;
        #(CLK_PERIOD * 20);

        Get_TX_Packet_Data = 1'b1;
        #(CLK_PERIOD)
        Get_TX_Packet_Data = 1'b0;
        #(CLK_PERIOD * 20);

        Get_TX_Packet_Data = 1'b1;
        #(CLK_PERIOD)
        Get_TX_Packet_Data = 1'b0;
        #(CLK_PERIOD * 20);

        Get_TX_Packet_Data = 1'b1;
        #(CLK_PERIOD)
        Get_TX_Packet_Data = 1'b0;
        #(CLK_PERIOD * 20);

//Pushing and Popping TX
        label = "(36) Pushing and Popping TX (Large)";
        n_rst = 1;
        Flush = 1'b0;
        Clear = 1'b0;
        Get_RX_Data = 1'b0;
        Store_RX_Packet_Data = 1'b0;
        Get_TX_Packet_Data = 1'b0;
        Store_TX_Data = 1'b0;
        RX_Packet_Data = 8'd0;
        reset_dut();

        TX_Data = 8'd88;

        Store_TX_Data = 1'b1;
        #(CLK_PERIOD * 10);
        TX_Data = 8'd77;
        #(CLK_PERIOD * 1);
        TX_Data = 8'd88;
        #(CLK_PERIOD * 10);
        TX_Data = 8'd99;
        #(CLK_PERIOD * 10);
        Store_TX_Data = 1'b0;

        Get_TX_Packet_Data = 1'b1;
        #(CLK_PERIOD)
        Get_TX_Packet_Data = 1'b0;
        #(CLK_PERIOD * 20);

        Get_TX_Packet_Data = 1'b1;
        #(CLK_PERIOD)
        Get_TX_Packet_Data = 1'b0;
        #(CLK_PERIOD * 20);

        Get_TX_Packet_Data = 1'b1;
        #(CLK_PERIOD)
        Get_TX_Packet_Data = 1'b0;
        #(CLK_PERIOD * 20);

        Get_TX_Packet_Data = 1'b1;
        #(CLK_PERIOD)
        Get_TX_Packet_Data = 1'b0;
        #(CLK_PERIOD * 20);

//Pushing and Popping TX
        label = "(37) Pushing and Popping TX (MAX)";
        n_rst = 1;
        Flush = 1'b0;
        Clear = 1'b0;
        Get_RX_Data = 1'b0;
        Store_RX_Packet_Data = 1'b0;
        Get_TX_Packet_Data = 1'b0;
        Store_TX_Data = 1'b0;
        RX_Packet_Data = 8'd0;
        reset_dut();

        TX_Data = 8'd88;

        Store_TX_Data = 1'b1;
        #(CLK_PERIOD * 2);
        TX_Data = 8'd77;
        #(CLK_PERIOD * 30);
        TX_Data = 8'd88;
        #(CLK_PERIOD * 30);
        TX_Data = 8'd99;
        #(CLK_PERIOD * 30);
        Store_TX_Data = 1'b0;

        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();


        //Clear
        label = "(38) Clear";
        n_rst = 1;
        Flush = 1'b0;
        Clear = 1'b0;
        Get_RX_Data = 1'b0;
        Store_RX_Packet_Data = 1'b0;
        Get_TX_Packet_Data = 1'b0;
        Store_TX_Data = 1'b0;
        RX_Packet_Data = 8'd0;
        reset_dut();

        TX_Data = 8'd88;

        Store_TX_Data = 1'b1;
        #(CLK_PERIOD * 30);
        TX_Data = 8'd77;
        #(CLK_PERIOD * 30);
        TX_Data = 8'd88;
        #(CLK_PERIOD * 30);
        TX_Data = 8'd99;
        #(CLK_PERIOD * 30);
        Store_TX_Data = 1'b0;

        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();

        Clear = 1'b1;
        #(CLK_PERIOD);
        Clear = 1'b0;
        #(CLK_PERIOD * 200);

        Store_TX_Data = 1'b1;
        #(CLK_PERIOD);
        TX_Data = 8'd77;
        #(CLK_PERIOD);
        TX_Data = 8'd88;
        #(CLK_PERIOD);
        TX_Data = 8'd99;
        #(CLK_PERIOD);
        Store_TX_Data = 1'b0;
        get_TX();
        get_TX();


        //Flush
        label = "(38) Flush";
        n_rst = 1;
        Flush = 1'b0;
        Clear = 1'b0;
        Get_RX_Data = 1'b0;
        Store_RX_Packet_Data = 1'b0;
        Get_TX_Packet_Data = 1'b0;
        Store_TX_Data = 1'b0;
        RX_Packet_Data = 8'd0;
        reset_dut();

        TX_Data = 8'd88;

        Store_TX_Data = 1'b1;
        #(CLK_PERIOD * 30);
        TX_Data = 8'd77;
        #(CLK_PERIOD * 30);
        TX_Data = 8'd88;
        #(CLK_PERIOD * 30);
        TX_Data = 8'd99;
        #(CLK_PERIOD * 30);
        Store_TX_Data = 1'b0;

        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        get_TX();
        Flush = 1'b1;
        #(CLK_PERIOD);
        Flush = 1'b0;
        #(CLK_PERIOD * 200);






        $finish;
    end
endmodule

/* verilator coverage_on */

