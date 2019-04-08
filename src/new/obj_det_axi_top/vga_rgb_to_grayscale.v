`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/05/2019 12:11:11 AM
// Design Name: 
// Module Name: vga_rgb_to_grayscale
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

// Converts the subcomponents of an RGB444 pixel into the subcomponents of an RGB444 grayscale pixel
module vga_rgb_to_grayscale(
    input enable_bw,
    input [7:0] bw_threshold,
    input [3:0] r,       /* Connect to Inst_vga output vga_red */
    input [3:0] g,       /* Connect to Inst_vga output vga_green */
    input [3:0] b,	     /* Connect to Inst_vga output vga_blue */
    output [7:0] gray8_out,
    output [3:0] r_gray, /* Connect to ov7670_top output vga444_red */
    output [3:0] g_gray, /* Connect to ov7670_top output vga444_green */
    output [3:0] b_gray  /* Connect to ov7670_top output vga444_blue */    
    );
    
    wire [7:0] grayscale_8bit, grey_thresholded;
    
    
    // Convert RGB444 to 8-bit grayscale
    rgb444_to_gray rgb_to_gray_converter(.vga444_red(r),
                                         .vga444_green(g),
                                         .vga444_blue(b),
                                         .gray_out(grayscale_8bit));
   assign gray8_out = grayscale_8bit;
    
    // Convert grayscale to black and white depending on threshold input
    grayscale8_to_bw bw_converter(.enable(enable_bw), .gray_in(grayscale_8bit), .threshold(bw_threshold), .bw_out(grey_thresholded));
    
    // Convert 8-bit grayscale back to RGB444 for display                                  
    gray_to_rgb444 gray_to_rgb_converter(.vga444_red(r_gray),
                                         .vga444_green(g_gray),
                                         .vga444_blue(b_gray),
                                         .gray_in(grey_thresholded));
                                         
                                         
endmodule
