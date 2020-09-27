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
    output [9  : 0] sine,                        // 10-bit output;   Q2.8 format
    output [9  : 0] cosine                       // 10-bit output    Q2.8 format
);
       //<--------------------- This will all be done in Q10.22 format------------------>
       //<--------------------- This will all be done in Q10.22 format------------------>
    localparam signed [31 : 0] initial_x = 32'h0026dd3b;               // Initial value for x; x = 0.6073
    localparam signed [31 : 0] initial_y = 32'h00000000;               // Initial value for y; y = 0.0000
    localparam signed [31 : 0] initial_z = 32'h00000000;               // Initial value for z; z = 0.0000
    
    
    
    reg [1 : 0] quadrant;                           // 0=1; 1=2; 2=3; 3=4
    
    reg [31 : 0] LUT [0 : 9];                       // Lookup table for tan inverse values
    initial $readmemh("my_LUT_Memory.mem", LUT);    // Initialize LUT @ time = 0
    reg [3 : 0] counter = 0;                        // i = 0
    reg d = 0;                                      // d;  1 = add;  0 = subtract;
    wire d_y = ~d;                                  // d value but for y;  1 = subtract; 0 = add
    
    reg rotated_angle;                                                                                   // 0 = not rotated; 1 = rotated
    reg  signed [31 : 0] final_Angle;                                                                    // final angle
    wire signed [31 : 0] reference_Angle = angle;                                                        // reference angle
    wire signed [31 : 0] out_bounds_reference_Angle = 
    reference_Angle >= 32'h43800000 ? reference_Angle - 32'h5a000000 : reference_Angle - 32'h2d000000;   // reference - 180 angle;
    always @ (*) 
        if(  (reference_Angle > 32'h16800000) && (reference_Angle < 32'h43800000)  )
        begin
            final_Angle <= out_bounds_reference_Angle;
            rotated_angle <= 1;
        end
        else if( (reference_Angle >= 32'h43800000) && (reference_Angle < 32'h5a000000) )
        begin
            final_Angle <= out_bounds_reference_Angle;
            rotated_angle <= 1;
        end
        else if(reference_Angle == 32'h5a000000)
        begin
            final_Angle <= 0;
            rotated_angle <= 0;
        end
        else
        begin
            final_Angle <= reference_Angle;
            rotated_angle <= 0;
        end
    
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
    
    always @ (*)
    begin
        if(reference_Angle <= 32'h16800000 || reference_Angle == 32'h5a000000) quadrant <= 0;       // 0-90
        else if(reference_Angle > 32'h16800000 && reference_Angle <= 32'h2d000000) quadrant <= 1;   // 91-180
        else if(reference_Angle > 32'h2d000000 && reference_Angle < 32'h43800000) quadrant <= 2;    // 181-269
        else  quadrant <= 3;                                                                        // 270-259
    end
    
    
    always @ (*) if(z_Adder_In1 < final_Angle) d <= 0; else d <= 1;
    
    
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
    register # (.set_x_val(0)) 
        y_Register( .CLK(CLK), .RESET(RESET), .in(y_Adder_Out), .out(y_Adder_In1) );
     // <-----------------------------two's compliment---------------------------------->
    twos_Compliment twos_Comp_Y( .in( y_Adder_In2 ), .out( y_Adder_In2_Comp ) );
     // <--------------------------y Register Negative Mux------------------------------->
    mux y_Reg_Neg_Mux( .sel(d), .A(  y_Adder_In2  ), .B(  y_Adder_In2_Comp  ), .out(y_Mux_Out) );
        //   <-----------------------------y Adder----------------------------->
    add_Fixed # ( .WI1(WI1), .WF1(WF1), .WI2(WI2), .WF2(WF2), .WIO(WIO), .WFO(WFO) )
                    y_Adder( .RESET(0), .in1(y_Adder_In1), .in2(y_Mux_Out), .out(y_Adder_Out) );
    
    
        // <--------------------------x Register------------------------------->
    register # (.set_x_val(1)) 
    x_Register( .CLK(CLK), .RESET(RESET), .in(x_Adder_Out), .out(x_Adder_In1) );
     // <-----------------------------two's compliment---------------------------------->
    twos_Compliment twos_Comp_X( .in(x_Adder_In2), .out(x_Adder_In2_Comp) );
     // <--------------------------x Register Negative Mux------------------------------->
    mux x_Reg_Neg_Mux( .sel(d_y), .A( x_Adder_In2 ), .B( ( x_Adder_In2_Comp ) ), .out(x_Mux_Out) );
        //   <-----------------------------x Adder----------------------------->
    add_Fixed # ( .WI1(WI1), .WF1(WF1), .WI2(WI2), .WF2(WF2), .WIO(WIO), .WFO(WFO) )
                    x_Adder( .RESET(0), .in1(x_Adder_In1), .in2(x_Mux_Out), .out(x_Adder_Out) );
    
    
    // <--------------------------Negate cosine and sine to get inverse angles------------------------------->
    // <-----------------------------------Output will be in Q2.8 format------------------------------------>
    reg [31 : 0] precise_cosine = 0;                                // To compute the precise cosine
    reg [31 : 0] precise_sine = 0;                                  // To compute the precise sine
    reg [9  : 0] out_cosine;
    reg [9  : 0] out_sine;
    always @ (*)
    begin
        out_cosine = { precise_cosine[31] , precise_cosine[22 : 14] };                  // Output for cosine
        out_sine =   { precise_sine[31] , precise_sine[22 : 14] };                      // Output for sine
    end
    wire [31 : 0] precise_cosine_neg;                                                               // To compute the precise cosine
    wire [31 : 0] precise_sine_neg;                                                                 // To compute the precise sine
    twos_Compliment twos_Comp_precise_cosine( .in( x_Adder_Out ), .out( precise_cosine_neg ) );
    twos_Compliment   twos_Comp_precise_sine( .in( y_Adder_Out ), .out( precise_sine_neg ) );
    always @ (*)
    begin
        if(reference_Angle > 32'h16800000 && reference_Angle < 32'h43800000)
        begin
            if(counter == 9)
            begin
                precise_cosine <= precise_cosine_neg;
                precise_sine   <= precise_sine_neg;
            end
        end
        else
        begin
            if(counter == 9)
            begin
                precise_cosine <= x_Adder_Out;
                precise_sine   <= y_Adder_Out;
            end
        end
    end
    assign cosine = out_cosine;
    assign sine = out_sine;
endmodule


