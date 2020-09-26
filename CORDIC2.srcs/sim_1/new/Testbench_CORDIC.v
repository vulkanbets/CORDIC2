`timescale 1ns / 1ps
module Testbench_CORDIC;
// Parameters
parameter WI1 = 10, WF1 = 22,               // input 1 integer and fraction bits
          WI2 = 10, WF2 = 22,               // input 2 integer and fraction bits
          WIO = WI1 > WI2 ? WI1 : WI2,      // output integer bits
          WFO = WF1 > WF2 ? WF1 : WF2;      // output fraction bits
// Inputs 
reg [31 : 0] angle = 32'h43800000;                  // input degrees
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

wire [31 : 0] value_x = DUT.y_Register.value;                               // current value of the y register
wire signed [WI1 + WF1 - 1 : 0] y_Adder_In1 = DUT.y_Adder_In1;              // y Add # 1
wire signed [WI2 + WF2 - 1 : 0] y_Adder_In2 = DUT.y_Adder_In2;              // y Add # 2
wire signed [WI2 + WF2 - 1 : 0] y_Adder_In2_Comp = DUT.y_Adder_In2_Comp;    // y Add # 2 two's compliment
wire signed [WIO + WFO - 1 : 0] y_Adder_Out = DUT.y_Adder_Out;              // y Adder Output
    
wire [31 : 0] value_y = DUT.x_Register.value;                               // current value of the x register
wire signed [WI1 + WF1 - 1 : 0] x_Adder_In1 = DUT.x_Adder_In1;              // x Add # 1
wire signed [WI2 + WF2 - 1 : 0] x_Adder_In2 = DUT.x_Adder_In2;              // x Add # 2
wire signed [WI2 + WF2 - 1 : 0] x_Adder_In2_Comp = DUT.x_Adder_In2_Comp;    // x Add # 2 two's compliment
wire signed [WIO + WFO - 1 : 0] x_Adder_Out = DUT.x_Adder_Out;              // x Adder Output
// Initialize clock
always #50 CLK <= ~CLK;
// <------------------Increment counter from 0-9 modulus 9-------------------->
always @ (posedge CLK)
begin
    if( DUT.counter == 9 ) RESET <= 1; else RESET <= 0;
    if( DUT.counter == 9 ) DUT.counter <= 0;
        else DUT.counter <= DUT.counter + 1;
end
    initial
    begin
        @(posedge CLK);                                         // Clock
        @(posedge CLK);                                         // Clock
        @(posedge CLK);                                         // Clock
        @(posedge CLK);                                         // Clock
        @(posedge CLK);                                         // Clock
        @(posedge CLK);                                         // Clock
        @(posedge CLK);                                         // Clock
        @(posedge CLK);                                         // Clock
        @(posedge CLK);                                         // Clock
        @(posedge CLK);                                         // Clock
    end
top DUT( .angle(angle), .CLK(CLK), .RESET(RESET) );             // Instantiate DUT
endmodule

