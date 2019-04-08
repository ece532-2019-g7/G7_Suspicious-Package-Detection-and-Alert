`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/09/2019 11:28:47 PM
// Design Name: 
// Module Name: suspicious_object_detector
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


module suspicious_object_detector (
    input        clk,
    input        resetn,
    input        i2c_config_done,
    input        capture_pixel,
    input [16:0] capture_addr,
    input        capture_wren,
    input [15:0] detection_thres,
    input [15:0] static_thres,
    input [15:0] suspicion_thres,
    input        start_capture,
    output       obj_detected,
    output       susp_obj_detected,
    output [7:0] prev_diff_pixel8,
    output [7:0] ref_pixel8,
    output [15:0] suspicion_out
    );

    parameter FRAME_SIZE = 76800;

    // FSM Connections
    wire resetn_datapath;
    wire [16:0] ref_addr, diff_addr;
    wire ref_wren, ref_bram_enable, diff_wren, diff_bram_enable, init_done, frame_start;

    // Output of diff BRAM
    wire prev_diff_out;

    // Output of ref BRAM
    wire ref_pixel_out;
    
    // Output to parent module for debugging. Pad one-bit b/w bit to 8-bits
    assign prev_diff_pixel8 = {8{prev_diff_out}};
    assign ref_pixel8 = {8{ref_pixel_out}};

    wire [9:0] frame_count;

    obj_det_control #(
        .FRAME_SIZE      (FRAME_SIZE)
        ) obj_det_control_inst(
        .clk             (clk),
        .resetn          (resetn),
        .i2c_config_done (i2c_config_done),
        .capture_addr    (capture_addr),
        .capture_wren    (capture_wren),
        .resetn_datapath (resetn_datapath),
        .ref_addr        (ref_addr),
        .ref_wren        (ref_wren),
        .ref_bram_enable (ref_bram_enable),
        .diff_addr       (diff_addr),
        .diff_wren       (diff_wren),
        .diff_bram_enable(diff_bram_enable),
        .init_done       (init_done),
        .frame_start     (frame_start),
        .frame_count     (frame_count),
        .start_capture   (start_capture)
        );
     
    obj_det_datapath obj_det_datapath_inst(
        .pixel_clk         (clk),
        .init_done         (init_done),
        .resetn            (resetn_datapath),
        .pixel_in          (capture_pixel),
        .frame_start       (frame_start),
        .ref_addr          (ref_addr),
        .ref_wren          (ref_wren), 
        .ref_bram_enable   (ref_bram_enable),
        .diff_addr         (diff_addr),
        .diff_wren         (diff_wren),
        .diff_bram_enable  (diff_bram_enable),
        .object_thres      (detection_thres),
        .static_thres      (static_thres),
        .suspicion_thres   (suspicion_thres),
        .object_detected   (obj_detected),
        .suspicion_detected(susp_obj_detected),
        .prev_pixel_out    (prev_diff_out),
        .ref_pixel_out     (ref_pixel_out),
        .frame_count       (frame_count),
        .suspicion_out     (suspicion_out)
    );
endmodule
