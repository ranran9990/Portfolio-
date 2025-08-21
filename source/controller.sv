`timescale 1ns / 10ps

typedef enum logic [4:0] {
    IDLE, ERROR, LOAD_SAMPLE, CLEAR_R0,
    WAIT0, WAIT1, WAIT2, 
    F0, F1, F2, F3,
    SHIFT0, SHIFT1, SHIFT2, SHIFT3,
    MULTIPLY0, MULTIPLY1, MULTIPLY2, MULTIPLY3,
    SUBTRACT0, SUBTRACT1, ADDITION, OUTPUT
} state_t;

module controller (
    input logic clk,
    input logic n_rst,
    input logic dr,
    input logic lc,
    input logic overflow,
    output logic cnt_up,
    output logic clear,
    output logic modwait,
    output logic [2:0] op,
    output logic [3:0] src1,
    output logic [3:0] src2,
    output logic [3:0] dest,
    output logic err
);

state_t state, next_state; 
logic next_modwait;

always_ff @(posedge clk, negedge n_rst) begin
    if (~n_rst) begin
        state <= IDLE;
        modwait <= 1'b0;
    end else begin
        state <= next_state;
        modwait <= next_modwait;
    end
end

always_comb begin
    next_state = state;
    next_modwait = modwait;

    case (state) 
        IDLE: begin
            if (lc) begin
                next_state = F0;
                next_modwait = 1'b1;
            end
            if (~lc & dr) begin
                next_state = LOAD_SAMPLE;
                next_modwait = 1'b1;
            end
        end

        F0: begin
            next_state = WAIT0;
            next_modwait = 1'b0;
        end

        WAIT0: begin
            if (lc) begin
                next_state = F1;
                next_modwait = 1'b1;
            end
        end

        F1: begin
            next_state = WAIT1;
            next_modwait = 1'b0;
        end

        WAIT1: begin
            if (lc) begin
                next_state = F2;
                next_modwait = 1'b1;
            end
        end

        F2: begin
            next_state = WAIT2;
            next_modwait = 1'b0;
        end

        WAIT2: begin
            if (lc) begin
                next_state = F3;
                next_modwait = 1'b1;
            end
        end

        F3: begin 
            next_state = IDLE;
            next_modwait = 1'b0;
        end

        LOAD_SAMPLE: begin
            if (~dr) begin
                next_state = ERROR;
                next_modwait = 1'b0;
            end
            if (dr) begin
                next_state = CLEAR_R0;
                next_modwait = 1'b1;
            end
        end

        CLEAR_R0: begin
            next_state = SHIFT0;
            next_modwait = 1'b1;
        end

        SHIFT0: begin
            next_state = SHIFT1;
            next_modwait = 1'b1;
        end

        SHIFT1: begin
            next_state = SHIFT2;
            next_modwait = 1'b1;
        end

        SHIFT2: begin
            next_state = SHIFT3;
            next_modwait = 1'b1;
        end

        SHIFT3: begin
            next_state = MULTIPLY0;
            next_modwait = 1'b1;
        end

        MULTIPLY0: begin
            if (overflow) begin
                next_state = ERROR;
                next_modwait = 1'b0;
            end else begin
                next_state = MULTIPLY1;
                next_modwait = 1'b1;
            end
        end

        MULTIPLY1: begin
            if (overflow) begin
                next_state = ERROR;
                next_modwait = 1'b0;
            end else begin
                next_state = MULTIPLY2;
                next_modwait = 1'b1;
            end
        end

        MULTIPLY2: begin
            if (overflow) begin
                next_state = ERROR;
                next_modwait = 1'b0;
            end else begin
                next_state = MULTIPLY3;
                next_modwait = 1'b1;
            end
        end

        MULTIPLY3: begin
            if (overflow) begin
                next_state = ERROR;
                next_modwait = 1'b0;
            end else begin
                next_state = SUBTRACT0;
                next_modwait = 1'b1;
            end
        end

        SUBTRACT0: begin
            if (overflow) begin
                next_state = ERROR;
                next_modwait = 1'b0;
            end else begin
                next_state = ADDITION;
                next_modwait = 1'b1;
            end
        end

        ADDITION: begin
            if (overflow) begin
                next_state = ERROR;
                next_modwait = 1'b0;
            end else begin
                next_state = SUBTRACT1;
                next_modwait = 1'b1;
            end
        end

        SUBTRACT1: begin
            if (overflow) begin
                next_state = ERROR;
                next_modwait = 1'b0;
            end else begin
                next_state = OUTPUT;
                next_modwait = 1'b1;
            end
        end

        OUTPUT: begin
            next_state = IDLE;
            next_modwait = 1'b0;
        end

        ERROR: begin
            if (dr) begin
                next_state = LOAD_SAMPLE;
                next_modwait = 1'b1;
            end
            if (lc) begin
                next_state = F0;
                next_modwait = 1'b1;               
            end
        end

        default: begin
            next_state = state;
            next_modwait = modwait;
        end    
    endcase
end

always_comb begin
    cnt_up = 1'b0;
    clear = 1'b0;
    //modwait = 1'b0;
    op = 3'b000;
    src1 = 4'b0;
    src2 = 4'b0;
    dest = 4'b0;
    err = 1'b0;

    case (state) 
        IDLE: begin
            cnt_up = 1'b0;
            clear = 1'b0;
            //modwait = 1'b0;
            op = 3'b000;
            src1 = 4'b0;
            src2 = 4'b0;
            dest = 4'b0;
            err = 1'b0;
        end

        F0: begin
            clear = 1'b1;
            //modwait = 1'b0;
            op = 3'b011;
            dest = 4'd6;
        end

        WAIT0: begin
            cnt_up = 1'b0;
            clear = 1'b0;
            //modwait = 1'b0;
            op = 3'b000;
            src1 = 4'b0;
            src2 = 4'b0;
            dest = 4'b0;
            err = 1'b0;
        end

        F1: begin
            //modwait = 1'b1;
            op = 3'b011;
            dest = 4'd7;
        end

        WAIT1: begin
            cnt_up = 1'b0;
            clear = 1'b0;
            //modwait = 1'b0;
            op = 3'b000;
            src1 = 4'b0;
            src2 = 4'b0;
            dest = 4'b0;
            err = 1'b0;
        end

        F2: begin
            //modwait = 1'b1;
            op = 3'b011;
            dest = 4'd8;
        end

        WAIT2: begin
            cnt_up = 1'b0;
            clear = 1'b0;
            //modwait = 1'b0;
            op = 3'b000;
            src1 = 4'b0;
            src2 = 4'b0;
            dest = 4'b0;
            err = 1'b0;
        end

        F3: begin
            //modwait = 1'b1;
            op = 3'b011;
            dest = 4'd9;
        end

        LOAD_SAMPLE: begin
            op = 3'b010;
            dest = 4'b1;
        end

        CLEAR_R0: begin
            cnt_up = 1'b1;
            //modwait = 1'b1;
            op = 3'b101;
            src1 = 4'b0;
            src2 = 4'b0;
            dest = 4'b0;
        end

        SHIFT0: begin
            //modwait = 1'b1;
            op = 3'b001;
            src1 = 4'd4;
            dest = 4'd5;
        end

        SHIFT1: begin
            //modwait = 1'b1;
            op = 3'b001;
            src1 = 4'd3;
            dest = 4'd4;
        end

        SHIFT2: begin
            //modwait = 1'b1;
            op = 3'b001;
            src1 = 4'd2;
            dest = 4'd3;
        end

        SHIFT3: begin
            //modwait = 1'b1;
            op = 3'b001;
            src1 = 4'b1;
            dest = 4'd2;
        end

        MULTIPLY0: begin
            //modwait = 1'b1;
            op = 3'b110;
            src1 = 4'd2;
            src2 = 4'd6;
            dest = 4'd10;
        end

        MULTIPLY1: begin
            //modwait = 1'b1;
            op = 3'b110;
            src1 = 4'd3;
            src2 = 4'd7;
            dest = 4'd11;
        end

        MULTIPLY2: begin
            //modwait = 1'b1;
            op = 3'b110;
            src1 = 4'd4;
            src2 = 4'd8;
            dest = 4'd12;
        end

        MULTIPLY3: begin
            //modwait = 1'b1;
            op = 3'b110;
            src1 = 4'd5;
            src2 = 4'd9;
            dest = 4'd13;
        end

        SUBTRACT0: begin
            //modwait = 1'b1;
            op = 3'b101;
            src1 = 4'd10;
            src2 = 4'd11;
            dest = 4'd14;
        end

        ADDITION: begin
            //modwait = 1'b1;
            op = 3'b100;
            src1 = 4'd14;
            src2 = 4'd12;
            dest = 4'd15;
        end

        SUBTRACT1: begin
            //modwait = 1'b1;
            op = 3'b101;
            src1 = 4'd15;
            src2 = 4'd13;
            dest = 4'd14;
        end

        OUTPUT: begin
            //modwait = 1'b1;
            op = 3'b001;
            src1 = 4'd14;
            dest = 4'b0;
        end

        ERROR: begin
            err = 1'b1;
        end

        default: begin
            cnt_up = 1'b0;
            clear = 1'b0;
            //modwait = 1'b0;
            op = 3'b000;
            src1 = 4'b0;
            src2 = 4'b0;
            dest = 4'b0;
            err = 1'b0;
        end
    endcase
end

endmodule

