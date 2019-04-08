`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/09/2019 10:08:52 PM
// Design Name: 
// Module Name: obj_det_control
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


module obj_det_control(
    input 		      clk,
    input 		      resetn,
    input 			  i2c_config_done,
    input 	   [16:0] capture_addr,
    input             capture_wren, // Connect to we output of ov7670_capture
    input      [9:0]  frame_count,  // Connect to frame_count output of datapath
    input 		      start_capture,
    output reg 		  resetn_datapath,
    output reg [16:0] ref_addr,
    output reg        ref_wren,
    output reg        ref_bram_enable,
    output reg [16:0] diff_addr,
    output reg        diff_wren,
    output reg 		  diff_bram_enable,
    output  		  init_done,
    output reg 		  frame_start
    );

	parameter FRAME_SIZE = 76800;


	///////////////////////// FSM //////////////////////////// 
	parameter RESET = 3'd0, WAIT_START = 3'b1, SYNC_CAPTURE = 3'd2, CAPTURE_REF = 3'd3, START_FRAME = 3'd4, PROC_FRAME = 3'd5;
	reg [2:0] curr_state, next_state;
	
	// Tells compiler to ignore everything between "synopsys translate_*"
	// synopsys translate_off
    reg [13*8-1:0] curr_state_ASCII; // one char need 8-bit, therefore curr_state_name can contain 12 chars
    
    always @(curr_state) // curr_state is your FSM registers
        begin
            case(curr_state)
                RESET:          curr_state_ASCII = "RESET"; 
                WAIT_START:     curr_state_ASCII = "WAIT_START"; 
                SYNC_CAPTURE:   curr_state_ASCII = "SYNC_CAPTURE";
                CAPTURE_REF:	curr_state_ASCII = "CAPTURE_REF";
                START_FRAME:    curr_state_ASCII = "START_FRAME";
                PROC_FRAME :	curr_state_ASCII = "PROC_FRAME";
            endcase
        end
    // synopsys translate_on


    // Change states, allow for asynchronous reset
    always@(posedge clk or negedge resetn) begin
		if (!resetn) curr_state <= RESET;
		else 		 curr_state <= next_state;
	end



	// Init_done controlled by control logic
	reg init_done_i;

	// // Level init_done outputted to Datapath and monitored by control path
	wire init_done_o;

	// // Catch pulse and output high
	pulse_detector init_done_pulse_detector(.clk(clk), .resetn(resetn), .pulse_in(init_done_i), .level_out(init_done_o));
	assign init_done = init_done_o; // Output pulse_detector output to datapath

	// State transition and output logic
	always@(*) begin

		// Default outputs
		init_done_i		 = 0;
		ref_wren  		 = 0;
		ref_bram_enable  = 1; // Both BRAMS are enabled by default
		diff_wren 		 = 0;
		diff_bram_enable = 1; // Both BRAMS are enabled by default
		frame_start 	 = 0;

		// Active-low reset, set high
		resetn_datapath   = 1;

		// By default, set address busses to be 0
		ref_addr 		 = 0;
		diff_addr		 = 0;

		case(curr_state)
			RESET: begin
				if (!resetn || !i2c_config_done) begin
					resetn_datapath  = 0;
					next_state       = RESET;
				end else begin
					next_state       = WAIT_START; // capture_addr should be 0 at this point
				end
			end
			WAIT_START: begin

				resetn_datapath  = 0; // Keep datapath in reset

				if (!start_capture) begin // Wait until receive start from top modules
					ref_bram_enable = 0;   // Disable BRAM's to be safe
					diff_bram_enable = 0;

					next_state = WAIT_START;
				end else begin
					next_state = SYNC_CAPTURE;
				end
			end
			SYNC_CAPTURE: begin 
				if (capture_addr != 17'd0 || ~capture_wren) begin // Wait until current frame elapses before starting capture OR downsampler stops dropping frames
					next_state = SYNC_CAPTURE;
				end else begin
					if (!init_done_o) begin // Check level init_done 
						next_state = CAPTURE_REF;
					end else begin
						next_state = START_FRAME; // Go through this state to assert frame_start
					end
				end
			end
			CAPTURE_REF: begin // Capture reference frame and write pixels to reference bram
				if ((capture_addr < (FRAME_SIZE - 1))) begin 

					// Enable writing to reference buffer
					ref_wren         = capture_wren;
					ref_bram_enable  = capture_wren;
					ref_addr         = capture_addr;

					// Also use this time to initialize difference buffer
					diff_wren        = capture_wren;
					diff_bram_enable = capture_wren;
					diff_addr        = capture_addr;

					next_state       = CAPTURE_REF;
				end else begin // Finish capturing frame. Initialization finished			
					// Set done signal
					init_done_i        = 1; // Pulse init_done, should be captured by pulse_detector causing init_done_o to go high

					next_state       = SYNC_CAPTURE; // Sync first
				end
			end
			START_FRAME: begin // Spend one cycle here to assert frame_start signal. Datapath will check for successive matches here.
				frame_start          = 1;
				//init_done_i            = 1;
				
				next_state           = PROC_FRAME;
			end
			PROC_FRAME: begin // Capture frame pixels and do parallel comparison to reference frame and previous difference
				//init_done_i            = 1;
				if ((capture_addr < (FRAME_SIZE - 1))) begin 
					// Pass capture_addr to ref_addr to read
					ref_addr         = capture_addr;

					// Write and read difference buffer
					diff_wren        = capture_wren;
					diff_bram_enable = capture_wren;
					diff_addr        = capture_addr;

					next_state       = PROC_FRAME;
				end else begin
					next_state       = SYNC_CAPTURE; 
				end
			end
			default: next_state = RESET;
		endcase
	end
endmodule
