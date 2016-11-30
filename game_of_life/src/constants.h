#ifndef _CONSTANTS_H_
#define _CONSTANTS_H_

#include <stdint.h>

#define FILENAME_IN "512x512.pgm"
#define FILENAME_OUT "testout.pgm"

// image height and width
#define IMHT 512
#define IMWD 512

// image to world offset
#define OFHT 0
#define OFWD 0

// world height
#define WDHT IMHT//102/ + 256 + 8 + 4
#define WDWD IMWD//1024 + 256 + 8 + 4

#define ITERATIONS 100//UINTMAX_MAX

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

#endif
