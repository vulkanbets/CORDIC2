`timescale 1ns / 1ps
module register # ( parameter WI1 = 10, WF1 = 22,
                              WI2 = 10, WF2 = 22,
                              WIO = WI1 > WI2 ? WI1 : WI2,
                              WFO = WF1 > WF2 ? WF1 : WF2,
                              set_x_val = 0 )
(
    input CLK,
    input RESET,
    input [31 : 0] in,
    output reg [31 : 0] out
);
    reg [31 : 0] value;
    initial
    begin
        if(set_x_val == 1)
        begin
            out <= top.initial_x;
        end
        else
        begin
            out <= 0;
        end
    end
    
    always @ (posedge CLK)
    begin
        out <= value;
    end
    
    always @ (*)
    begin
        if(RESET)
        begin
            if(set_x_val == 1)
            begin
                out <= top.initial_x;
                value <= in;
            end
            else
            begin
                out <= 0;
                value <= in;
            end
        end
        else value <= in;
    end
endmodule
