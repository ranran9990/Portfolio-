`timescale 1ns / 10ps

typedef enum logic [2:0] {  
    IDLE, LOAD_SOF, SEND_SOF, LOAD_DATA, SEND_DATA, LOAD_EOF, SEND_EOF
} state_t;

module fsm (
    input logic clk,
    input logic n_rst,
    input logic start,
    input logic done,
    input logic end_packet,
    input logic [7:0] data_const,
    input logic [7:0] data_dyn,
    output logic const_select,
    output logic load,
    output logic [7:0] data_out
);

    state_t next_state, current_state;

    always_ff @(posedge clk, negedge n_rst) begin
        if (~n_rst) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    always_comb begin
        next_state = current_state;
        load = 0;
        data_out = 0;
        const_select = 0;   

        case (current_state)
            IDLE: 
                if (start) begin
                    next_state = LOAD_SOF;
                end
            
            LOAD_SOF: begin
                load = 1'b1;
                data_out = data_const;
                const_select = 1'b0;
                next_state = SEND_SOF;
            end

            SEND_SOF:
                if (done) begin 
                    next_state = LOAD_DATA;
                end

            LOAD_DATA: begin
                    data_out = data_dyn;
                    load = 1'b1;
                    const_select = 1'b0;
                    next_state = SEND_DATA;
            end

            SEND_DATA: 
                if (done & ~end_packet) begin
                    next_state = LOAD_DATA; 
                end else if (done & end_packet) begin
                    next_state = LOAD_EOF;
                end 
            
            LOAD_EOF: begin
                load = 1'b1;
                data_out = data_const;
                const_select = 1'b1;
                next_state = SEND_EOF;
            end           

            SEND_EOF:
                if (done) begin
                    next_state = IDLE;
                end

            default: begin
                    load = 0;
                    data_out = 0;
                    const_select = 0;            
                    next_state = IDLE;
            end
        endcase
    end

endmodule

