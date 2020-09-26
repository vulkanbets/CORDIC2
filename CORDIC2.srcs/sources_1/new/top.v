`timescale 1ns / 1ps
      //<---------------- This will all be done in Q10.22 format------------------->
      //<---------------- This will all be done in Q10.22 format------------------->
module top # ( parameter    WI1 = 10, WF1 = 22,                     // input 1 integer and fraction bits
                            WI2 = 10, WF2 = 22,                     // input 2 integer and fraction bits
                            WIO = WI1 > WI2 ? WI1 : WI2,            // output integer bits
                            WFO = WF1 > WF2 ? WF1 : WF2 )           // output fraction bits
(
    input [31 : 0] angle,               // 32-bit input
    input CLK,
    input RESET,
    output sine,                        // 10-bit output;   Q3.7 format
    output cosine                       // 10-bit output    Q3.7 format
);
       //<--------------------- This will all be done in Q10.22 format------------------>
       //<--------------------- This will all be done in Q10.22 format------------------>
    localparam signed [31 : 0] initial_x = 32'h0026dd3b;               // Initial value for x; x = 0.6073
    localparam signed [31 : 0] initial_y = 32'h00000000;               // Initial value for y; y = 0.0000
    localparam signed [31 : 0] initial_z = 32'h00000000;               // Initial value for z; z = 0.0000
    
    reg [31 : 0] LUT [0 : 9];                                   // Lookup table for tan inverse values
    initial $readmemh("my_LUT_Memory.mem", LUT);                // Initialize LUT @ time = 0
    reg [3 : 0] counter = 0;                                    // i = 0
    reg d = 0;                                                  // d;  1 = add;  0 = subtract;
    wire d_y = ~d;                                              // d value but for y;  1 = subtract; 0 = add
    
    wire signed [31 : 0] reference_Angle = angle;                   // reference angle
    
    wire signed [WI1 + WF1 - 1 : 0] z_Adder_In1;                            // z Add # 1
    wire signed [WI2 + WF2 - 1 : 0] z_Adder_In2 = LUT[counter];             // z Add # 2
    wire signed [WI2 + WF2 - 1 : 0] z_Adder_In2_Comp;                       // z Add # 2 two's compliment
    wire signed [WI2 + WF2 - 1 : 0] z_Mux_Out;                              // z Mux Out
    wire signed [WIO + WFO - 1 : 0] z_Adder_Out;                            // z Adder Output
    
    
    wire signed [WI1 + WF1 - 1 : 0] y_Adder_In1;                            // y Add # 1
    wire signed [WI2 + WF2 - 1 : 0] y_Adder_In2 = x_Adder_In1 >>> counter;  // y Add # 2
    wire signed [WI2 + WF2 - 1 : 0] y_Adder_In2_Comp;                       // y Add # 2 two's compliment
    wire signed [WI2 + WF2 - 1 : 0] y_Mux_Out;                              // y Mux Out
    wire signed [WIO + WFO - 1 : 0] y_Adder_Out;                            // y Adder Output
    
    
    wire signed [WI1 + WF1 - 1 : 0] x_Adder_In1;                            // x Add # 1
    wire signed [WI2 + WF2 - 1 : 0] x_Adder_In2 = y_Adder_In1 >>> counter;  // x Add # 2
    wire signed [WI2 + WF2 - 1 : 0] x_Adder_In2_Comp;                       // x Add # 2 two's compliment
    wire signed [WI2 + WF2 - 1 : 0] x_Mux_Out;                              // x Mux Out
    wire signed [WIO + WFO - 1 : 0] x_Adder_Out;                            // x Adder Output
    
    
    always @ (*) if(z_Adder_In1 < reference_Angle) d <= 0; else d <= 1;
    
    
    
        // <--------------------------z Register------------------------------->
    register z_Register( .CLK(CLK), .RESET(RESET), .in(z_Adder_Out), .out(z_Adder_In1) );
     // <-----------------------------two's compliment---------------------------------->
    twos_Compliment twos_Comp_Z( .in(z_Adder_In2), .out(z_Adder_In2_Comp) );
     // <--------------------------z Register Negative Mux------------------------------->
    mux z_Reg_Neg_Mux( .sel(d), .A(z_Adder_In2), .B(z_Adder_In2_Comp), .out(z_Mux_Out) );
        //   <-----------------------------z Adder----------------------------->
    add_Fixed # ( .WI1(WI1), .WF1(WF1), .WI2(WI2), .WF2(WF2), .WIO(WIO), .WFO(WFO) )
                    z_Adder( .RESET(0), .in1(z_Adder_In1), .in2(z_Mux_Out), .out(z_Adder_Out) );
    //<-----------------------------initialize Z Register------------------------------->
    
    
    
    
        // <--------------------------y Register------------------------------->
    register y_Register( .CLK(CLK), .RESET(RESET), .in(y_Adder_Out), .out(y_Adder_In1) );
     // <-----------------------------two's compliment---------------------------------->
    twos_Compliment twos_Comp_Y( .in( y_Adder_In2 ), .out( y_Adder_In2_Comp ) );
     // <--------------------------y Register Negative Mux------------------------------->
    mux y_Reg_Neg_Mux( .sel(d_y), .A(  y_Adder_In2  ), .B(  y_Adder_In2_Comp  ), .out(y_Mux_Out) );
        //   <-----------------------------y Adder----------------------------->
    add_Fixed # ( .WI1(WI1), .WF1(WF1), .WI2(WI2), .WF2(WF2), .WIO(WIO), .WFO(WFO) )
                    y_Adder( .RESET(0), .in1(y_Adder_In1), .in2(y_Mux_Out), .out(y_Adder_Out) );
    
    
        // <--------------------------x Register------------------------------->
    register # (.set_x_val(1)) 
    x_Register( .CLK(CLK), .RESET(RESET), .in(x_Adder_Out), .out(x_Adder_In1) );
     // <-----------------------------two's compliment---------------------------------->
    twos_Compliment twos_Comp_X( .in(x_Adder_In2), .out(x_Adder_In2_Comp) );
     // <--------------------------x Register Negative Mux------------------------------->
    mux x_Reg_Neg_Mux( .sel(d), .A( x_Adder_In2 ), .B( ( x_Adder_In2_Comp ) ), .out(x_Mux_Out) );
        //   <-----------------------------x Adder----------------------------->
    add_Fixed # ( .WI1(WI1), .WF1(WF1), .WI2(WI2), .WF2(WF2), .WIO(WIO), .WFO(WFO) )
                    x_Adder( .RESET(0), .in1(x_Adder_In1), .in2(x_Mux_Out), .out(x_Adder_Out) );
endmodule

