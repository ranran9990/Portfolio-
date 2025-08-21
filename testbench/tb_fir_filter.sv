`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_fir_filter ();

    localparam CLK_PERIOD = 10ns;

    logic clk, n_rst, load_coeff, data_ready, one_k_samples, modwait, err;
    logic [15:0] sample_data, fir_coefficient, fir_out;

    fir_filter filter (.clk(clk), .n_rst(n_rst), .load_coeff(load_coeff), .data_ready(data_ready), .one_k_samples(one_k_samples), .modwait(modwait), .err(err), .sample_data(sample_data), .fir_coefficient(fir_coefficient), .fir_out(fir_out));

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

    task insert_coeff;
    begin
        load_coeff = 1;
        @(negedge clk);
        @(negedge clk);
        fir_coefficient = 16'h8000;
        @(negedge clk);
        @(negedge clk);
        fir_coefficient = 16'hC000;
        @(negedge clk);
        @(negedge clk);
        fir_coefficient = 16'h4000;
        @(negedge clk);
        @(negedge clk);
        fir_coefficient = 16'h2000;
        // fir_coefficient = 16'h1000;
        // @(negedge clk);
        // @(negedge clk);
    end
    endtask

    task insert_sample;
    input logic [15:0] sample;

    begin        
        sample_data = sample;
        data_ready = 1;
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        data_ready = 0;
        @(negedge clk);
        @(negedge clk);
    end
    endtask

    initial begin
        n_rst = 1;
        sample_data = 0;
        fir_coefficient = 0;
        load_coeff = 0;
        data_ready = 0;
        reset_dut();

        //coefficients
        insert_coeff();
        load_coeff = 0;
        @(negedge clk);
        @(negedge clk);

        //samples
        insert_sample(.sample(16'h1234));
        #(CLK_PERIOD * 30);
        insert_sample(.sample(16'h2345));
        #(CLK_PERIOD * 30);
        insert_sample(.sample(16'h4321));
        #(CLK_PERIOD * 30);
        insert_sample(.sample(16'h3241));
        #(CLK_PERIOD * 30);
        insert_sample(.sample(16'hFFFF));
        #(CLK_PERIOD * 30);
        insert_sample(.sample(16'h8888));
        #(CLK_PERIOD * 30);


        // insert_sample(.sample(16'h1234));
        // insert_sample(.sample(16'h2345));
        // insert_sample(.sample(16'h4321));
        // insert_sample(.sample(16'h3241));
        // #(CLK_PERIOD * 10);

        // insert_sample(.sample(16'h1234));
        // insert_sample(.sample(16'h2345));
        // insert_sample(.sample(16'h4321));
        // insert_sample(.sample(16'h3241));
        // #(CLK_PERIOD * 10);

        // insert_sample(.sample(16'h1234));
        // insert_sample(.sample(16'h2345));
        // insert_sample(.sample(16'h4321));
        // insert_sample(.sample(16'h3241));
        // #(CLK_PERIOD * 10);

        $finish;
    end
endmodule

/* verilator coverage_on */

