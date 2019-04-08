/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

#include <stdio.h>
#include <string.h>

#include "lwip/err.h"
#include "lwip/tcp.h"
#if defined (__arm__) || defined (__aarch64__)
#include "xil_printf.h"
#endif

volatile unsigned int * downsampler_bram = (unsigned int *)0xC0000000;
volatile unsigned int * obj_det_axi_base_address = (unsigned int *)0x44A40000;

#define FRAME_SIZE 76800
#define FRAME_BUF_SIZE FRAME_SIZE*2
u8 frame_buf[FRAME_BUF_SIZE];

unsigned int STAT1_OFFSET = 1;
unsigned int DETECT_THRES_OFFSET = 2;
unsigned int STATIC_THRES_OFFSET = 3;
unsigned int SUSP_THRES_OFFSET   = 4;

unsigned int dec_rate_offset = 16;
unsigned int bw_thres_offset = 1;
unsigned int start_offset    = 0;

unsigned int object_susp_offset = 17;
unsigned int object_det_offset  = 16;
unsigned int suspicion_offset   = 0;


void set_suspicion_threshold(unsigned int new_thres) {
	// Write to register
	*(obj_det_axi_base_address + SUSP_THRES_OFFSET) = new_thres;
}

unsigned int check_suspicion_alert() {
	return (*(obj_det_axi_base_address + STAT1_OFFSET) >> object_susp_offset) & 0x1;
}

int transfer_data() {
	return 0;
}

void print_app_header()
{
	xil_printf("\n\r\n\r-----lwIP TCP Server ------\n\r");
}

err_t recv_callback(void *arg, struct tcp_pcb *tpcb,
                               struct pbuf *p, err_t err)
{

	/*int alert = 0;
	while (1) {
		alert = check_suspicion_alert();
		if(alert){
			break;
	   }
	}*/

	for (int i = 0; i < FRAME_SIZE; i++){
	   	*downsampler_bram = i;

	   	int pixel32 = *(downsampler_bram+1);
	   	char pixel = pixel32 & 0xFF;
	   	frame_buf[i*2+1] = pixel;

	   	pixel = (pixel32 >> 8) & 0xFF;
	   	frame_buf[i*2] = pixel;
	}

	   unsigned int bytes_sent = 0;

	   while (bytes_sent < 200000){
		   if (tcp_sndbuf(tpcb)) {
			   err = tcp_write(tpcb, frame_buf+bytes_sent, 10000, 1);
		   } else
			   xil_printf("no space in tcp_sndbuf\n\r");

		   bytes_sent += 10000;
	   }

	return ERR_OK;
}

err_t accept_callback(void *arg, struct tcp_pcb *newpcb, err_t err)
{
	static int connection = 1;

	/* set the receive callback for this connection */
	tcp_recv(newpcb, recv_callback);

	/* just use an integer number indicating the connection id as the
	   callback argument */
	tcp_arg(newpcb, (void*)(UINTPTR)connection);

	/* increment for subsequent accepted connections */
	connection++;

	return ERR_OK;
}


int start_application()
{
	struct tcp_pcb *pcb;
	err_t err;
	unsigned port = 7;

	/* create new TCP PCB structure */
	pcb = tcp_new();
	if (!pcb) {
		xil_printf("Error creating PCB. Out of Memory\n\r");
		return -1;
	}

	/* bind to specified @port */
	err = tcp_bind(pcb, IP_ADDR_ANY, port);
	if (err != ERR_OK) {
		xil_printf("Unable to bind to port %d: err = %d\n\r", port, err);
		return -2;
	}

	/* we do not need any arguments to callback functions */
	tcp_arg(pcb, NULL);

	/* listen for connections */
	pcb = tcp_listen(pcb);
	if (!pcb) {
		xil_printf("Out of memory while tcp_listen\n\r");
		return -3;
	}

	/* specify callback to use for incoming connections */
	tcp_accept(pcb, accept_callback);

	xil_printf("TCP echo server started @ port %d\n\r", port);

	return 0;
}
