`timescale 1ns / 1ps

module mux
(
    input sel,
    input [31 : 0] A, B,
    output reg [31 : 0] out
);
    always @ (*)
    if (!sel) out <= A;
    else out <= B;
    
endmodule
