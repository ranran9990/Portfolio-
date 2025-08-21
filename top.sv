`default_nettype none
// Empty top module

typedef enum logic [3:0] {
  ALT1 = 4'b1000, VEL1 = 4'b0100, FUEL1 = 4'b0010, THRUST1 = 4'b0001 
} state_t;


module top (
  // I/O ports
  input  logic hz100, reset,
  input  logic [20:0] pb,
  output logic [7:0] left, right,
         ss7, ss6, ss5, ss4, ss3, ss2, ss1, ss0,
  output logic red, green, blue,

  // UART ports
  output logic [7:0] txdata,
  input  logic [7:0] rxdata,
  output logic txclk, rxclk,
  input  logic txready, rxready
);

lunarlander lander(.hz100(hz100), .reset(reset), .in(pb[19:0]), .ss7(ss7), .ss6(ss6), .ss5(ss5), .ss3(ss3), .ss2(ss2), .ss1(ss1), .ss0(ss0), .red(red), .green(green));



endmodule 


module lunarlander #(
  parameter FUEL=16'h800,
  parameter ALTITUDE=16'h4500,
  parameter VELOCITY=16'h0,
  parameter THRUST=16'h5,
  parameter GRAVITY=16'h5
)(
  input logic hz100, reset,
  input logic [19:0] in,
  output logic [7:0] ss7, ss6, ss5, 
  output logic [7:0] ss3, ss2, ss1, ss0,
  output logic red, green
);

logic [4:0] keyout;
logic [3:0] keyout_n;
logic keyclk, clk, land, crash, wen;
logic [15:0] alt, vel, fuel, thrust, alt_n, vel_n, fuel_n, thrust_n;

keysync key(.clk(hz100), .rst(reset), .keyin(in[19:0]), .keyout(keyout), .keyclk(keyclk));

always_ff@(posedge keyclk, posedge reset) begin
  if (reset) begin
    thrust_n <= THRUST;
  end else if(~keyout[4]) begin
    thrust_n <= {12'b0, keyout[3:0]};
  end 
end

assign keyout_n = {keyout == 5'd19, keyout == 5'd18, keyout == 5'd17, keyout == 5'd16};

clock_psc clock(.clk(hz100), .rst(reset), .lim(8'd24), .hzX(clk));

ll_alu alu(.alt(alt), .vel(vel), .fuel(fuel), .thrust(thrust), .alt_n(alt_n), .vel_n(vel_n), .fuel_n(fuel_n));

ll_memory memory(.clk(clk), .rst(reset), .wen(wen), .alt_n(alt_n), .vel_n(vel_n), .fuel_n(fuel_n), .thrust_n(thrust_n), .alt(alt), .vel(vel), .fuel(fuel), .thrust(thrust));

ll_control control(.clk(clk), .rst(reset), .alt(alt), .vel(vel), .land(land), .crash(crash), .wen(wen));

ll_display display(.clk(keyclk), .rst(reset), .land(land), .crash(crash), .disp_ctrl(keyout_n), .alt(alt), .vel(vel), .fuel(fuel), .thrust(thrust), 
                   .ss7(ss7), .ss6(ss6), .ss5(ss5), .ss3(ss3), .ss2(ss2), .ss1(ss1), .ss0(ss0), .red(red), .green(green));

endmodule

// fa f1(.a(pb[0]), .b(pb[1]), .ci(pb[2]), .s(right[0]), .co(right[1]));  

// fa4 f41(.a(pb[3:0]), .b(pb[7:4]), .ci(pb[19]), .s(right[3:0]), .co(right[4]));

// logic co;
// logic [3:0] s;
// bcdadd1 ba1(.a(pb[3:0]), .b(pb[7:4]), .ci(pb[19]), .co(co), .s(s));
// ssdec s0(.in(s), .out(ss0[6:0]), .enable(1));
// ssdec s1(.in({3'b0,co}), .out(ss1[6:0]), .enable(1));
// ssdec s5(.in(pb[7:4]), .out(ss5[6:0]), .enable(1));
// ssdec s7(.in(pb[3:0]), .out(ss7[6:0]), .enable(1));

// logic co;
// logic [15:0] s;
// bcdadd4 ba1(.a(16'h1234), .b(16'h1111), .ci(0), .co(red), .s(s));
// ssdec s0(.in(s[3:0]),   .out(ss0[6:0]), .enable(1));
// ssdec s1(.in(s[7:4]),   .out(ss1[6:0]), .enable(1));
// ssdec s2(.in(s[11:8]),  .out(ss2[6:0]), .enable(1));
// ssdec s3(.in(s[15:12]), .out(ss3[6:0]), .enable(1));

// logic [3:0] out;
// bcd9comp1 cmp1(.in(pb[3:0]), .out(out));
// ssdec s0(.in(pb[3:0]), .out(ss0[6:0]), .enable(1));
// ssdec s1(.in(out), .out(ss1[6:0]), .enable(1));

// logic [15:0] s;
// bcdaddsub4 bas4(.a(16'h0000), .b(16'h0001), .op(1), .s(s));
// ssdec s0(.in(s[3:0]),   .out(ss0[6:0]), .enable(1));
// ssdec s1(.in(s[7:4]),   .out(ss1[6:0]), .enable(1));
// ssdec s2(.in(s[11:8]),  .out(ss2[6:0]), .enable(1));
// ssdec s3(.in(s[15:12]), .out(ss3[6:0]), .enable(1));

module keysync (
    input logic clk,             
    input logic rst,             
    input logic [19:0] keyin,    
    output logic [4:0] keyout,  
    output logic keyclk          
);
    always_comb begin
        keyout[0] = keyin[1] | keyin[3] | keyin[5] | keyin[7] | keyin[9] |
                    keyin[11] | keyin[13] | keyin[15] | keyin[17] | keyin[19];
        keyout[1] = keyin[2] | keyin[3] | keyin[6] | keyin[7] | keyin[10] |
                    keyin[11] | keyin[14] | keyin[15] | keyin[18] | keyin[19];
        keyout[2] = keyin[4] | keyin[5] | keyin[6] | keyin[7] | keyin[12] |
                    keyin[13] | keyin[14] | keyin[15];
        keyout[3] = keyin[8] | keyin[9] | keyin[10] | keyin[11] | keyin[12] |
                    keyin[13] | keyin[14] | keyin[15];
        keyout[4] = keyin[16] | keyin[17] | keyin[18] | keyin[19];
    end

    logic delay;

    always_ff @(posedge clk) begin
      delay <= ~delay;
    end

    always_ff @(negedge delay, posedge rst)begin
      if(rst)begin 
        keyclk <= 0;
      end else begin
        keyclk <= |keyin;
      end
    end

endmodule

module clock_psc (
    input logic clk,          
    input logic rst,          
    input logic [7:0] lim,    
    output logic hzX          
);

    logic [7:0] counter, counter_n; 
    logic hzX_n;                   

    always_comb begin
        counter_n = counter;       
        hzX_n = hzX;               
        if (lim == 8'b0) begin
            hzX_n = ~clk;          
        end else if (counter == lim) begin
            counter_n = 8'b0;      
            hzX_n = ~hzX;          
        end else begin
            counter_n = counter + 1; 
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 8'b0;       
            hzX <= 1'b0;            
        end else begin
            counter <= counter_n;   
            hzX <= hzX_n;           
        end
    end
endmodule

module ll_display (
  input logic clk,
  input logic rst,
  input logic land,
  input logic crash,
  input logic [3:0] disp_ctrl,
  input logic [15:0] alt,
  input logic [15:0] vel,
  input logic [15:0] fuel,
  input logic [15:0] thrust,
  output logic [7:0] ss7, ss6, ss5,
  output logic [7:0] ss3, ss2, ss1, ss0,
  output logic red,
  output logic green
); 

logic [6:0] output1, output2, output3, output4;
logic [15:0] next_input;
logic [15:0] math_output, negative_vel;
logic enable1, enable2, enable3, enable4, red_n, green_n, negative;
state_t state, state_n;

ssdec s1(.in(next_input[3:0]),   .out(output1), .enable(enable1));
ssdec s2(.in(next_input[7:4]),   .out(output2), .enable(enable2));
ssdec s3(.in(next_input[11:8]),   .out(output3), .enable(enable3));
ssdec s4(.in(next_input[15:12]),   .out(output4), .enable(enable4));

always_comb begin
  enable1 = 1;
  enable2 = 1;
  enable3 = 1;
  enable4 = 1;

case(state) 
  ALT1: begin
    {ss7, ss6, ss5} = 24'b01110111_00111000_01111000;
    {ss3, ss2, ss1, ss0} = {{1'b0, output4}, {1'b0, output3}, {1'b0, output2}, {1'b0, output1}};
    next_input = alt;
  if (alt < 16'h1000 || alt > 16'h9000) begin
    enable4 = 0;
  end if (alt < 16'h100 || alt > 16'h9900) begin
    enable3 = 0;
  end if (alt < 16'h10 || alt > 16'h9990) begin
    enable2 = 0;
  end
  end
  VEL1: begin
    {ss7, ss6, ss5} = 24'b00111110_01111001_00111000;
    if (vel[15]) begin
      {ss3, ss2, ss1, ss0} = {{1'b0, 7'b1000000}, {1'b0, output3}, {1'b0, output2}, {1'b0, output1}};
      next_input = math_output;
    end else begin
      {ss3, ss2, ss1, ss0} = {{1'b0, output4}, {1'b0, output3}, {1'b0, output2}, {1'b0, output1}};
      next_input = vel;
    end
  if (vel < 16'h1000 || vel > 16'h9000) begin
    enable4 = 0;
  end if (vel < 16'h100 || vel > 16'h9900) begin
    enable3 = 0;
  end if (vel < 16'h10 || vel > 16'h9990) begin
    enable2 = 0;
  end
  end 
  FUEL1: begin
    {ss7, ss6, ss5} = 24'b01101111_01110111_01101101;
    {ss3, ss2, ss1, ss0} = {{1'b0, output4}, {1'b0, output3}, {1'b0, output2}, {1'b0, output1}};
    next_input = fuel;
  if (fuel < 16'h1000 || fuel > 16'h9000) begin
    enable4 = 0;
  end if (fuel < 16'h100 || fuel > 16'h9900) begin
    enable3 = 0;
  end if (fuel < 16'h10 || fuel > 16'h9990) begin
    enable2 = 0;
  end
  end 
  THRUST1: begin
    {ss7, ss6, ss5} = 24'b01111000_01110110_01010000;
    {ss3, ss2, ss1, ss0} = {{1'b0, output4}, {1'b0, output3}, {1'b0, output2}, {1'b0, output1}};
    next_input = thrust;
  if (thrust < 16'h1000 || thrust > 16'h9000) begin
    enable4 = 0;
  end if (thrust < 16'h100 || thrust > 16'h9900) begin
    enable3 = 0;
  end if (thrust < 16'h10 || thrust > 16'h9990) begin
    enable2 = 0;
  end
  end
  default: begin
    {ss7, ss6, ss5} = 24'b01110111_00111000_01111000;
    {ss3, ss2, ss1, ss0} = {{1'b0, output4}, {1'b0, output3}, {1'b0, output2}, {1'b0, output1}};
    next_input = alt;
  end   
endcase
end


bcdaddsub4 bas4(.a(16'h0000), .b(vel), .op(1), .s(math_output));

always_ff@(posedge clk, posedge rst) begin
  if (rst) begin
    state <= ALT1;
  end else begin
    state <= state_n;
  end
end

always_comb begin
  green = land;
  red = crash;
  case({state, disp_ctrl})
    {ALT1, {1'b1, 1'b0, 1'b0, 1'b0}}: state_n = ALT1;
    {ALT1, {1'b0, 1'b1, 1'b0, 1'b0}}: state_n = VEL1;
    {ALT1, {1'b0, 1'b0, 1'b1, 1'b0}}: state_n = FUEL1;
    {ALT1, {1'b0, 1'b0, 1'b0, 1'b1}}: state_n = THRUST1;
    {VEL1, {1'b1, 1'b0, 1'b0, 1'b0}}: state_n = ALT1;
    {VEL1, {1'b0, 1'b1, 1'b0, 1'b0}}: state_n = VEL1;
    {VEL1, {1'b0, 1'b0, 1'b1, 1'b0}}: state_n = FUEL1;
    {VEL1, {1'b0, 1'b0, 1'b0, 1'b1}}: state_n = THRUST1;
    {FUEL1, {1'b1, 1'b0, 1'b0, 1'b0}}: state_n = ALT1;
    {FUEL1, {1'b0, 1'b1, 1'b0, 1'b0}}: state_n = VEL1;
    {FUEL1, {1'b0, 1'b0, 1'b1, 1'b0}}: state_n = FUEL1;
    {FUEL1, {1'b0, 1'b0, 1'b0, 1'b1}}: state_n = THRUST1;
    {THRUST1, {1'b1, 1'b0, 1'b0, 1'b0}}: state_n = ALT1;
    {THRUST1, {1'b0, 1'b1, 1'b0, 1'b0}}: state_n = VEL1;
    {THRUST1, {1'b0, 1'b0, 1'b1, 1'b0}}: state_n = FUEL1;
    {THRUST1, {1'b0, 1'b0, 1'b0, 1'b1}}: state_n = THRUST1;
    default: state_n = state;
  endcase
end
endmodule

module ll_control (
  input logic clk,
  input logic rst,
  input logic [15:0] alt,
  input logic [15:0] vel,
  output logic land,
  output logic crash,
  output logic wen
);

logic [15:0] landed;
logic land_n, crash_n, wen_n;
bcdaddsub4 bas1(.a(alt), .b(vel), .op(0), .s(landed));

always_ff@(posedge clk, posedge rst) begin
  if (rst) begin
    land <= 0;
    crash <= 0;
    wen <= 0;
  end else begin
    land <= land_n;
    crash <= crash_n;
    wen <= wen_n;
  end
end

always_comb begin
  if(~(land | crash)) begin
    if (landed[15] | landed == 0) begin
      wen_n = 0;
      if (vel < 16'h9970) begin
        land_n = 0;
        crash_n = 1;
      end else begin 
        land_n = 1;
        crash_n = 0;
      end
    end else begin
      wen_n = 1;
      crash_n = 0;
      land_n = 0;
    end
  end else begin
    land_n = land;
    crash_n = crash;
    wen_n = wen;
  end
end

endmodule

module ll_alu #(
  parameter GRAVITY = 16'h5
)(
  input logic [15:0] alt,
  input logic [15:0] vel,
  input logic [15:0] fuel,
  input logic [15:0] thrust,
  output logic [15:0] alt_n,
  output logic [15:0] vel_n,
  output logic [15:0] fuel_n
);

logic [15:0] alt_c, vel_c1, vel_c2, fuel_c, thrust_c;

always_comb begin
  thrust_c = thrust;

  if (fuel == 16'b0) begin
    thrust_c = 0;
  end
end

bcdaddsub4 bas1(.a(alt), .b(vel), .op(0), .s(alt_c));
bcdaddsub4 bas2(.a(vel), .b(GRAVITY), .op(1), .s(vel_c1));
bcdaddsub4 bas3(.a(vel_c1), .b(thrust_c), .op(0), .s(vel_c2));
bcdaddsub4 bas4(.a(fuel), .b(thrust), .op(1), .s(fuel_c));

always_comb begin
  if ((alt_c[15] == 1 )| alt == 0) begin
    alt_n = 0;
    vel_n = 0;
  end else begin
    alt_n = alt_c;
    vel_n = vel_c2;
  end
  if ((fuel_c[15] == 1 )| fuel_c == 0) begin
    fuel_n = 0;
  end else begin
    fuel_n = fuel_c;
  end
end

endmodule

module ll_memory #(
  parameter ALTITUDE = 16'h4500,
  parameter VELOCITY = 16'h0,
  parameter FUEL = 16'h800,
  parameter THRUST = 16'h5
)(
  input logic clk,
  input logic rst,
  input logic wen,
  input logic [15:0] alt_n,
  input logic [15:0] vel_n,
  input logic [15:0] fuel_n,
  input logic [15:0] thrust_n,
  output logic [15:0] alt,
  output logic [15:0] vel,
  output logic [15:0] fuel,
  output logic [15:0] thrust
);

always_ff@(posedge clk, posedge rst) begin
  if (rst) begin
    alt <= ALTITUDE;
    vel <= VELOCITY;
    fuel <= FUEL;
    thrust <= THRUST;
  end else if (wen) begin
    alt <= alt_n;
    vel <= vel_n;
    fuel <= fuel_n;
    thrust <= thrust_n;
  end 
end
endmodule

module bcdaddsub4 (
  input logic [15:0] a,
  input logic [15:0] b,
  input logic op,
  output logic [15:0] s
);

logic [15:0] select;

bcd9comp1 cmp1(.in(b[3:0]), .out(select[3:0]));
bcd9comp1 cmp2(.in(b[7:4]), .out(select[7:4]));
bcd9comp1 cmp3(.in(b[11:8]), .out(select[11:8]));
bcd9comp1 cmp4(.in(b[15:12]), .out(select[15:12]));

bcdadd4 ba1(.a(a), .b(op?{select[15:12], select[11:8], select[7:4], select[3:0]}:{b[15:12], b[11:8], b[7:4], b[3:0]}), .ci(op), .co(), .s(s));

endmodule

module bcd9comp1 (
  input logic [3:0] in,
  output logic [3:0] out
);

always_comb
case (in)
  4'b0000: out = 4'b1001;
  4'b0001: out = 4'b1000;
  4'b0010: out = 4'b0111;
  4'b0011: out = 4'b0110;
  4'b0100: out = 4'b0101;
  4'b0101: out = 4'b0100;
  4'b0110: out = 4'b0011;
  4'b0111: out = 4'b0010;
  4'b1000: out = 4'b0001;
  4'b1001: out = 4'b0000;
  default: out = 4'b0000;
endcase 

endmodule

module bcdadd4 (
  input logic [15:0] a,
  input logic [15:0] b,
  input logic ci,
  output logic co,
  output logic [15:0] s
);

logic co1, co2, co3;

bcdadd1 ba1(.a(a[3:0]), .b(b[3:0]), .ci(ci), .co(co1), .s(s[3:0]));
bcdadd1 ba2(.a(a[7:4]), .b(b[7:4]), .ci(co1), .co(co2), .s(s[7:4]));
bcdadd1 ba3(.a(a[11:8]), .b(b[11:8]), .ci(co2), .co(co3), .s(s[11:8]));
bcdadd1 ba4(.a(a[15:12]), .b(b[15:12]), .ci(co3), .co(co), .s(s[15:12]));

endmodule

module bcdadd1 (
  input logic [3:0] a,
  input logic [3:0] b,
  input logic ci,
  output logic co,
  output logic [3:0] s
);

logic [3:0] sy;
logic co1, x0, x1, x2, x3;

fa4 f1(.a(a[3:0]), .b(b[3:0]), .ci(ci), .s(sy[3:0]), .co(co1));

assign x0 = 0;
assign x1 = (sy[3] & sy[2]) | (sy[3] & sy[1] | co1);
assign x2 = (sy[3] & sy[2]) | (sy[3] & sy[1] | co1);
assign x3 = 0;
assign co = (sy[3] & sy[2]) | (sy[3] & sy[1] | co1);

fa4 f2(.a({x3, x2, x1, x0}), .b(sy[3:0]), .ci(0), .s(s[3:0]), .co());

endmodule

module ssdec (
  input logic [3:0] in,
  input logic enable,
  output logic [6:0] out
);

assign {out} =  (in[3:0] == 4'b1111) && enable == 1 ? 7'b1110001:
                (in[3:0] == 4'b1110) && enable == 1 ? 7'b1111001:
                (in[3:0] == 4'b1101) && enable == 1 ? 7'b1011110:
                (in[3:0] == 4'b1100) && enable == 1 ? 7'b0111001:
                (in[3:0] == 4'b1011) && enable == 1 ? 7'b1111100:
                (in[3:0] == 4'b1010) && enable == 1 ? 7'b1110111:
                (in[3:0] == 4'b1001) && enable == 1 ? 7'b1100111:
                (in[3:0] == 4'b1000) && enable == 1 ? 7'b1111111:
                (in[3:0] == 4'b0111) && enable == 1 ? 7'b0000111:
                (in[3:0] == 4'b0110) && enable == 1 ? 7'b1111101:
                (in[3:0] == 4'b0101) && enable == 1 ? 7'b1101101:
                (in[3:0] == 4'b0100) && enable == 1 ? 7'b1100110:
                (in[3:0] == 4'b0011) && enable == 1 ? 7'b1001111:
                (in[3:0] == 4'b0010) && enable == 1 ? 7'b1011011:
                (in[3:0] == 4'b0001) && enable == 1 ? 7'b0000110:
                (in[3:0] == 4'b0000) && enable == 1 ? 7'b0111111:
                7'b0000000;
endmodule

module fa (
  input logic a,
  input logic b,
  input logic ci,
  output logic s,
  output logic co
);

assign s = a ^ b ^ ci;
assign co = (a & b) | (a & ci) | (b & ci);

endmodule

module fa4 (
  input logic [3:0] a,
  input logic [3:0] b,
  input logic ci,
  output logic [3:0] s,
  output logic co
);

logic co1, co2, co3;

fa f1(.a(a[0]), .b(b[0]), .ci(ci), .s(s[0]), .co(co1));  
fa f2(.a(a[1]), .b(b[1]), .ci(co1), .s(s[1]), .co(co2));  
fa f3(.a(a[2]), .b(b[2]), .ci(co2), .s(s[2]), .co(co3));  
fa f4(.a(a[3]), .b(b[3]), .ci(co3), .s(s[3]), .co(co));  

endmodule

