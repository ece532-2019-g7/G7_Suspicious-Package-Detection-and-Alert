`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2014/05/23 15:48:40
// Design Name: 
// Module Name: vga
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

// This module assumes a QVGA 320 x 240 image will be displayed in the middle
// of a 640 x 480 VGA screen.

module vga444(
input clk25,
output reg[3:0] vga_red,
output reg[3:0] vga_green,
output reg[3:0] vga_blue,
output reg vga_hsync,
output reg vga_vsync,
output [9:0] HCnt,
output [9:0] VCnt,

output [16:0] frame_addr,
input [15:0] frame_pixel
    );
    //Timing constants
      parameter hRez   = 640;
      parameter hStartSync   = 640+16;
      parameter hEndSync     = 640+16+96;
      parameter hMaxCount    = 800;
    
      parameter vRez         = 480;
      parameter vStartSync   = 480+10;
      parameter vEndSync     = 480+10+2;
      parameter vMaxCount    = 480+10+2+33;
    
    parameter hsync_active   =0;
    parameter vsync_active  = 0;
    reg[9:0] hCounter;
    reg[9:0] vCounter;    
    reg[16:0] address;  
    reg blank;
   initial   hCounter = 10'b0;
   initial   vCounter = 10'b0;  
   initial   address = 17'b0;   
   initial   blank = 1'b1;    
   
   assign frame_addr = address;
   assign HCnt = hCounter;
   assign VCnt = vCounter;
   
   always@(posedge clk25) begin
            if( hCounter == hMaxCount-1 )begin
   				hCounter <=  10'b0;
   				if (vCounter == vMaxCount-1 )
   					vCounter <=  10'b0;
   				else
   					vCounter <= vCounter+1;
   				end
   			else
   				hCounter <= hCounter+1;
   
   			if (blank ==0) begin
   				vga_red   <= frame_pixel[11:8];
   				vga_green <= frame_pixel[7:4];
   				vga_blue  <= frame_pixel[3:0];
   				end
   			else begin
   				vga_red   <= 4'b0;
   				vga_green <= 4'b0;
   				vga_blue  <= 4'b0;
   			     end;

                        // A 320 by 240 image is placed in the middle of a
                        //  640 by 480 screen
   			if(  vCounter  >= 360 || vCounter  < 120) begin
   				address <= 17'b0; 
   				blank <= 1;
   				end
   			else begin
   				if ( hCounter  < 480 && hCounter  >= 160) begin
   					blank <= 0;
   					address <= address+1;
   					end
   				else
   					blank <= 1;
   				end;
   	
   			// Are we in the hSync pulse? (one has been added to include frame_buffer_latency)
   			if( hCounter > hStartSync && hCounter <= hEndSync)
   				vga_hsync <= hsync_active;
   			else
   				vga_hsync <= ~ hsync_active;
   			
   
   			// Are we in the vSync pulse?
   			if( vCounter >= vStartSync && vCounter < vEndSync )
   				vga_vsync <= vsync_active;
   			else
   				vga_vsync <= ~ vsync_active;
   end 
endmodule
