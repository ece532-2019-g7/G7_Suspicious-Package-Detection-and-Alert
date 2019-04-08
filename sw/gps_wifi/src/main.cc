/******************************************************************************/
/*                                                                            */
/* TCPEchoServer -- A DEWFcK TCP Server application to  demonstrate how to    */
/*                  use the TcpServer Class. This can be used in conjunction  */
/*                  with TCPEchoClient.                                       */
/*                                                                            */
/******************************************************************************/
/* Author: Keith Vogel                                                        */
/* Copyright 2014, Digilent Inc.                                              */
/******************************************************************************/
/*
 *
 * Copyright (c) 2013-2014, Digilent <www.digilentinc.com>
 * Contact Digilent for the latest version.
 *
 * This program is free software; distributed under the terms of
 * BSD 3-clause license ("Revised BSD License", "New BSD License", or "Modified BSD License")
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * 1.    Redistributions of source code must retain the above copyright notice, this
 *        list of conditions and the following disclaimer.
 * 2.    Redistributions in binary form must reproduce the above copyright notice,
 *        this list of conditions and the following disclaimer in the documentation
 *        and/or other materials provided with the distribution.
 * 3.    Neither the name(s) of the above-listed copyright holder(s) nor the names
 *        of its contributors may be used to endorse or promote products derived
 *        from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */
/******************************************************************************/
/* Revision History:                                                          */
/*                                                                            */
/*    05/14/2014(KeithV):   Created                                           */
/*    08/09/2016(TommyK):   Modified to use Microblaze/Zynq                   */
/*    12/02/2017(atangzwj): Validated for Vivado 2016.4                       */
/*    01/20/2018(atangzwj): Validated for Vivado 2017.4                       */
/*                                                                            */
/******************************************************************************/

extern "C"
{
#include "gps.h"
}

#include "PmodWIFI.h"
#include "xil_cache.h"
#include "xparameters.h"

#ifdef __MICROBLAZE__
#define PMODWIFI_VEC_ID XPAR_INTC_0_PMODWIFI_0_VEC_ID
#else
#define PMODWIFI_VEC_ID XPAR_FABRIC_PMODWIFI_0_WF_INTERRUPT_INTR
#endif

/************************************************************************/
/*                                                                      */
/*              SET THESE VALUES FOR YOUR NETWORK                       */
/*                                                                      */
/************************************************************************/

IPv4 ipServer = {0,0,0,0}; // {0,0,0,0} for DHCP

unsigned short portServer = DEIPcK::iPersonalPorts44 + 300; // Port 44300

// Specify the SSID
//const char *szSsid = "SM-G930W88313";
const char *szSsid = "SM-G930W88313";

// Select 1 for the security you want, or none for no security
#define USE_WPA2_PASSPHRASE
//#define USE_WPA2_KEY
//#define USE_WEP40
//#define USE_WEP104
//#define USE_WF_CONFIG_H

// Modify the security key to what you have.
#if defined(USE_WPA2_PASSPHRASE)

//   const char *szPassPhrase = "rsqd5920";
const char *szPassPhrase = "rsqd5920";
   #define WiFiConnectMacro() deIPcK.wfConnect(szSsid, szPassPhrase, &status)

#elif defined(USE_WPA2_KEY)

   WPA2KEY key = { 0x27, 0x2C, 0x89, 0xCC, 0xE9, 0x56, 0x31, 0x1E,
                   0x3B, 0xAD, 0x79, 0xF7, 0x1D, 0xC4, 0xB9, 0x05,
                   0x7A, 0x34, 0x4C, 0x3E, 0xB5, 0xFA, 0x38, 0xC2,
                   0x0F, 0x0A, 0xB0, 0x90, 0xDC, 0x62, 0xAD, 0x58 };
   #define WiFiConnectMacro() deIPcK.wfConnect(szSsid, key, &status)

#elif defined(USE_WEP40)

   const int iWEPKey = 0;
   DEWFcK::WEP40KEY keySet = { 0xBE, 0xC9, 0x58, 0x06, 0x97,   // Key 0
                               0x00, 0x00, 0x00, 0x00, 0x00,   // Key 1
                               0x00, 0x00, 0x00, 0x00, 0x00,   // Key 2
                               0x00, 0x00, 0x00, 0x00, 0x00 }; // Key 3
   #define WiFiConnectMacro() deIPcK.wfConnect(szSsid, keySet, iWEPKey, &status)

