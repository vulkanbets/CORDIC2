`timescale 1ns / 1ps

module add_Fixed # ( parameter  WI1 = 4, WF1 = 4,    // input 1 integer and fraction bits
                                WI2 = 4, WF2 = 4,    // input 2 integer and fraction bits
             WIO = WI1 > WI2 ? WI1 + 1 : WI2 + 1,    // output integer bits
             WFO = WF1 > WF2 ? WF1 : WF2 )           // output fraction bits
(
    input RESET,
    input signed [WI1 + WF1 - 1 : 0] in1,       // Add # 1
    input signed [WI2 + WF2 - 1 : 0] in2,       // Add # 2
    output signed [WIO + WFO - 1 : 0] out,      // Output
    output reg OVF                              // Overflow flag
);
    // Local Parameters; Precise addition parameters
    localparam WIP = WI1 > WI2 ? WI1 + 1 : WI2 + 1;     // local parameters for Precise integer bits
    localparam WFP = WF1 > WF2 ? WF1 : WF2;             // local parameters for Precise fraction bits
    localparam maxWI = WI1 > WI2 ? 1 : 0;               // 1 means WI1 is bigger; 0 means WI2 is bigger
    localparam maxWF = WF1 > WF2 ? 1 : 0;               // 1 means WF1 is bigger; 0 means WF2 is bigger
    
    // Used to align the decimal points
    reg [WIP + WFP - 2 : 0] in1_Temp;
    reg [WIP + WFP - 2 : 0] in2_Temp;
    // Same as above but with the sign bit
    reg [WIP + WFP - 1 : 0] in1_Temp2;      //  These have the aligned values in them
    reg [WIP + WFP - 1 : 0] in2_Temp2;      //  These have the aligned values in them
    
    // Determine which inputs have the smallest WI's or WF's
    wire smallest_WI = WI1 < WI2 ? 1 : 0;    // 1 means WI1 is smaller; 0 means WI2 is smaller
    wire smallest_WF = WF1 < WF2 ? 1 : 0;    // 1 means WF1 is smaller; 0 means WF2 is smaller
    
    // Temporary registers for output
    reg [WIO - 1 : 0] temp_out_int_bits;
    reg [WFO - 1 : 0] temp_out_frac_bits;
    
    // Compute the full precision product
    wire signed [WIP + WFP - 1 : 0] fullPreciseSum = in1_Temp2 + in2_Temp2;     // Precise sum
    
    // fullPreciseProduct Sign bit
    wire sign_Bit = fullPreciseSum[WIP + WFP - 1];                  // fullPreciseSum Sign bit
    
    // Store Integer bits and Fraction bits
    wire [WIP - 1 : 0] precise_int_bits  = fullPreciseSum[WIP + WFP - 1 : WFP];   // Just the integer  bits of fullPreciseSum
    wire [WFP - 1 : 0] precise_frac_bits = fullPreciseSum[WFP - 1 : 0];           // Just the fraction bits of fullPreciseSum
    
    // Int temp wire
    reg [WIP - WIO - 1 : 0] tmp;   // Truncated integer bits
    
    initial OVF <= 0;       // Set intial state of overflow = 0
    
    wire [WI1 - 1 : 0] In1_int_bits  = in1[WI1 + WF1 - 1 : WF1];  // Just the integer  bits of in1
    wire [WF1 - 1 : 0] In1_frac_bits = in1[WF1 - 1 : 0];          // Just the fraction bits of in1
    wire [WI2 - 1 : 0] In2_int_bits  = in2[WI2 + WF2 - 1 : WF2];  // Just the integer  bits of in2
    wire [WF2 - 1 : 0] In2_frac_bits = in2[WF2 - 1 : 0];          // Just the fraction bits of in2
    
    always @ (*)
    begin
        if(RESET) begin in1_Temp <= 0; in2_Temp <= 0; end
        else
        if(smallest_WI && smallest_WF) // WI1 is smaller; WF1 is smaller
        begin
            in1_Temp <= in1 <<< (WF2 - WF1) ;  // {(WI2 - WI1){in1[WI1 + WF1 - 1]}}
            in2_Temp <= in2;
        end
        else if(smallest_WI && !smallest_WF) // WI1 is smaller; WF2 is smaller
        begin
            in1_Temp <= { {((WIP + WFP)-(WI1 + WF1)){in1[WI1 + WF1 - 1]}} , in1 };
            in2_Temp <= { in2 , {((WIP + WFP)-(WI2 + WF2 + 1)){1'b0}} };
            
        end
        else if(!smallest_WI && smallest_WF) // WI2 is smaller; WF1 is smaller
        begin
            in2_Temp <= { {((WIP + WFP)-(WI2 + WF2)){in2[WI2 + WF2 - 1]}} , in2 };
            in1_Temp <= { in1 , {((WIP + WFP)-(WI1 + WF1 + 1)){1'b0}} };
        end
        else                                // WI2 is smaller; WF2 is smaller
        begin
            in2_Temp <= in2 <<< (WF1 - WF2);
            in1_Temp <= in1;
        end
        in1_Temp2 <= { in1_Temp[WIP + WFP - 2] , in1_Temp };
        in2_Temp2 <= { in2_Temp[WIP + WFP - 2] , in2_Temp };
        
        
        // -------------------------Output Bitwidth logic
        
        // Logic for integer bits
        if( WIO == WIP )  // Assign precise bits to temp_out_int_bits
        begin
            temp_out_int_bits <= precise_int_bits;
            // ----------------------------- Check for overflow
            if( in1[WI1+WF1-1]==in2[WI2+WF2-1]==~out[WIO+WFO-1] || (~in1[WI1+WF1-1]==~in2[WI2+WF2-1]==out[WIO+WFO-1]) )
                OVF <= 1;
            else
                OVF <= 0;
        end
        else if( WIO > WIP )  // sign-extend
        begin
            temp_out_int_bits <= {{ (WIO - WIP){precise_int_bits[WIP - 1]}} , precise_int_bits };
            OVF <= 0;       // Overflow always = 0 in this case
        end
        else        // WIO < max(WF1 + WF2) + 1;
        begin
            tmp <= precise_int_bits[WIP - 1 : WIP - (WIP - WIO)];
            temp_out_int_bits <= { precise_int_bits[WIP - 1], precise_int_bits[WIO - 2 : 0] };
               // ----------------------------- Check for overflow
            if( (in1[WI1+WF1-1]==in2[WI2+WF2-1]== (&tmp) ) || ( ~in1[WI1+WF1-1]==~in2[WI2+WF2-1]== (|tmp)) )
                OVF <= 0;
            else
                OVF <= 1;
        end
        
        
        // Logic for fraction bits
        if( WFO == WFP ) 
        begin                       // Assign precise bits to temp_out_frac_bits
            temp_out_frac_bits <= precise_frac_bits;
            OVF <= 0;
        end
        else if( WFO > WFP )
        begin                           // Append zeros
            temp_out_frac_bits <= { precise_frac_bits[WFP - 1 : 0] , {(WFO - (WF1 + WF2 + 1)){1'b0}} };
            OVF <= 0;
        end
        else
        begin       // WFO < max(WF1 + WF2); Truncate bits
            temp_out_frac_bits <= precise_frac_bits[WFP - 1 : WFP - 1 - (WFO - 1)];
            OVF <= 0;
        end
    end
    
    assign out = {temp_out_int_bits , temp_out_frac_bits};
    
endmodule

