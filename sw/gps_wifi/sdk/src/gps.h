/*
 * gps.h
 *
 *  Created on: Mar 14, 2019
 *      Author: RLK
 */

#ifndef SRC_GPS_H_
#define SRC_GPS_H_

#include "PmodGPS.h"
#include "xil_cache.h"
#include "xparameters.h"


/************ Function Prototypes ************/

void gps_DemoInitialize();

void gps_DemoRun();

int SetupInterruptSystem(PmodGPS *InstancePtr, u32 interruptDeviceID,
      u32 interruptID);

void EnableCaches();

void DisableCaches();

int init_gps(void);


/************ Global Variables ************/

extern PmodGPS GPS;
//extern INTC intc;


#endif /* SRC_GPS_H_ */
