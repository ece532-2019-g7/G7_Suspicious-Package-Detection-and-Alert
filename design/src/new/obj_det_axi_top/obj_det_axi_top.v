`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/26/2019 04:04:12 PM
// Design Name: 
// Module Name: obj_det_axi_top
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


module obj_det_axi_top #
	(
        parameter integer FRAME_SIZE            = 76800,
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 5
	) (

		input wire  clk100,
		input wire  clk25,
		input wire  resetn,
		
	    // Ports of Axi Slave 
		input wire s00_axi_aclk,
        input wire s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready,
	    
	    // Inputs from downsampler
	    input wire [16:0] obj_det_addr,
	    input wire [15:0] obj_det_pixel,
	    input wire        obj_det_wren,
	    input wire        config_finished,
	    
	    // Outputs from object detection to downsampler
	    output wire       suspicious_detected,
	    output wire [15:0] decimation_rate,
	    
	    // External ports
	    input wire [15:0] switches,
	    output wire [11:0] leds,
	    
	    // VGA Ports
        output wire [3:0] vga444_red,
        output wire [3:0] vga444_green,
        output wire [3:0] vga444_blue,
        output wire vga_hsync,
        output wire vga_vsync
	    
    );
    
    // Intermediate wires for  VGA display
     wire [15:0] ref_pixel_rgb, prev_diff_pixel_rgb;
     wire [7:0] prev_diff_pixel, ref_pixel;
     
     wire [3:0] prev_diff_pixel_r, prev_diff_pixel_g, prev_diff_pixel_b;
     wire [3:0] ref_pixel_r, ref_pixel_g, ref_pixel_b;

    // Object detection parameters
    wire [16:0] detection_thres, static_thres, suspicion_thres;
    wire [15:0] suspicion;
    wire [7:0]  bw_thres_in, bw_threshold_axi;
    
    wire start_capture, object_detected, object_susp;
    
    // Mux between AXI threshold and switches threshold
    assign bw_thres_in = (!switches[15]) ? bw_threshold_axi : switches[7:0];
    
    // Output alert to interrupt block and to downsampler
    assign suspicious_detected = object_susp;
    
    
    assign leds[11] = object_susp;
    assign leds[10] = object_detected;
    assign leds[9] = start_capture;
    
    assign leds[7:0] = suspicion;
    
    assign leds[8]   = obj_det_wren;
    
    //////////////////////// Object Detection /////////////////////////////////
    
    obj_det_unit_top #(
        .FRAME_SIZE              (FRAME_SIZE)
    ) obj_det_unit_top_inst(
        
        // External inputs
        .clk                     (clk100),
        .resetn                  (resetn),
        
        // Preprocessing inputs (from AXI CONFIG1 register)
        .bw_thres                (bw_thres_in),
        
        // OV7670_CAPTURE Ports
        .capture_addr            (obj_det_addr),          
        .capture_wren            (obj_det_wren),          
        .pixel_in                (obj_det_pixel),              
        .ov7670_config_done      (config_finished),                  
        
        // Control inputs (from AXI CONFIG1 Register)
        .start_capture           (start_capture),        
        
        // Threshold Configuration (from AXI registers)
        .detection_thres         (detection_thres),       
        .static_thres            (static_thres),          
        .suspicion_thres         (suspicion_thres),      
        
        // Algorithm outputs (Connect to AXI STAT1 register)
        .object_detected         (object_detected),             
        .object_susp             (object_susp),                
        .suspicion_out           (suspicion),
        
        // Debugging outputs
        .prev_diff_pixel         (prev_diff_pixel),
        .ref_pixel               (ref_pixel)
    );
    
    //////////////////// VGA for debugging /////////////////////////
    
    wire [16:0] vga_frame_addr;
    wire [15:0] vga_frame_pixel, vga_bram_in;
    
    wire [7:0] gray_data_8;
    wire [15:0] bw_data_16;
    
    // VGA BRAM
    blk_mem_gen_0 u_vga_frame_buffer (
       .clka    (clk100),    
       .wea     (obj_det_wren),      
       .addra   (obj_det_addr), 
       .dina    (vga_bram_in),   
       .clkb    (clk25),
       .enb     (1'b1),    
       .addrb   (vga_frame_addr), 
       .doutb   (vga_frame_pixel) 
     );
    
    // VGA encoder, reads VGA BRAM
     vga444   Inst_vga(
        .clk25       (clk25),
        .vga_red     (vga444_red),
        .vga_green   (vga444_green),
        .vga_blue    (vga444_blue),
        .vga_hsync   (vga_hsync),
        .vga_vsync   (vga_vsync),
        .HCnt        (),
        .VCnt        (),
    
        .frame_addr   (vga_frame_addr),
        .frame_pixel  (vga_frame_pixel) 
     );
     
    // Reconstruct RGB 444
    gray_to_rgb444 prev_diff_to_rgb_inst(
        .gray_in        (prev_diff_pixel),
        .vga444_red     (prev_diff_pixel_r),
        .vga444_green   (prev_diff_pixel_g),
        .vga444_blue    (prev_diff_pixel_b)
    );
    
    gray_to_rgb444 ref_to_rgb_inst(
        .gray_in        (ref_pixel),
        .vga444_red     (ref_pixel_r),
        .vga444_green   (ref_pixel_g),
        .vga444_blue    (ref_pixel_b)
    );

    // Convert downsampled pixel to black and white                              
    vga_rgb_to_grayscale vga_rgb_to_grayscale_inst(
        .enable_bw      (1'b1),
        .bw_threshold   (bw_thres_in), 
        .r              (obj_det_pixel[11:8]),       
        .g              (obj_det_pixel[7:4]),     
        .b              (obj_det_pixel[3:0]),      
        .gray8_out      (gray_data_8),
        .r_gray         (bw_data_16[11:8]), 
        .g_gray         (bw_data_16[7:4]), 
        .b_gray         (bw_data_16[3:0])  
    );
                                   
                                   
    assign ref_pixel_rgb       = {4'b0, ref_pixel_r, ref_pixel_g, ref_pixel_b};
    assign prev_diff_pixel_rgb = {4'b0, prev_diff_pixel_r, prev_diff_pixel_g, prev_diff_pixel_b};
    
    // Switch what is written to the VGA BRAM. Either data before passed through obj_det_unit, or after
    assign vga_bram_in   = !switches[14] ? bw_data_16 : (!switches[13] ? ref_pixel_rgb : prev_diff_pixel_rgb);
    
    
    ////////////////// AXI Slave registers /////////////////////////
    
    obj_det_axi_slave_0 obj_det_axi_slave_0_inst (
        // Object detection paramters
        .decimation_rate(decimation_rate),
        .bw_threshold(bw_threshold_axi),
        .start_capture(start_capture),
        .object_susp(object_susp),
        .object_detected(object_detected),
        .suspicion(suspicion),
        .detection_thres(detection_thres),
        .static_thres(static_thres),
        .suspicion_thres(suspicion_thres),     
        
        // Regular AXI slave ports  
        .s00_axi_aclk(s00_axi_aclk),
        .s00_axi_aresetn(s00_axi_aresetn),
        .s00_axi_awaddr(s00_axi_awaddr),
        .s00_axi_awvalid(s00_axi_awvalid),
        .s00_axi_awready(s00_axi_awready),
        .s00_axi_wdata(s00_axi_wdata),
        .s00_axi_wstrb(s00_axi_wstrb),
        .s00_axi_wvalid(s00_axi_wvalid),
        .s00_axi_wready(s00_axi_wready),
        .s00_axi_bresp(s00_axi_bresp),
        .s00_axi_bvalid(s00_axi_bvalid),
        .s00_axi_bready(s00_axi_bready),
        .s00_axi_araddr(s00_axi_araddr),
        .s00_axi_arvalid(s00_axi_arvalid),
        .s00_axi_arready(s00_axi_arready),
        .s00_axi_rdata(s00_axi_rdata),
        .s00_axi_rresp(s00_axi_rresp),
        .s00_axi_rvalid(s00_axi_rvalid),
        .s00_axi_rready(s00_axi_rready)
     );  
endmodule
