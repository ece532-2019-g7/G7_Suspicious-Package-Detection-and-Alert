# Misplaced / Suspicious Package Detection and Alert System

Safety is a major concern for public events, venues and transit. Many surveillance cameras out there today capture video but do not identify suspicious packages nor issue alerts. To identify suspicious packages, public services such as GO Transit and TTC rely on public announcements encouraging individuals to report suspicious packages directly to an employee. We believe that the current method is neither ideal nor efficient.

Our system monitors public areas and flags objects that have remained stationary for 20 seconds. A remote user can request status updates from the detection system over WiFi. These updates include the following information:
- Status (i.e. whether an object has been detected)
- GPS Coordinates

GPS coordinates are included in the status message to facilitate the use of the system in temporary venues, thus eliminating the need for system operators to manually track the locations of each detector.

## Building and Running the Detection System

> **This project is known to build with Xilinx Vivado 2017.4**

Follow these steps to set up and run the detection system:

1. Clone this repository
2. Open the Vivado project and run through to Generate Bitstream
3. Export hardware to SDK
    > Make sure you export the bitstream
4. Launch SDK
5. Create a new Application Project
6. Include the software source files
7. Set the SSID and passphrase of your WiFi access point
8. Connect the PMODs to the Nexys 4 DDR board

    | PMOD   | Port           |
    | :----- | :------------- |
    | Camera | `JA` & `JB`    |
    | WiFi   | `JXADC`        |
    | GPS    | `JC` (Top Row) |

9. Connect the board to your computer using the USB cable and power on the board
10. Program the board
11. Launch the application on the MicroBlaze using SDK's Run Configuration manager

## Using the Detection System

_Before_ launching the on-board software, point the camera at the area you wish to monitor.

Shortly after the application is launched on the board, a reference image used to detect foreign objects is captured and stored in memory. In the current release, the only way to capture a new reference is to re-program the board.

## Authors

Robert Kolaja, Albert Le, & Tony Wang

## Acknowledgments

We used the following components from the [Digilent Vivado Library](https://github.com/Digilent/vivado-library) to build this project:
- PmodWIFI v1.0
- PmodGPS v1.1
