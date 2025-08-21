`timescale 1ns / 10ps

module ahb_subordinate (
    input logic clk,
    input logic n_rst,
    input logic clear_coeff,
    input logic [1:0] coefficient_num,
    input logic modwait,
    input logic [15:0] fir_out,
    input logic err,
    input logic hsel,
    input logic [3:0] haddr,
    input logic hsize,
    input logic [1:0] htrans,
    input logic hwrite,
    input logic [15:0] hwdata,
    output logic [15:0] sample_data,
    output logic data_ready,
    output logic new_coefficient_set,
    output logic [15:0] fir_coefficient,
    output logic [15:0] hrdata,
    output logic hresp
);

logic [15:0] next_hrdata,
             next_write45,
             sample,
             next_write67,
             next_write89,
             next_writeAB,
             next_writeCD,
             write67,
             write89,
             writeAB,
             writeCD;

logic next_writeE,
      writeE,
      data_ready1, 
      data_ready2,
      pipe_hwrite,
      pipe_hsize,
      pipe_henable,
      henable;

logic [1:0] pipe_htrans;

logic [3:0] pipe_haddr;

always_ff @(posedge clk, negedge n_rst) begin
    if (~n_rst) begin
        sample <= 16'b0;
        write67 <= 16'b0;
        write89 <= 16'b0;
        writeAB <= 16'b0;
        writeCD <= 16'b0;
        writeE <= 1'b0;
        data_ready2 <= 1'b0;
        pipe_hwrite <= 1'b0;
        pipe_hsize <= 1'b0;
        pipe_htrans <= 2'b0;
        pipe_haddr <= 4'b0;
        pipe_henable <= 1'b0;
        hrdata <= 16'b0;
    end else begin
        sample <= next_write45;
        write67 <= next_write67;
        write89 <= next_write89;
        writeAB <= next_writeAB;
        writeCD <= next_writeCD;
        writeE <= next_writeE;
        data_ready2 <= data_ready1;
        pipe_hwrite <= hwrite;
        pipe_hsize <= hsize;
        pipe_htrans <= htrans;
        pipe_haddr <= haddr;
        pipe_henable <= henable;
        hrdata <= next_hrdata;
    end
end

//Hazard and Read
always_comb begin
    next_hrdata = hrdata;
    if((haddr == pipe_haddr) & (htrans ==  2 & pipe_htrans == 2) & (~hwrite & pipe_hwrite)) begin
        next_hrdata = hsize ? hwdata : haddr[0] ? {hwdata[15:8], 8'b0} : {8'b0, hwdata[7:0]};
    end
    else if (~hwrite & hsel & htrans == 2) begin
        if (hsize == 0) begin
            case(haddr)
            4'd0: next_hrdata = {15'b0, modwait | new_coefficient_set};
            4'd1: next_hrdata = {7'b0, err, 8'b0};

            4'd2: next_hrdata = {8'b0, fir_out[7:0]};
            4'd3: next_hrdata = {fir_out[15:8], 8'b0};

            4'd4: next_hrdata = {8'b0, sample[7:0]};
            4'd5: next_hrdata = {sample[15:8], 8'b0};

            4'd6: next_hrdata = {8'b0,  write67[7:0]};
            4'd7: next_hrdata = { write67[15:8], 8'b0};

            4'd8: next_hrdata = {8'b0,  write89[7:0]};
            4'd9: next_hrdata = {write89[15:8], 8'b0};

            4'hA: next_hrdata = {8'b0,  writeAB[7:0]};
            4'hB: next_hrdata = {writeAB[15:8], 8'b0};

            4'hC: next_hrdata = {8'b0,  writeCD[7:0]};
            4'hD: next_hrdata = {writeCD[15:8], 8'b0};

            4'hE: next_hrdata= {15'b0, new_coefficient_set};

            default: begin
                next_hrdata = hrdata;
            end
            endcase
        end

        if (hsize == 1) begin
            case(haddr)
            4'd0: next_hrdata = {7'b0, err, 7'b0, modwait | new_coefficient_set};
            4'd2: next_hrdata = fir_out;
            4'd4: next_hrdata = sample;
            4'd6: next_hrdata = write67;
            4'd8: next_hrdata = write89;
            4'hA: next_hrdata = writeAB;
            4'hC: next_hrdata = writeCD;
            4'hE: next_hrdata = {15'b0, new_coefficient_set};
            default: next_hrdata = hrdata;
            endcase
        end
    end
end

// Write Enable
always_comb begin
    henable = 1'b0;
    hresp = 1'b0;

    if(((haddr == 4'hF)) | (((haddr == 4'd0)|(haddr == 4'd1)|(haddr == 4'd2)|(haddr == 4'd3)) & hwrite & hsel & (htrans == 2'd2))) begin
        hresp = 1'b1;
    end else if((htrans == 2'd2) & hsel & hwrite) begin
        henable = 1'b1;
    end else begin
        henable = 1'b0;
        hresp = 1'b0;
    end
end

//Write 
always_comb begin
    data_ready1 = 1'b0;
    next_write45 = sample_data;
    next_write67 = write67;
    next_write89 = write89;
    next_writeAB = writeAB;
    next_writeCD = writeCD;
    next_writeE = writeE;

    if(clear_coeff) begin
        next_writeE = 1'b0;
    end

    if (pipe_hwrite & pipe_henable) begin
        if(pipe_hsize == 0) begin
            
            case (pipe_haddr)
            4'd4: begin
                next_write45 = {8'b0, hwdata[7:0]};
                data_ready1 = 1'b1;
            end
            4'd5: begin
                next_write45 = {hwdata[15:8], 8'b0};
                data_ready1 = 1'b1;
            end

            4'd6: next_write67 = {8'b0, hwdata[7:0]};
            4'd7: next_write67 = {hwdata[15:8], 8'b0};

            4'd8: next_write89 = {8'b0, hwdata[7:0]};
            4'd9: next_write89 = {hwdata[15:8], 8'b0};

            4'hA: next_writeAB = {8'b0, hwdata[7:0]};
            4'hB: next_writeAB = {hwdata[15:8], 8'b0};

            4'hC: next_writeCD = {8'b0, hwdata[7:0]};
            4'hD: next_writeCD = {hwdata[15:8], 8'b0};

            4'hE: next_writeE = hwdata[0];

            default: begin
                    data_ready1 = 1'b0;
                    next_write45 = sample_data;
                    next_write67 = write67;
                    next_write89 = write89;
                    next_writeAB = writeAB;
                    next_writeCD = writeCD;
                    next_writeE = writeE;
            end
            endcase
        end

        else begin
            case (pipe_haddr)
            4'd4: begin
                next_write45 = hwdata;
                data_ready1 = 1'b1;
            end
            4'd6: next_write67 = hwdata;
            4'd8: next_write89 = hwdata;
            4'hA: next_writeAB = hwdata;
            4'hC: next_writeCD = hwdata;
            4'hE: next_writeE = hwdata[0];

            default: begin
                    data_ready1 = 1'b0;
                    next_write45 = sample_data;
                    next_write67 = write67;
                    next_write89 = write89;
                    next_writeAB = writeAB;
                    next_writeCD = writeCD;
                    next_writeE = writeE;
            end
            endcase
        end
    end
end

//Coefficient Select
always_comb begin
    case (coefficient_num)
    2'd0: fir_coefficient = write67;
    2'd1: fir_coefficient = write89;
    2'd2: fir_coefficient = writeAB;
    2'd3: fir_coefficient = writeCD;
    endcase
end

//Output
always_comb begin
    new_coefficient_set = writeE;
    data_ready = data_ready1 | data_ready2;
    sample_data = sample;
end
endmodule

