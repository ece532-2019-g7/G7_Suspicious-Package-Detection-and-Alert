`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2014/05/23 16:24:31
// Design Name: 
// Module Name: ov7725_top
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


module ov7670_top(


// OV7670 Ports
input  CLK100MHZ,
input  OV7670_VSYNC,
input  OV7670_HREF,
input  OV7670_PCLK,
output OV7670_XCLK,
output OV7670_SIOC,
inout  OV7670_SIOD,
input [7:0] OV7670_D,


// VGA Ports
output[3:0] vga444_red,
output[3:0] vga444_green,
output[3:0] vga444_blue,
output vga_hsync,
output vga_vsync,


// External ports
output[15:0] LED,
input BTNC,
input BTND,
input BTNL,
input [15:0] SW, /* Switches to program threshold */
output pwdn,
output reset

);

parameter FRAME_SIZE = 76800;

// Address busses
wire [16:0] capture_addr, frame_addr, vga_frame_addr, obj_det_addr, vga_bram_addr;

// Pixel data busses
wire [15:0] rgb_data_16, bw_data_16, frame_pixel, vga_frame_pixel, obj_det_pixel, vga_bram_in;

// Write enables
wire capture_wren, obj_det_wren, vga_wren;
wire frame_bram_wren;

// I2C OConfig
wire  config_finished;  
wire  resend; 


// Clocks
wire  clk25, clk100, clk200;  
assign pwdn = 0;
assign reset = 1;

// Object detection status and config
wire [15:0] suspicion_out;
wire object_detected, suspicion_detected, object_alert;
wire [15:0] decimation_rate;
wire [15:0] ov7670_frame_rate, detection_thres, static_thres, suspicion_thres;
wire start_capture;

assign ov7670_frame_rate = 16'd200;
assign decimation_rate = 16'hfff0; 
assign detection_thres = FRAME_SIZE >> 4; // 4800 pixels
assign static_thres    = FRAME_SIZE >> 5; // 2400 pixels
assign suspicion_thres = 16'd40; // 40 frames

assign LED[15] = suspicion_detected;
assign LED[14] = object_detected;
assign LED[13] = start_capture;


assign  	OV7670_XCLK = clk25;

assign LED[7:0] = suspicion_out;

assign LED[8]   = obj_det_wren;
assign LED[9]   = suspicion_detected;

// The button (BTNC) is used to resend the configuration bits to the camera.
// The button is debounced with a 50 MHz clock
 debounce   btn_debounce(
 		.clk(clk25),
 		.i(BTNC),
 		.o(resend)
 );


// This button is used to reset the clock
wire clk_reset;
 debounce   reset_debounce(
 		.clk(clk25),
 		.i(BTND),
 		.o(clk_reset)
 );


 debounce start_debounce(
     .clk(clk25),
     .i(BTNL), // Right button starts capture
     .o(start_capture)
   );

//assign start_capture = BTNL;
//assign clk_reset     = BTND;
//assign resend        = BTNC;

// Intermediate wires for display
wire [7:0] gray_data_8;
wire [15:0] gray_data_16;

 wire [3:0] vga444_red_stub, vga444_green_stub, vga444_blue_stub;
 wire [3:0] vga444_red_susp, vga444_green_susp, vga444_blue_susp;
 wire [15:0] vga444_susp16;


 wire [15:0] ref_pixel_rgb, prev_diff_pixel_rgb;
 wire [7:0] prev_diff_pixel, ref_pixel;
 
 wire [3:0] prev_diff_pixel_r, prev_diff_pixel_g, prev_diff_pixel_b;
 wire [3:0] ref_pixel_r, ref_pixel_g, ref_pixel_b;
     
 assign gray_data_16 = {8'b0, gray_data_8};


assign frame_bram_wren = capture_wren & ~suspicion_detected; // Stop writing BRAM when suspicious object is detected
 //////////////// Start DUT //////////////////////////

ov7670_capture capture(
    .pclk  (OV7670_PCLK),
    .vsync (OV7670_VSYNC),
    .href  (OV7670_HREF),
    .d     ( OV7670_D),
    .addr  (capture_addr),
    .dout  (rgb_data_16),
    .we   (capture_wren)
  );

// Immediate frame buffer. Read by downsampler
blk_mem_gen_0 u_frame_buffer (
  // Write port
   .clka(clk25),    
   .wea(frame_bram_wren),     
   .addra(capture_addr),  
   .dina(rgb_data_16),   
  // Read port 
   .clkb(clk100),    
   .enb(obj_det_wren),
   .addrb(frame_addr),  
   .doutb(frame_pixel)  
 );

frame_downsampler #(
    .FRAME_SIZE(FRAME_SIZE)
    ) frame_downsampler_inst(
    .clk(clk100),
    .resetn(!resend), // Active low reset
    
    // OV7670 Camera outputs
    .ov7670_capture_addr(capture_addr),
    .decimation_rate(decimation_rate),
    .ov7670_vsync(OV7670_VSYNC),
    
    // BRAM interface
    .tdata_addr(frame_addr), // Frame Buffer read address
    .tdata(frame_pixel), // Frame Buffer read data
    
    // Outputs to object detection
    .obj_det_addr(obj_det_addr),
    .obj_det_pixel(obj_det_pixel),
    .obj_det_wren(obj_det_wren)
);

vga_rgb_to_grayscale vga_rgb_to_grayscale_inst(
    .enable_bw(SW[15]), /* Toggle between black and white or not */
    .bw_threshold(SW[7:0]), /* Used to program black and white threshold */
    .r(obj_det_pixel[11:8]),       /* Connect to RGB camera output */
    .g(obj_det_pixel[7:4]),       /* Connect to RGB camera output  */
    .b(obj_det_pixel[3:0]),      /* Connect to RGB camera output */
    .gray8_out(gray_data_8),
    .r_gray(bw_data_16[11:8]), /* Connect to wrdata port of BRAM */
    .g_gray(bw_data_16[7:4]), /* Connect to wrdata port of BRAM*/
    .b_gray(bw_data_16[3:0])  /* Connect to wrdata port of BRAM */
    );
 

 assign ref_pixel_rgb = {4'b0, ref_pixel_r, ref_pixel_g, ref_pixel_b};
 assign prev_diff_pixel_rgb = {4'b0, prev_diff_pixel_r, prev_diff_pixel_g, prev_diff_pixel_b};
 
 // Switch what is written to the BRAM. Either data before passed through obj_det_unit, or after
 assign vga_bram_in   = !SW[14] ? bw_data_16 : (!SW[13] ? ref_pixel_rgb : prev_diff_pixel_rgb);
 assign vga_bram_addr = obj_det_addr;
 assign vga_wren      = obj_det_wren;

 // BRAM using memory generator from IP catalog
// Simple dual-port, 16 bits wide, 76800 deep  
blk_mem_gen_0 u_vga_frame_buffer (
   .clka(clk100),    
   .wea(vga_wren),      
   .addra(vga_bram_addr), 
   .dina(vga_bram_in),   
   .clkb(clk25),
   .enb (1'b1),    
   .addrb(vga_frame_addr), 
   .doutb(vga_frame_pixel) 
 );

 vga444   Inst_vga(
    .clk25       (clk25),
    .vga_red    (vga444_red),//_stub),
    .vga_green   (vga444_green),//_stub),
    .vga_blue    (vga444_blue),//_stub),
    .vga_hsync   (vga_hsync),
    .vga_vsync  (vga_vsync),
    .HCnt       (),
    .VCnt       (),

    .frame_addr   (vga_frame_addr),
    .frame_pixel  (vga_frame_pixel) 
 );

gray_to_rgb444 prev_diff_to_rgb_inst(.gray_in(prev_diff_pixel),
                                     .vga444_red(prev_diff_pixel_r),
                                     .vga444_green(prev_diff_pixel_g),
                                     .vga444_blue(prev_diff_pixel_b));

gray_to_rgb444 ref_to_rgb_inst(.gray_in(ref_pixel),
                               .vga444_red(ref_pixel_r),
                               .vga444_green(ref_pixel_g),
                               .vga444_blue(ref_pixel_b));

 
I2C_AV_Config IIC(
 		.iCLK   (clk25),    
 		.iRST_N (!resend),    
 		.Config_Done (config_finished),
 		.I2C_SDAT  ( OV7670_SIOD),    
 		.I2C_SCLK  ( OV7670_SIOC),
 		.LUT_INDEX (),
 		.I2C_RDATA ()
 		); 







obj_det_unit_top #(
        .FRAME_SIZE              (FRAME_SIZE)
      ) obj_det_unit_top_inst(
    
        // External inputs
        .clk                     (clk100),
        .resetn                  (!resend),
        
        // Preprocessing inputs (from AXI CONFIG1 register)
        .bw_thres                (SW[7:0]),
    
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
        .object_susp             (suspicion_detected),                
        .suspicion_out           (suspicion_out),
    
        // Debugging outputs
        .prev_diff_pixel         (prev_diff_pixel),
        .ref_pixel               (ref_pixel)
        );
    // User logic ends


wire locked;
   
clk_wiz_0 u_clock
   (
   // Clock in ports
    .clk_in1(CLK100MHZ),      // input clk_in1
    .reset(clk_reset),
    // Clock out ports
    .clk_out1(clk100),     // output clk_out1
    .clk_out2(clk200),   // output clk_out2
    .clk_out3(clk25),   // output clk_out2
    .locked(locked)
    );

 ///////////////////////// END DUT ////////////////////////////

endmodule
