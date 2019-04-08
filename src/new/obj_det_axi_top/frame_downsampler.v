`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/23/2019 10:06:09 AM
// Design Name: 
// Module Name: frame_downsampler
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


module frame_downsampler(
    input clk,
    input resetn,
    
    // OV7670 Camera outputs
    input [16:0] ov7670_capture_addr,
    input [15:0] decimation_rate,
    input ov7670_vsync,
    
    // BRAM interface
    output reg [16:0] tdata_addr,
    input      [15:0] tdata,
    
    // Outputs to object detection
    output [16:0] obj_det_addr,
    output [15:0] obj_det_pixel,
    output obj_det_wren
    );
    
    parameter FRAME_SIZE = 76800;
    
    
    reg tvalid, transfer;

    // Stores delayed version of read data
    reg [15:0] buffered_capture_pixel;

    reg [19:0] cnt;
    wire [19:0] max_vsync_cnt;
    
    // TODO: change back to decimation_rate = 16'hfff0 
    assign max_vsync_cnt = decimation_rate << 2; //16'hfff0 << 2;//decimation_rate;//decimation_rate << 2;
    

    assign obj_det_addr = ((tdata_addr) >= 17'd2) ? (tdata_addr - 17'd2) : 17'd0;
    assign obj_det_wren = tvalid | transfer;
    assign obj_det_pixel = buffered_capture_pixel[15:0];
    

    reg [31:0] vsync_cnt;

    always @(posedge clk or negedge resetn) begin
        if (resetn == 0) begin
            buffered_capture_pixel <= 0;
            tvalid <= 0;
            tdata_addr <= 0;
            cnt <= 0;
            transfer <= 0;
            vsync_cnt <= 0;
        end
        else begin
            if (ov7670_vsync) begin
                vsync_cnt <= vsync_cnt + 1;
            end
            if (vsync_cnt >= max_vsync_cnt && ~transfer && ov7670_capture_addr == (FRAME_SIZE - 1)) begin
                transfer <= 1;
            end
            else if (transfer && cnt <= FRAME_SIZE) begin
                if (cnt > 0)
                    tvalid <= 1;
                else
                    tvalid <= 0;
                tdata_addr <= tdata_addr + 1;
                buffered_capture_pixel <= tdata; // Send out pixel read from BRAM
                cnt <= cnt + 1;
            end
            else if (cnt == (FRAME_SIZE + 1)) begin
                cnt <= 0;
                tvalid <= 0;
                tdata_addr <= 0;
                transfer <= 0;
                vsync_cnt <= 0;
            end
        end
    end

endmodule
