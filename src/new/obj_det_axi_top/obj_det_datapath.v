`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/08/2019 08:58:22 PM
// Design Name: 
// Module Name: obj_det_datapath
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


module obj_det_datapath(
    input         pixel_clk,
    input         init_done,
    input         frame_start,
    input         resetn,
    input         pixel_in,
    input  [16:0] ref_addr,
    input         ref_wren,
    input         ref_bram_enable,
    input  [16:0] diff_addr,
    input         diff_wren,
    input         diff_bram_enable,
    input  [15:0] object_thres,
    input  [15:0] static_thres,
    input  [15:0] suspicion_thres,
    output        object_detected,
    output        suspicion_detected,
    output        prev_pixel_out,
    output        ref_pixel_out,
    output [9:0]  frame_count,
    output [15:0]  suspicion_out
    );
    
    
    // Pixels
    reg curr_pixel, pixel_in_d1;
    wire ref_pixel, diff_pixel, prev_diff_pixel, match_pixel;

    // Diff pixel
    reg diff_pixel_d1, diff_pixel_d2;
    
    // Counters to detect objects and mark as suspicious
    reg [16:0] diff_cnt, match_cnt;

    // Suspicion level
    reg [8:0]  suspicion;

    // Goes high when enough pixels are the same between frames
    wire frame_match;

    reg [9:0] frame_cnt;

    assign frame_count = frame_cnt;

    assign suspicion_out = suspicion;

    // Latch pixel from camera. Delay to account for 2 cycle read latency on BRAMs.
    // Otherwise curr_pixel and ref/diff pixel will not be aligned.
    always@(posedge pixel_clk or negedge resetn) begin
        if (!resetn) begin
            pixel_in_d1 <= 1'b0;
            curr_pixel  <= 1'b0;

            diff_pixel_d1 <= 1'b0;
            diff_pixel_d2 <= 1'b0;
        end else begin
            // curr pixel is delayed by 2 clock cycle
            pixel_in_d1 <= pixel_in & (ref_wren | diff_wren); // Gate by capture_wren so that invalid pixel data does not propagate through
            curr_pixel  <= pixel_in_d1 & (ref_wren | diff_wren); // Gate by capture_wren so that invalid pixel data does not propagate through
            
            // Delay diff pixel by 2 clock cycles
            diff_pixel_d1 <= diff_pixel;
            diff_pixel_d2 <= diff_pixel_d1;

        end

    end

    
    // Block Memory Generated BRAM
    // 1-bit wide, 76800 depth. Single Port RAM
    // 2 cycle read latency
    // Port A: Operating Mode - Write First  | Use ENA pin
    blk_mem_gen_obj_det_ref_1bit ref_frame_buffer(
                        .addra  (ref_addr),
                        .clka   (pixel_clk),
                        .dina   (pixel_in),
                        .douta  (ref_pixel),
                        .ena    (ref_bram_enable),
                        .wea    (ref_wren));
                                      
    // Compare current pixel to reference frame
    assign diff_pixel  = ((ref_pixel ^ curr_pixel) & init_done);
    
    // Bring out prev_diff_pixel for live testing
    assign prev_pixel_out = prev_diff_pixel;

    assign ref_pixel_out = ref_pixel;
    
    // Block Memory Generated BRAM
    // 1-bit wide, 76800 depth. Single Port RAM
    // 2 cycle read latency
    // Port A: Operating Mode - Read First  | Use ENA pin
    blk_mem_gen_obj_det_diff_1bit diff_frame_buffer(
                        .addra  (diff_addr),
                        .clka   (pixel_clk),
                        .dina   (diff_pixel),
                        .douta  (prev_diff_pixel),
                        .ena    (diff_bram_enable),
                        .wea    (diff_wren)
                        );
    
    // Compare difference to previous difference
    // Delay difference by one clock cycle to align with output of difference BRAM (prev_diff_pixel)
    assign match_pixel = ((diff_pixel_d2 & prev_diff_pixel) & init_done);
    
    // Counters to track number of difference pixels in an image
    always@(posedge pixel_clk) begin
        // Reset counts to zero in reset, while capturing reference frame, or at the start of a new frame
        if (!resetn | ~init_done) begin
            suspicion <= 1'b0;
            diff_cnt  <= 1'b0;
            match_cnt <= 1'b0;
            frame_cnt <= 1'b0;
        end else if (frame_start) begin
            if (!frame_match) begin // reset suspicion if the previous frame was not matching
                suspicion <= 1'b0;
            end else begin
                suspicion <= (suspicion < suspicion_thres) ? (suspicion + 1) : suspicion; // Rail at max
            end
            diff_cnt  <= 1'b0;
            match_cnt <= 1'b0;

            frame_cnt <= frame_cnt + 1; // Increment frame counter

        end else begin // Count number of non-zero pixels. Only increment when a new pixel arrives
            diff_cnt  <= diff_cnt  + (diff_wren & diff_pixel); 
            match_cnt <= match_cnt + (diff_wren & match_pixel);
        end
    end

    assign object_detected    = (diff_cnt > object_thres);
    assign frame_match        = (object_detected & (match_cnt > static_thres));
    assign suspicion_detected = (suspicion == suspicion_thres);

endmodule
