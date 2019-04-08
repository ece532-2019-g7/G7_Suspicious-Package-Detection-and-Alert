`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/03/2019 05:44:53 PM
// Design Name: 
// Module Name: obj_det_unit_top
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


module obj_det_unit_top
    (

    // External inputs
    input clk,
    input resetn,
    
    // Preprocessing inputs (from AXI CONFIG1 register)
    input [7:0] bw_thres,

    // OV7670_CAPTURE Ports
    input [16:0] capture_addr,          // Connected to addr output of downsampler module
    input        capture_wren,          // Connected to we output of downsampler module
    input [15:0] pixel_in,              // Connected to dout output of downsampler module
    input ov7670_config_done,           // Connected to I2C_AV_CONFIG. Goes high when camera is done configuration

    // Control inputs (from AXI CONFIG1 Register)
    input        start_capture,         // Set to high to start algorithm (AXI R/W)

    // Threshold Configuration (from AXI registers)
    input [15:0] detection_thres,       // The number of active pixels to signal a detected object (AXI R/W)
    input [15:0] static_thres,          // The number of active pixels that must be the same between consecutive frames to be considered static  (AXI R/W)
    input [15:0] suspicion_thres,       // Time in seconds that image must be stable for to be considered suspicious (AXI R/W)
    
    // Algorithm outputs (Connect to AXI STAT1 register)
    output object_detected,             // Per frame output that goes high when an object is detected in a frame. Goes low between frames
    output object_susp,                 // Output that goes high when suspicious object is detected
    output [15:0] suspicion_out,

    // Debugging outputs
    output [7:0] prev_diff_pixel,
    output [7:0] ref_pixel
    );

    parameter FRAME_SIZE = 76800;


    // RGB components of incoming pixel from OV7670
    wire [3:0] pixel_in_r, pixel_in_g, pixel_in_b;
    
    // 8-bit grayscale of incoming pixel from OV7670. This output is written to the OV7670 BRAM for DRAM transfer to DRAM
    wire [7:0] pixel_in_gray8;
    
    // Stores black and white pixel to be put into BRAM buffers
    wire [7:0] pixel_in_bw8;
    
    // Frame pixel to be inputed into object detection algo
    wire susp_pixel_in;

    assign pixel_in_r = pixel_in[11:8];
    assign pixel_in_g = pixel_in[7:4];
    assign pixel_in_b = pixel_in[3:0];
    
   // Convert RGB444 to 8-bit grayscale. This output is written to the OV7670 BRAM for DMA transfer to DRAM
   rgb444_to_gray rgb_to_gray_converter(.vga444_red(pixel_in_r),
                                        .vga444_green(pixel_in_g),
                                        .vga444_blue(pixel_in_b),
                                        .gray_out(pixel_in_gray8));
                                         
    // Convert 8-bit grayscale to 8-bit black and white so it can be written to BRAM buffers
    grayscale8_to_bw gray8_to_bw_inst(.enable(1'b1),
                                      .gray_in(pixel_in_gray8),
                                      .threshold(bw_thres),
                                      .bw_out(pixel_in_bw8));
                                      
    assign susp_pixel_in = pixel_in_bw8[0];
             
    suspicious_object_detector #(
        .FRAME_SIZE       (FRAME_SIZE)
        )
        suspicious_object_detector_inst(
        .clk              (clk),
        .resetn           (resetn),
        .i2c_config_done  (ov7670_config_done),
        .capture_pixel    (susp_pixel_in),
        .capture_addr     (capture_addr),
        .capture_wren     (capture_wren),
        .detection_thres  (detection_thres),
        .static_thres     (static_thres),
        .suspicion_thres  (suspicion_thres),
        .obj_detected     (object_detected),
        .susp_obj_detected(object_susp),
        .prev_diff_pixel8 (prev_diff_pixel),
        .ref_pixel8       (ref_pixel),
        .start_capture    (start_capture),
        .suspicion_out    (suspicion_out)                                           
    ); 
    

endmodule
