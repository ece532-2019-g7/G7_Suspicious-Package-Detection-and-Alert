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
    input aclk,                     // 100 Mhz input clock
    input clk25,                    // 25 MHz input clock, in-phase with 100 MHz
    input aresetn,                  // Asynchronous active-low reset
    
    // AXI-Lite slave interface
    input [31:0]  S_AXI_AWADDR,
    input         S_AXI_AWVALID,
    output        S_AXI_AWREADY,
    
    input [31:0]  S_AXI_WDATA,
    input [3:0]   S_AXI_WSTRB,
    input         S_AXI_WVALID,
    output        S_AXI_WREADY,
    
    output [1:0]  S_AXI_BRESP,
    output        S_AXI_BVALID,
    input         S_AXI_BREADY,
    
    input [31:0]  S_AXI_ARADDR,
    input         S_AXI_ARVALID,
    output        S_AXI_ARREADY,
    
    output [31:0] S_AXI_RDATA,
    output [1:0]  S_AXI_RRESP,
    output        S_AXI_RVALID,
    input         S_AXI_RREADY,
    
    // camera
    input  OV7670_VSYNC,
    input  OV7670_HREF,
    input  OV7670_PCLK,
    output OV7670_XCLK,
    output OV7670_SIOC,
    inout  OV7670_SIOD,
    input [7:0] OV7670_D,
    output pwdn, 
    output reset,
    
    // Connections to AXI Object Detection IP
    output [16:0] obj_det_addr,         // Address input to object detection ip
    output [15:0] obj_det_pixel,        // Pixel from camera frame in full RGB444
    output        obj_det_wren,         // Capture wren for object detection, synced with read enable on immediate buffer
    output        ov7670_config_done,   // Indicates to object detection that camera is finished configuration
    input         obj_det_susp,         // Goes high when suspicious object detected
    input  [15:0] decimation_rate       // Decimation rate for downsampler
);

    // Number of pixels in frame for QVGA. DO NOT CHANGE    
    parameter FRAME_SIZE = 76800;
    
    // Ouptut clock to run OV7670
    assign OV7670_XCLK = clk25;
     
    // Address busses
    wire [16:0] capture_addr, frame_addr, bram_addr;
    
    // Pixel data busses
    wire [15:0] rgb_data_16, frame_pixel, bram_data;
    
    // Write enables
    wire capture_wren, frame_bram_wren;
    
    // I2C Config
    wire  config_finished;  
    
    // Gate writing to downsampled buffer by suspicious object alert. Halt writing when object detected
    assign frame_bram_wren = obj_det_wren & ~obj_det_susp;
    
    // Indicates to object detection that camera is ready
    assign ov7670_config_done = config_finished;
    
    // Power defaults for OV7670
    assign pwdn = 0;
    assign reset = 1;
       
    // Reads immediate frame buffer at a rate determined by the decimation rate
    // to downsample the frame rate.
    // Operates on 100MHz clock. Passes downsampled frame stream to object detection
    frame_downsampler #(
        .FRAME_SIZE(FRAME_SIZE)
    ) frame_downsampler_inst(
        .clk                (aclk),       // 100 MHz input clock
        .resetn             (aresetn), // Active low reset
        
        // OV7670 Camera outputs
        .ov7670_capture_addr(capture_addr),
        .decimation_rate    (decimation_rate),
        .ov7670_vsync       (OV7670_VSYNC),
        
        // BRAM interface
        .tdata_addr         (frame_addr), // Frame Buffer read address
        .tdata              (frame_pixel),     // Frame Buffer read data
        
        // Outputs to object detection
        .obj_det_addr       (obj_det_addr),
        .obj_det_pixel      (obj_det_pixel),
        .obj_det_wren       (obj_det_wren)
    );
    
    // OV7670 Camera Decoder
    ov7670_capture capture(
        .pclk  (OV7670_PCLK),
        .vsync (OV7670_VSYNC),
        .href  (OV7670_HREF),
        .d     (OV7670_D),
        .addr  (capture_addr),
        .dout (rgb_data_16),
        .we   (capture_wren)
      );
    
    // Immediate frame buffer to store frames from camera
    // dual-port, 16 bits wide, 76800 deep 
    blk_mem_gen_0 u_frame_buffer (
        // 25 MHz write port
        .clka(clk25),    
        .wea(capture_wren),     
        .addra(capture_addr),  
        .dina(rgb_data_16),  
        // 100 MHz read port  
        .clkb(aclk),    
        .enb(obj_det_wren),
        .addrb(frame_addr),  
        .doutb(frame_pixel) 
    );
    
    // BRAM to store downsampled frames
    blk_mem_gen_0 downsampled_frame_buffer (
        // 100 MHz write port
        .clka(aclk),    
        .wea(frame_bram_wren),     
        .addra(obj_det_addr),  
        .dina(obj_det_pixel),    
        // 100 MHz read port
        .clkb(aclk),   
        .enb(1'b1),
        .addrb(bram_addr),  
        .doutb(bram_data) 
    );
    
    I2C_AV_Config IIC(
        .iCLK       (clk25),    
        .iRST_N     (aresetn),    
        .Config_Done(config_finished),
        .I2C_SDAT   (OV7670_SIOD),    
        .I2C_SCLK   (OV7670_SIOC),
        .LUT_INDEX  (),
        .I2C_RDATA  ()
    ); 
        
    S00_AXI S00_AXI_inst (
        .bram_addr(bram_addr), // bram address
        .bram_data(bram_data), // data_value
        .S_AXI_ACLK(aclk),
        .S_AXI_ARESETN(aresetn),
        .S_AXI_AWADDR(S_AXI_AWADDR),
        //.S_AXI_AWPROT(s00_axi_awprot),
        .S_AXI_AWVALID(S_AXI_AWVALID),
        .S_AXI_AWREADY(S_AXI_AWREADY),
        .S_AXI_WDATA(S_AXI_WDATA),
        .S_AXI_WSTRB(S_AXI_WSTRB),
        .S_AXI_WVALID(S_AXI_WVALID),
        .S_AXI_WREADY(S_AXI_WREADY),
        .S_AXI_BRESP(S_AXI_BRESP),
        .S_AXI_BVALID(S_AXI_BVALID),
        .S_AXI_BREADY(S_AXI_BREADY),
        .S_AXI_ARADDR(S_AXI_ARADDR),
        //.S_AXI_ARPROT(s00_axi_arprot),
        .S_AXI_ARVALID(S_AXI_ARVALID),
        .S_AXI_ARREADY(S_AXI_ARREADY),
        .S_AXI_RDATA(S_AXI_RDATA),
        .S_AXI_RRESP(S_AXI_RRESP),
        .S_AXI_RVALID(S_AXI_RVALID),
        .S_AXI_RREADY(S_AXI_RREADY)
    );

endmodule
