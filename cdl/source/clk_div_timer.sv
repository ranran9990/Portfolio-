`timescale 1ns / 10ps

typedef enum logic [1:0] {COUNT_8_1, COUNT_8_2, COUNT_9} state_clk_div;


module clk_div_timer (
    input logic clk, n_rst, enable,    
    output logic clk_divided,
    output logic strobe
);

logic clear_counter, count_enable;
logic [3:0] rollover_val;
logic rollover_flag;

state_clk_div state, next_state;


flex_counter #(.SIZE(4)) countering(.clk(clk), .n_rst(n_rst), .clear(clear_counter), .count_enable(count_enable),
                                    .rollover_val(rollover_val), .count_out(), .rollover_flag(rollover_flag));


always_ff @(posedge clk, negedge n_rst) begin
    if (~n_rst) begin
        state <= COUNT_8_1;
    end else begin
        state <= next_state;
    end
end

always_ff @(posedge clk, negedge n_rst) begin
    if (~n_rst) begin
        clk_divided <= 1'b0;
    end else if (enable) begin
        if (rollover_flag) begin
            clk_divided <= ~clk_divided;
        end
    end
end

always_comb begin
    next_state = state;
    case(state)
        COUNT_8_1: begin
            if (rollover_flag) begin
                next_state = COUNT_8_2;
            end
        end
        COUNT_8_2: begin
            if (rollover_flag) begin
                next_state = COUNT_9;
            end
        end
        COUNT_9: begin
            if (rollover_flag) begin
                next_state = COUNT_8_1;
            end
        end
        default: next_state = state;
    endcase
end

assign count_enable = enable;
assign clear_counter = ~enable;

always_comb begin
    case(state)
        COUNT_8_1,
        COUNT_8_2: rollover_val = 4'd8;
        COUNT_9:   rollover_val = 4'd9;
        default:   rollover_val = 4'd8;
    endcase
end

assign strobe = rollover_flag;



// //4-4-5

// always_ff @(posedge clk, negedge n_rst) begin
//     if (~n_rst) begin
//         state_two <= COUNT_4_1;
//     end else begin
//         state_two <= next_state_two;
//     end
// end

// always_ff @(posedge clk, negedge n_rst) begin
//     if (~n_rst) begin
//         clk_divided_two <= 1'b0;
//     end else if (enable) begin
//         if (rollover_flag) begin
//             clk_divided_two <= ~clk_divided_two;
//         end
//     end
// end

// always_comb begin
//     next_state_two = state_two;
//     case(state_two)
//         COUNT_4_1: begin
//             if (rollover_flag_two) begin
//                 next_state_two = COUNT_4_2;
//             end
//         end
//         COUNT_4_2: begin
//             if (rollover_flag_two) begin
//                 next_state_two = COUNT_5;
//             end
//         end
//         COUNT_5: begin
//             if (rollover_flag_two) begin
//                 next_state_two = COUNT_4_1;
//             end
//         end
//         default: next_state_two = state_two;
//     endcase
// end

// assign count_enable_two = enable;
// assign clear_counter_two = ~enable;

// always_comb begin
//     case(state_two)
//         COUNT_4_1: rollover_val_two = 4'd7;
//         COUNT_4_2: rollover_val_two = 4'd7;
//         COUNT_5:   rollover_val_two = 4'd7;
//         default:   rollover_val_two = 4'd7;
//     endcase

//     assign middle_strobe = rollover_flag_two;
// end

endmodule


