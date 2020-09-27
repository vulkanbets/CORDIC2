`timescale 1ns / 1ps
module Testbench_CORDIC;
// Parameters
parameter WI1 = 10, WF1 = 22,               // input 1 integer and fraction bits
          WI2 = 10, WF2 = 22,               // input 2 integer and fraction bits
          WIO = WI1 > WI2 ? WI1 : WI2,      // output integer bits
          WFO = WF1 > WF2 ? WF1 : WF2;      // output fraction bits
// Inputs 
reg [31 : 0] angle = 32'h00000000;                  // input degrees
reg RESET = 0;
reg CLK = 0;
// Outputs 
wire [1 : 0] quadrant = DUT.quadrant;                                                   // 0=1; 1=2; 2=3; 3=4
wire signed [31 : 0] reference_Angle = DUT.reference_Angle;                             // Reference angle
wire signed [31 : 0] out_bounds_reference_Angle = DUT.out_bounds_reference_Angle;       // reference - 180 angle
wire rotated_angle = DUT.rotated_angle;                                                 // 0 = not rotated; 1 = rotated
wire signed [31 : 0] final_Angle = DUT.final_Angle;                                     // final angle
wire [31 : 0] LUT [0 : 9] = DUT.LUT;                                                    // Lookup table for tan inverse values
wire [31 : 0] value = DUT.z_Register.value;                                             // current value of the z register
wire signed [WI1 + WF1 - 1 : 0] z_Adder_In1 = DUT.z_Adder_In1;                          // z Add # 1
wire signed [WI2 + WF2 - 1 : 0] z_Adder_In2 = DUT.z_Adder_In2;                          // z Add # 2
wire signed [WI2 + WF2 - 1 : 0] z_Adder_In2_Comp = DUT.z_Adder_In2_Comp;                // z Add # 2 two's compliment
wire signed [WIO + WFO - 1 : 0] z_Adder_Out = DUT.z_Adder_Out;                          // z Adder Output
wire d = DUT.d;                                                                         // d;  1 = add;  0 = subtract;
wire [31 : 0] precise_sine = DUT.precise_sine;                  // To compute the precise sine
wire [31 : 0] precise_cosine = DUT.precise_cosine;              // To compute the precise cosine
wire [31 : 0] precise_sine_neg = DUT.precise_sine_neg;          // To compute the precise sine
wire [31 : 0] precise_cosine_neg = DUT.precise_cosine_neg;      // To compute the precise cosine
wire [9  : 0] out_sine = DUT.out_sine;                          // Final Output for sine
wire [9  : 0] out_cosine = DUT.out_cosine;                      // Final Output for cosine

wire [31 : 0] value_y = DUT.y_Register.value;                               // current value of the y register
wire signed [WI1 + WF1 - 1 : 0] y_Adder_In1 = DUT.y_Adder_In1;              // y Add # 1
wire signed [WI2 + WF2 - 1 : 0] y_Adder_In2 = DUT.y_Adder_In2;              // y Add # 2
wire signed [WI2 + WF2 - 1 : 0] y_Adder_In2_Comp = DUT.y_Adder_In2_Comp;    // y Add # 2 two's compliment
wire signed [WIO + WFO - 1 : 0] y_Adder_Out = DUT.y_Adder_Out;              // y Adder Output
wire signed [WIO + WFO - 1 : 0] y_Mux_Out = DUT.y_Mux_Out;                // y Adder Output
    
wire [31 : 0] value_x = DUT.x_Register.value;                               // current value of the x register
wire signed [WI1 + WF1 - 1 : 0] x_Adder_In1 = DUT.x_Adder_In1;              // x Add # 1
wire signed [WI2 + WF2 - 1 : 0] x_Adder_In2 = DUT.x_Adder_In2;              // x Add # 2
wire signed [WI2 + WF2 - 1 : 0] x_Adder_In2_Comp = DUT.x_Adder_In2_Comp;    // x Add # 2 two's compliment
wire signed [WIO + WFO - 1 : 0] x_Adder_Out = DUT.x_Adder_Out;              // x Adder Output
wire signed [WI2 + WF2 - 1 : 0] x_Mux_Out = DUT.x_Mux_Out;                  // x Mux Out
// Initialize clock
always #3 CLK <= ~CLK;
// <------------------Increment counter from 0-9 modulus 9-------------------->
always @ (posedge CLK)
begin
    if( DUT.counter == 9 ) RESET <= 1; else RESET <= 0;
    if( DUT.counter == 9 ) DUT.counter <= 0;
        else DUT.counter <= DUT.counter + 1;
end
    initial
    begin
        @(posedge CLK);                                         // Clock 0
        @(posedge CLK);                                         // Clock 1
        @(posedge CLK);                                         // Clock 2
        @(posedge CLK);                                         // Clock 3
        @(posedge CLK);                                         // Clock 4
        @(posedge CLK);                                         // Clock 5
        @(posedge CLK);                                         // Clock 6
        @(posedge CLK);                                         // Clock 7
        @(posedge CLK);                                         // Clock 8
        @(posedge CLK);                                         // Clock 9
        angle <= 32'h00400000;                                  // new value 1
        @(posedge CLK);                                         // Clock 0
        @(posedge CLK);                                         // Clock 1
        @(posedge CLK);                                         // Clock 2
        @(posedge CLK);                                         // Clock 3
        @(posedge CLK);                                         // Clock 4
        @(posedge CLK);                                         // Clock 5
        @(posedge CLK);                                         // Clock 6
        @(posedge CLK);                                         // Clock 7
        @(posedge CLK);                                         // Clock 8
        @(posedge CLK);                                         // Clock 9
        angle <= 32'h16400000;                                  // new value 89
        @(posedge CLK);                                         // Clock 0
        @(posedge CLK);                                         // Clock 1
        @(posedge CLK);                                         // Clock 2
        @(posedge CLK);                                         // Clock 3
        @(posedge CLK);                                         // Clock 4
        @(posedge CLK);                                         // Clock 5
        @(posedge CLK);                                         // Clock 6
        @(posedge CLK);                                         // Clock 7
        @(posedge CLK);                                         // Clock 8
        @(posedge CLK);                                         // Clock 9
        angle <= 32'h16800000;                                  // new value 90
        @(posedge CLK);                                         // Clock 0
        @(posedge CLK);                                         // Clock 1
        @(posedge CLK);                                         // Clock 2
        @(posedge CLK);                                         // Clock 3
        @(posedge CLK);                                         // Clock 4
        @(posedge CLK);                                         // Clock 5
        @(posedge CLK);                                         // Clock 6
        @(posedge CLK);                                         // Clock 7
        @(posedge CLK);                                         // Clock 8
        @(posedge CLK);                                         // Clock 9
        angle <= 32'h16c00000;                                  // new value 91
        @(posedge CLK);                                         // Clock 0
        @(posedge CLK);                                         // Clock 1
        @(posedge CLK);                                         // Clock 2
        @(posedge CLK);                                         // Clock 3
        @(posedge CLK);                                         // Clock 4
        @(posedge CLK);                                         // Clock 5
        @(posedge CLK);                                         // Clock 6
        @(posedge CLK);                                         // Clock 7
        @(posedge CLK);                                         // Clock 8
        @(posedge CLK);                                         // Clock 9
        angle <= 32'h2cc00000;                                  // new value 179
        @(posedge CLK);                                         // Clock 0
        @(posedge CLK);                                         // Clock 1
        @(posedge CLK);                                         // Clock 2
        @(posedge CLK);                                         // Clock 3
        @(posedge CLK);                                         // Clock 4
        @(posedge CLK);                                         // Clock 5
        @(posedge CLK);                                         // Clock 6
        @(posedge CLK);                                         // Clock 7
        @(posedge CLK);                                         // Clock 8
        @(posedge CLK);                                         // Clock 9
        angle <= 32'h2d000000;                                  // new value 180
        @(posedge CLK);                                         // Clock 0
        @(posedge CLK);                                         // Clock 1
        @(posedge CLK);                                         // Clock 2
        @(posedge CLK);                                         // Clock 3
        @(posedge CLK);                                         // Clock 4
        @(posedge CLK);                                         // Clock 5
        @(posedge CLK);                                         // Clock 6
        @(posedge CLK);                                         // Clock 7
        @(posedge CLK);                                         // Clock 8
        @(posedge CLK);                                         // Clock 9
        angle <= 32'h2d400000;                                  // new value 181
        @(posedge CLK);                                         // Clock 0
        @(posedge CLK);                                         // Clock 1
        @(posedge CLK);                                         // Clock 2
        @(posedge CLK);                                         // Clock 3
        @(posedge CLK);                                         // Clock 4
        @(posedge CLK);                                         // Clock 5
        @(posedge CLK);                                         // Clock 6
        @(posedge CLK);                                         // Clock 7
        @(posedge CLK);                                         // Clock 8
        @(posedge CLK);                                         // Clock 9
        angle <= 32'h43400000;                                  // new value 269
        @(posedge CLK);                                         // Clock 0
        @(posedge CLK);                                         // Clock 1
        @(posedge CLK);                                         // Clock 2
        @(posedge CLK);                                         // Clock 3
        @(posedge CLK);                                         // Clock 4
        @(posedge CLK);                                         // Clock 5
        @(posedge CLK);                                         // Clock 6
        @(posedge CLK);                                         // Clock 7
        @(posedge CLK);                                         // Clock 8
        @(posedge CLK);                                         // Clock 9
        angle <= 32'h43800000;                                  // new value 270
        @(posedge CLK);                                         // Clock 0
        @(posedge CLK);                                         // Clock 1
        @(posedge CLK);                                         // Clock 2
        @(posedge CLK);                                         // Clock 3
        @(posedge CLK);                                         // Clock 4
        @(posedge CLK);                                         // Clock 5
        @(posedge CLK);                                         // Clock 6
        @(posedge CLK);                                         // Clock 7
        @(posedge CLK);                                         // Clock 8
        @(posedge CLK);                                         // Clock 9
        angle <= 32'h43c00000;                                  // new value 271
        @(posedge CLK);                                         // Clock 0
        @(posedge CLK);                                         // Clock 1
        @(posedge CLK);                                         // Clock 2
        @(posedge CLK);                                         // Clock 3
        @(posedge CLK);                                         // Clock 4
        @(posedge CLK);                                         // Clock 5
        @(posedge CLK);                                         // Clock 6
        @(posedge CLK);                                         // Clock 7
        @(posedge CLK);                                         // Clock 8
        @(posedge CLK);                                         // Clock 9
        angle <= 32'h59c00000;                                  // new value 359
        @(posedge CLK);                                         // Clock 0
        @(posedge CLK);                                         // Clock 1
        @(posedge CLK);                                         // Clock 2
        @(posedge CLK);                                         // Clock 3
        @(posedge CLK);                                         // Clock 4
        @(posedge CLK);                                         // Clock 5
        @(posedge CLK);                                         // Clock 6
        @(posedge CLK);                                         // Clock 7
        @(posedge CLK);                                         // Clock 8
        @(posedge CLK);                                         // Clock 9
        angle <= 32'h5a000000;                                  // new value 360
        
    end
top DUT( .angle(angle), .CLK(CLK), .RESET(RESET) );             // Instantiate DUT
endmodule

