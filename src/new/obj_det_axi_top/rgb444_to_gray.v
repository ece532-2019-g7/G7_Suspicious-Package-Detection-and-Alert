`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/04/2019 09:12:52 PM
// Design Name: 
// Module Name: rgb444_to_gray
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

// Convert RGB444 to 8-bit greyscale
module rgb444_to_gray(
    input [3:0] vga444_red,
    input [3:0] vga444_green,
    input [3:0] vga444_blue,
    output [7:0] gray_out
    );
    
    
    // Approximate the formula: gray_out = R * 0.3 + G * 0.59 + B * 0.11
    // Actual: gray_out = R*16*0.3125 + G*16*0.5625 + B*16*0.125
    assign gray_out = vga444_red * 5 + vga444_green * 9 + vga444_blue * 2;

endmodule
