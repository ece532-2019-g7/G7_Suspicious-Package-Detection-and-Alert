`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/04/2019 11:35:45 PM
// Design Name: 
// Module Name: gray_to_rgb444
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

// Convert 8-bit greyscal to RGB444 to output to VGA
module gray_to_rgb444(
    input [7:0] gray_in,
    output [3:0] vga444_red,
    output [3:0] vga444_green,
    output [3:0] vga444_blue
    );
    
    // Get rid of lower 4 MSB to convert 8-bit to 4-bit
    assign vga444_red = gray_in >> 4;
    assign vga444_green = gray_in >> 4;
    assign vga444_blue = gray_in >> 4;
    
endmodule
