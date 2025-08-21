`timescale 1ns / 10ps

typedef enum logic [3:0] {  
    LOADER_IDLE, LOADER_F0, LOADER_WAIT0, LOADER_F1, LOADER_WAIT1, LOADER_F2, LOADER_WAIT2, LOADER_F3, LOADER_WAIT3, LOADER_CLEAR
} state_loader;

module coefficient_loader (
    input logic clk,
    input logic n_rst,
    input logic new_coefficient_set,
    input logic modwait,
    output logic load_coeff,
    output logic [1:0] coefficient_num,
    output logic clear_coeff
);

state_loader state, next_state;

always_ff @(posedge clk, negedge n_rst) begin
    if (~n_rst) begin
        state <= LOADER_IDLE;
    end else begin
        state <= next_state;
    end
end

always_comb begin
    next_state = state;

    case (state) 

        LOADER_IDLE: begin
            if (new_coefficient_set) begin
                next_state = LOADER_F0;
            end
        end

        LOADER_F0: next_state = LOADER_WAIT0;

        LOADER_WAIT0: begin 
            if (~modwait) begin
                next_state = LOADER_F1;
            end
        end

        LOADER_F1: next_state = LOADER_WAIT1;

        LOADER_WAIT1: begin 
            if (~modwait) begin
                next_state = LOADER_F2;
            end
        end
                    
        LOADER_F2: next_state = LOADER_WAIT2;

        LOADER_WAIT2: begin 
            if (~modwait) begin
                next_state = LOADER_F3;
            end
        end
                    
        LOADER_F3: next_state = LOADER_WAIT3;

        LOADER_WAIT3: begin 
            if (~modwait) begin
                next_state = LOADER_CLEAR;
            end
        end
            
        LOADER_CLEAR: next_state = LOADER_IDLE;

        default:
            next_state = LOADER_IDLE;
    endcase
end

always_comb begin
    load_coeff = 1'b0;
    coefficient_num = 2'b0;
    clear_coeff = 1'b0;

    case (state) 

        LOADER_IDLE: begin
            load_coeff = 1'b0;
            coefficient_num = 2'b0;
            clear_coeff = 1'b0;
        end

        LOADER_F0: begin
            load_coeff = 1'b1;
            coefficient_num = 2'b0;
            clear_coeff = 1'b0;
        end

        LOADER_WAIT0: begin
            load_coeff = 1'b0;
            coefficient_num = 2'b0;
            clear_coeff = 1'b0;
        end

        LOADER_F1: begin
            load_coeff = 1'b1;
            coefficient_num = 2'd1;
            clear_coeff = 1'b0;
        end

        LOADER_WAIT1: begin
            load_coeff = 1'b0;
            coefficient_num = 2'd1;
            clear_coeff = 1'b0;
        end
                    
        LOADER_F2: begin
            load_coeff = 1'b1;
            coefficient_num = 2'd2;
            clear_coeff = 1'b0;
        end

        LOADER_WAIT2: begin
            load_coeff = 1'b0;
            coefficient_num = 2'd2;
            clear_coeff = 1'b0;
        end
                    
        LOADER_F3: begin
            load_coeff = 1'b1;
            coefficient_num = 2'd3;
            clear_coeff = 1'b0;
        end

        LOADER_WAIT3: begin
            load_coeff = 1'b0;
            coefficient_num = 2'd3;
            clear_coeff = 1'b0;
        end
            
        LOADER_CLEAR: begin
            load_coeff = 1'b0;
            coefficient_num = 2'b0;
            clear_coeff = 1'b1;
        end

        default: begin
            load_coeff = 1'b0;
            coefficient_num = 2'b0;
            clear_coeff = 1'b0;
        end
    endcase
end

endmodule

