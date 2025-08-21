`timescale 1ns / 10ps

typedef enum logic [2:0] {
    IDLE, CLEAR_PACKET, START_PACKET, STOP_BIT, EXTRA_CYCLE, END_PACKET
} state_t;

module rcu (
    input logic clk,
    input logic n_rst,
    input logic new_packet_detected,
    input logic packet_done,
    input logic framing_error,
    output logic sbc_clear,
    output logic sbc_enable,
    output logic load_buffer,
    output logic enable_timer
);

    state_t state, next_state;

    always_ff @(posedge clk, negedge n_rst) begin
        if (~n_rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always_comb begin
        next_state = state;

        case (state)
        IDLE:           if (new_packet_detected) begin
                            next_state = CLEAR_PACKET;
                        end

        CLEAR_PACKET:   next_state = START_PACKET;

        START_PACKET:   if (packet_done) begin
                            next_state = STOP_BIT;
                        end

        STOP_BIT:       next_state = EXTRA_CYCLE;

        EXTRA_CYCLE:    begin
                            if (framing_error) begin
                                next_state = IDLE;
                            end else if (~framing_error) begin
                                next_state = END_PACKET;
                            end
                        end
        
        END_PACKET:     next_state = IDLE;
        
        default:        next_state = IDLE;
        endcase
    end

    always_comb begin
        sbc_clear    = 0;
        sbc_enable   = 0;
        load_buffer  = 0;
        enable_timer = 0;

        case (state)
        IDLE:           begin
                            sbc_clear    = 0;
                            sbc_enable   = 0;
                            load_buffer  = 0;
                            enable_timer = 0;
                        end    

        CLEAR_PACKET:   begin
                            sbc_clear    = 1;
                            sbc_enable   = 0;
                            load_buffer  = 0;
                            enable_timer = 0;
                        end

        START_PACKET:   begin
                            sbc_clear    = 0;
                            sbc_enable   = 0;
                            load_buffer  = 0;
                            enable_timer = 1;
                        end

        STOP_BIT:       begin
                            sbc_clear    = 0;
                            sbc_enable   = 1;
                            load_buffer  = 0;
                            enable_timer = 0;
                        end

        EXTRA_CYCLE:    begin
                            sbc_clear    = 0;
                            sbc_enable   = 0;
                            load_buffer  = 0;
                            enable_timer = 0;
                        end

        END_PACKET:     begin
                            sbc_clear    = 0;
                            sbc_enable   = 0;
                            load_buffer  = 1;
                            enable_timer = 0;
                        end

        default:        begin
                            sbc_clear    = 0;
                            sbc_enable   = 0;
                            load_buffer  = 0;
                            enable_timer = 0; 
                        end
        endcase
    end
endmodule

