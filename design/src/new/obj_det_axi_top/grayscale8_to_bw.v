`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/06/2019 05:31:26 PM
// Design Name: 
// Module Name: grayscale8_to_bw
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module grayscale8_to_bw(
    input enable,
    input [7:0] gray_in,
    input [7:0] threshold,
    output [7:0] bw_out
    );
    
    // Follow python implmentation of convert_to_bw()
    assign bw_out = (enable) ? ((gray_in > threshold) ? 8'd0 : 8'd255) : gray_in;
    
endmodule