#elif defined(USE_WEP104)

   const int iWEPKey = 0;
   DEWFcK::WEP104KEY keySet = { 0x3E, 0xCD, 0x30, 0xB2, 0x55, 0x2D, 0x3C, 0x50, 0x52, 0x71, 0xE8, 0x83, 0x91,   // Key 0
                                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,   // Key 1
                                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,   // Key 2
                                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }; // Key 3
   #define WiFiConnectMacro() deIPcK.wfConnect(szSsid, keySet, iWEPKey, &status)

#elif defined(USE_WF_CONFIG_H)

   #define WiFiConnectMacro() deIPcK.wfConnect(0, &status)

#else // No security - OPEN

   #define WiFiConnectMacro() deIPcK.wfConnect(szSsid, &status)

#endif

//******************************************************************************************
//******************************************************************************************
//***************************** END OF CONFIGURATION ***************************************
//******************************************************************************************
//******************************************************************************************

typedef enum
{
   NONE = 0,
   CONNECT,
   LISTEN,
   ISLISTENING,
   WAITISLISTENING,
   AVAILABLECLIENT,
   ACCEPTCLIENT,
   READ,
   WRITE,
   CLOSE,
   EXIT,
   DONE
} STATE;

STATE state = CONNECT;

unsigned tStart = 0;
unsigned tWait = 5000;
unsigned int send_gps = 0;

TCPServer tcpServer;
#define cTcpClients 2
TCPSocket rgTcpClient[cTcpClients];

TCPSocket *ptcpClient = NULL;

u8 rgbRead[1024];
char * tmp;
int cbRead = 0;
int count = 0;

IPSTATUS status;

void DemoInitialize();
void DemoRun();

volatile unsigned int * downsampler_bram = (unsigned *)XPAR_OV7670_TOP_0_BASEADDR;//(unsigned int *)0xC0000000;

#define FRAME_SIZE 76800
#define FRAME_BUF_SIZE FRAME_SIZE*2
u8 frame_buf[FRAME_BUF_SIZE];

unsigned int * obj_det_axi_base_addr = (unsigned *)XPAR_OBJ_DET_AXI_TOP_0_BASEADDR;//(unsigned int *)0x44A00000;

unsigned int CONFIG1_OFFSET = 0;
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


void start_object_detection() {
	int curr_config = *(obj_det_axi_base_addr + CONFIG1_OFFSET);

	// Set LSB to 1
	int start_config = (curr_config & 0xFFFFFFFE) | 0x1;

	// Write to register
	*(obj_det_axi_base_addr + CONFIG1_OFFSET) = start_config;
	xil_printf("Starting detection\n");
}

void set_suspicion_threshold(unsigned int new_thres) {
	// Write to register
	*(obj_det_axi_base_addr + SUSP_THRES_OFFSET) = new_thres;
}

unsigned int check_suspicion_alert() {
	return (*(obj_det_axi_base_addr + STAT1_OFFSET) >> object_susp_offset) & 0x1;
}


int main(void) {

	//xil_printf("Hello World\n");
   Xil_ICacheEnable();
   Xil_DCacheEnable();

   /*for (int i = 0; i < FRAME_SIZE; i++){
   	*downsampler_bram = i;
   	int pixel32 = *(downsampler_bram+1);
   	//xil_printf("pixel32 0x%x\r\n", pixel32);
   	char pixel = pixel32 & 0xFF;
   	frame_buf[i*2+1] = pixel;
   	pixel = (pixel32 >> 8) & 0xFF;
   	frame_buf[i*2] = pixel;
   	//xil_printf("0x%x 0x%x\n", frame_buf[i*2], frame_buf[i*2+1]);
   }
   xil_printf("0x%x\n", frame_buf[7550]);
   return 0;*/

   xil_printf("TCP Test Echo Server\r\nConnecting...\r\n");

   DemoInitialize();
   gps_DemoInitialize();
   DemoRun();
   return 0;
}

void DemoInitialize() {
   setPmodWifiAddresses(
      XPAR_PMODWIFI_0_AXI_LITE_SPI_BASEADDR,
      XPAR_PMODWIFI_0_AXI_LITE_WFGPIO_BASEADDR,
      XPAR_PMODWIFI_0_AXI_LITE_WFCS_BASEADDR,
      XPAR_PMODWIFI_0_S_AXI_TIMER_BASEADDR
   );
   setPmodWifiIntVector(PMODWIFI_VEC_ID);


   int c = 0;
   while (c < 10000000) {
	   c++;
   }
   start_object_detection();

}

