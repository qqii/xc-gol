#ifndef _CONSTANTS_H_
#define _CONSTANTS_H_

#define FILENAME_IN "test.pgm"
#define FILENAME_OUT "testout.pgm"

// image height and width
#define IMHT 16
#define IMWD 16

// number of iterations to run
#define STEP 1

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

#endif
