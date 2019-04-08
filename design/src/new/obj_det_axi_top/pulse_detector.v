`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/15/2019 06:24:34 PM
// Design Name: 
// Module Name: pulse_detector
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


module pulse_detector(
    input clk,
    input resetn,
    input pulse_in,
    output reg level_out
    );


	always@(posedge clk) begin
		if (!resetn) begin
			level_out   <= 1'b0;
		end else if (pulse_in) begin
			level_out <= 1'b1;
		end
	end
endmodule
