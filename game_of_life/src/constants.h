#ifndef _CONSTANTS_H_
#define _CONSTANTS_H_

#include <stdint.h>

#define FILENAME_IN "lwss.pgm"
#define FILENAME_OUT "testout.pgm"

#define VERBOSE

// image height and width, has to match FILENAME_IN
#define IMHT 16
#define IMWD 16

// world height and with, doesn't have to match image
// larger worlds will cause the image to be placed from OFHT, OFWD
#define WDHT IMHT//102/ + 256 + 8 + 4
#define WDWD IMWD//1024 + 256 + 8 + 4

// image to world offset
#define OFHT 0
#define OFWD 0

// number of workers
#define WCOUNT 7

// #define ITERATIONS UINTMAX_MAX // basically forever
#define ITERATIONS 1024

// UNTILT_THRESHOLD < TILT_THRESHOLD to avoid it detecting multiple times
#define TILT_THRESHOLD   30
#define UNTILT_THRESHOLD 10

#define FXOS8700EQ_I2C_ADDR         0x1E  //register addresses for orientation
#define FXOS8700EQ_XYZ_DATA_CFG_REG 0x0E
#define FXOS8700EQ_CTRL_REG_1       0x2A
#define FXOS8700EQ_DR_STATUS        0x0
#define FXOS8700EQ_OUT_X_MSB        0x1
#define FXOS8700EQ_OUT_X_LSB        0x2
#define FXOS8700EQ_OUT_Y_MSB        0x3
#define FXOS8700EQ_OUT_Y_LSB        0x4
#define FXOS8700EQ_OUT_Z_MSB        0x5
#define FXOS8700EQ_OUT_Z_LSB        0x6

// constants for LEDs
#define D0   0b0000
#define D2   0b0001
#define D1_b 0b0010
#define D1_g 0b0100
#define D1_r 0b1000

// constants for buttons
#define SW1 14
#define SW2 13

// comment out on linux
#define _WIN32

#endif