void DemoRun() {
	int saw_alert = 0;
	int alert = 0;
   while (1) {
	   //if(!alert)
	   //{
		alert = check_suspicion_alert();
		if (alert) {
			saw_alert = 1;
//			xil_printf("Suspicious object detected\n");
		}
	   //}


      switch (state) {
      case CONNECT:
         if (WiFiConnectMacro()) {
            xil_printf("Connection Created\r\n");
            deIPcK.begin(ipServer);
            state = LISTEN;
         } else if (IsIPStatusAnError(status)) {
            xil_printf("Unable to make connection, status: 0x%X\r\n", status);
            state = CLOSE;
         }
         break;

      // Say to listen on the port
      case LISTEN:
         if (deIPcK.tcpStartListening(portServer, tcpServer)) {
            for (int i = 0; i < cTcpClients; i++) {
               tcpServer.addSocket(rgTcpClient[i]);
            }
         }
         state = ISLISTENING;
         break;

      case ISLISTENING:
         count = tcpServer.isListening();

         if (count > 0) {
            deIPcK.getMyIP(ipServer);
            xil_printf("Server started on %d.%d.%d.%d:%d\r\n",
               ipServer.u8[0],
               ipServer.u8[1],
               ipServer.u8[2],
               ipServer.u8[3],
               portServer
            );
            xil_printf("%d sockets listening on port: %d\r\n", count,
                  portServer);
            state = AVAILABLECLIENT;
         } else {
            xil_printf("%d sockets listening on port: %d\r\n", count,
                  portServer);
            state = WAITISLISTENING;
         }
         break;

      case WAITISLISTENING:
         if (tcpServer.isListening() > 0) {
            state = ISLISTENING;
         }
         break;

      // Wait for a connection
      case AVAILABLECLIENT:
         if ((count = tcpServer.availableClients()) > 0) {
            xil_printf("Got %d clients pending\r\n", count);
            state = ACCEPTCLIENT;
         }
         break;

      // Accept the connection
      case ACCEPTCLIENT:

         // Accept the client
         if ((ptcpClient = tcpServer.acceptClient()) != NULL
               && ptcpClient->isConnected()) {
            xil_printf("Got a Connection\r\n");
            state = WRITE;
            tStart = (unsigned) SYSGetMilliSecond();
         }

         // This probably won't happen unless the connection is dropped
         // if it is, just release our socket and go back to listening
         else {
            state = CLOSE;
         }
         break;

      // Wait for the read, but if too much time elapses (5 seconds)
      // we will just close the tcpClient and go back to listening
      /*case READ:
         // See if we got anything to read
         if ((cbRead = ptcpClient->available()) > 0) {
            cbRead = cbRead < (int) sizeof(rgbRead) ? cbRead : sizeof(rgbRead);
            cbRead = ptcpClient->readStream(rgbRead, cbRead);
            xil_printf("Got %d bytes\r\n", cbRead);
            state = WRITE;
         }
         // If connection was closed by the user
         else if (!ptcpClient->isConnected()) {
            state = CLOSE;
         }
         break;*/

      // Echo back the string
      case WRITE:

    	 send_gps = 0;
         if (ptcpClient->isConnected()) {

        	 if(alert)//saw_alert
        	 {
        		 saw_alert = 0;

            xil_printf("Suspicious Object Detected!\r\n");
            strcpy((char *)rgbRead, "Suspicious Object Detected!\n");

            int num_satellites;
                	  GPS_getData(&GPS);

            		  while(!GPS.ping)
            		  {
            			  xil_printf("WAITING FOR GPS\n");
            		  }

            		  if (GPS.ping) {
            			  xil_printf("GPS.ping\n");
            			   GPS_formatSentence(&GPS);
            			   //itoa(GPS_getNumSats(&GPS), (char *)rgbRead, 10);
            			   cbRead = strlen((char *)rgbRead);
            			   if (GPS_isFixed(&GPS)) {
            				  itoa(100, tmp, 10);
            				  //tmp = GPS_getLatitude(&GPS);
            				  strcat((char *)rgbRead, "Latitude: ");
            				  strcat((char *)rgbRead, tmp);
            				  strcat((char *)rgbRead, "\n");
            				  xil_printf("Latitude: %s\n\r", tmp);
            				  //tmp = GPS_getLongitude(&GPS);
            				  strcat((char *)rgbRead, "Longitude: ");
            				  strcat((char *)rgbRead, tmp);
            				  strcat((char *)rgbRead, "\n");
            				  xil_printf("Longitude: %s\n\r", tmp);
            				  //tmp = GPS_getAltitudeString(&GPS);
            				  strcat((char *)rgbRead, "Altitude: ");
            				  strcat((char *)rgbRead, tmp);
            				  strcat((char *)rgbRead, "\n");
            				  xil_printf("Altitude: %s\n\r", tmp);
            				  strcat((char *)rgbRead, "Number of Satellites: ");
            				  num_satellites = GPS_getNumSats(&GPS);
            				  itoa(num_satellites, tmp, 10);
            				  strcat((char *)rgbRead, tmp);
            				  xil_printf("Number of Satellites: %s\n\n\r", tmp);
            				  send_gps = 1;
            			   } else {
            				   strcat((char *)rgbRead, "Number of Satellites: ");
            				   num_satellites = GPS_getNumSats(&GPS);
            				   itoa(num_satellites, tmp, 10);
            				   strcat((char *)rgbRead, tmp);
            				  xil_printf("Number of Satellites: %d\n\r", num_satellites);
            			   }
            			   GPS.ping = FALSE;
            		}

            /*for (int i = 0; i < cbRead; i++) {
               xil_printf("%c", (char) rgbRead[i]);
            }
            xil_printf("\r\n");*/

            //ptcpClient->writeStream(rgbRead, cbRead);

            for (int i = 0; i < FRAME_SIZE; i++){
            	*downsampler_bram = i;

            	int pixel32 = *(downsampler_bram+1);
            	//xil_printf("pixel32 0x%x\r\n", pixel32);
            	char pixel = pixel32 & 0xFF;
            	frame_buf[i*2+1] = pixel;

            	pixel = (pixel32 >> 8) & 0xFF;
            	frame_buf[i*2] = pixel;

            	//xil_printf("0x%x 0x%x\n", frame_buf[i*2], frame_buf[i*2+1]);
            }

            //xil_printf("%x\n", frame_buf[7555]);

            xil_printf("Sending image\n");

            //size_t bytes_sent = 0;

            /*while(bytes_sent < FRAME_BUF_SIZE){
            	// only send 7552 bytes for some reason all subsequent sends fails
            	// and sends 0 bytes
            	// sending FRAME_BUF_SIZE size only sends 7552 bytes as well
            	bytes_sent += ptcpClient->writeStream(frame_buf+bytes_sent, 7552);
                xil_printf("%d\n", bytes_sent);
            }*/

            // comment out the while loop above and the below code will successfully
            // send 7552 bytes to client_mb.py running on your local system
            // sends just 7552 bytes

        	 }
        	 else
        	 {
        		 strcpy((char *)rgbRead, "Nothing to Report...");
        	 }


            cbRead = strlen((char *)rgbRead);
            xil_printf("cbRead: %d\n\r", cbRead);
            xil_printf("rgbRead: %s\n\n\r", rgbRead);
            ptcpClient->writeStream(rgbRead, cbRead);

        	if (send_gps) {
				int c = 0;
				while (c < 10000) {
				   c++;
				}
        	}


            /*
            bytes_sent = ptcpClient->writeStream(frame_buf, 5000);
            xil_printf("bytes_sent: %d\n", bytes_sent);
            bytes_sent = ptcpClient->writeStream(frame_buf, 5000);
            xil_printf("bytes_sent: %d\n", bytes_sent);
            */

            state = CLOSE;
            tStart = (unsigned) SYSGetMilliSecond();
         }

         // The connection was closed on us, go back to listening
         else {
            xil_printf("Unable to write back.\r\n");
            state = CLOSE;
         }
         break;

      // Close our tcpClient and go back to listening
      case CLOSE:
         xil_printf("Closing connection\r\n");
         if (ptcpClient)
            ptcpClient->close();
         tcpServer.addSocket(*ptcpClient);
         xil_printf("\r\n");
         state = ISLISTENING;
         break;

      // Something bad happened, just exit out of the program
      case EXIT:
         tcpServer.close();
         xil_printf("Something went wrong, sketch is done.\r\n");
         state = DONE;
         break;

      // Do nothing in the loop
      case DONE:

      default:
         break;
      }

      // Every pass through loop(), keep the stack alive
      DEIPcK::periodicTasks();
   }
}
