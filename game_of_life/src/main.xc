// COMS20001 - Cellular Automaton Farm - Initial Code Skeleton
// (using the XMOS i2c accelerometer demo code)
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>

#include <platform.h>
#include <xs1.h>

#include "i2c.h"
#include "pgmIO.h"

#include "constants.h"
#include "world.h"

on tile[0]: port p_scl = XS1_PORT_1E;         //interface ports to orientation
on tile[0]: port p_sda = XS1_PORT_1F;

#define FXOS8700EQ_I2C_ADDR 0x1E  //register addresses for orientation
#define FXOS8700EQ_XYZ_DATA_CFG_REG 0x0E
#define FXOS8700EQ_CTRL_REG_1 0x2A
#define FXOS8700EQ_DR_STATUS 0x0
#define FXOS8700EQ_OUT_X_MSB 0x1
#define FXOS8700EQ_OUT_X_LSB 0x2
#define FXOS8700EQ_OUT_Y_MSB 0x3
#define FXOS8700EQ_OUT_Y_LSB 0x4
#define FXOS8700EQ_OUT_Z_MSB 0x5
#define FXOS8700EQ_OUT_Z_LSB 0x6

/////////////////////////////////////////////////////////////////////////////////////////
//
// Read Image from PGM file from path infname[] to channel c_out
//
/////////////////////////////////////////////////////////////////////////////////////////
void DataInStream(char infname[], chanend c_out) {
  int res;
  uint8_t line[IMWD];
  printf("DataInStream: Start...\n");

  // Open PGM file
  res = _openinpgm(infname, IMWD, IMHT);
  if (res) {
    printf("DataInStream: Error openening %s\n.", infname);
    return;
  }

  // Read image line-by-line and send byte by byte to channel c_out
  for (int y = 0; y < IMHT; y++) {
    _readinline(line, IMWD);
    for (int x = 0; x < IMWD; x++) {
      c_out <: line[x];
      // printf( "-%4.1d ", line[ x ] ); //show image values
    }
    // printf( "\n" );
  }

  // Close PGM image file
  _closeinpgm();
  // printf( "DataInStream: Done...\n" );
  return;
}

/////////////////////////////////////////////////////////////////////////////////////////
//
// Start your implementation by changing this function to implement the game of life
// by farming out parts of the image to worker threads who implement it...
// Currently the function just inverts the image
//
/////////////////////////////////////////////////////////////////////////////////////////
void distributor(chanend c_in, chanend c_out, chanend fromAcc) {
  uint8_t val;
  world_t world = blank_w(new_ix(IMHT, IMWD));

  // Starting up and wait for tilting of the xCore-200 Explorer
  printf("ProcessImage: Start, size = %dx%d\n", IMHT, IMWD);
  printf("Waiting for Board Tilt...\n");
  fromAcc :> int value;

  // Read in and do something with your image values..
  // This just inverts every pixel, but you should
  // change the image according to the "Game of Life"
  printf("Processing...\n");
  for (int y = 0; y < IMHT; y++) {  // go through all lines
    for (int x = 0; x < IMWD; x++) {  // go through each pixel per line
      c_in :> val;  // read the pixel value
      world = set_w(world, new_ix(y, x), val);
    }
  }

  world = flip_w(world);
  printworld_w(world);
  for (int i = 0; i < STEP; i++) {
    for (int y = 0; y < IMHT; y++) {
      for (int x = 0; x < IMWD; x++) {
        ix_t ix = new_ix(y, x);
        world = set_w(world, ix, step_w(world, ix));
      }
    }
    world = flip_w(world);
    printworld_w(world);
  }

  for (int y = 0; y < IMHT; y++) {
    for (int x = 0; x < IMWD; x++) {
      if (isalive_w(world, new_ix(y, x))) {
        val = ~0;
      } else {
        val = 0;
      }
      c_out <: val;
    }
  }

  printf("\nOne processing round completed...\n");
}

/////////////////////////////////////////////////////////////////////////////////////////
//
// Write pixel stream from channel c_in to PGM image file
//
/////////////////////////////////////////////////////////////////////////////////////////
void DataOutStream(char outfname[], chanend c_in) {
  int res;
  uint8_t line[IMWD];

  // Open PGM file
  printf("DataOutStream: Start...\n");
  res = _openoutpgm(outfname, IMWD, IMHT);
  if (res) {
    printf("DataOutStream: Error opening %s\n.", outfname);
    return;
  }

  // Compile each line of the image and write the image line-by-line
  for (int y = 0; y < IMHT; y++) {
    for (int x = 0; x < IMWD; x++) {
      c_in :> line[x];
      // printf( "-%4.1d ", line[ x ] ); //show image values
    }
    _writeoutline(line, IMWD);
    // printf( "DataOutStream: Line written...\n" );
  }

  // Close the PGM image
  _closeoutpgm();
  printf("DataOutStream: Done...\n");
  return;
}

/////////////////////////////////////////////////////////////////////////////////////////
//
// Initialise and  read orientation, send first tilt event to channel
//
/////////////////////////////////////////////////////////////////////////////////////////
void orientation(client interface i2c_master_if i2c, chanend toDist) {
  i2c_regop_res_t result;
  char status_data = 0;
  int tilted = 0;

  // Configure FXOS8700EQ
  result =
      i2c.write_reg(FXOS8700EQ_I2C_ADDR, FXOS8700EQ_XYZ_DATA_CFG_REG, 0x01);
  if (result != I2C_REGOP_SUCCESS) {
    printf("I2C write reg failed\n");
  }

  // Enable FXOS8700EQ
  result = i2c.write_reg(FXOS8700EQ_I2C_ADDR, FXOS8700EQ_CTRL_REG_1, 0x01);
  if (result != I2C_REGOP_SUCCESS) {
    printf("I2C write reg failed\n");
  }

  // Probe the orientation x-axis forever
  while (1) {
    // check until new orientation data is available
    do {
      status_data =
          i2c.read_reg(FXOS8700EQ_I2C_ADDR, FXOS8700EQ_DR_STATUS, result);
    } while (!status_data & 0x08);

    // get new x-axis tilt value
    int x = read_acceleration(i2c, FXOS8700EQ_OUT_X_MSB);

    // send signal to distributor after first tilt
    if (!tilted) {
      if (x > 30) {
        tilted = 1 - tilted;
        toDist <: 1;
      }
    }
  }
}
/////////////////////////////////////////////////////////////////////////////////////////
//
// Orchestrate concurrent system and start up all threads
//
/////////////////////////////////////////////////////////////////////////////////////////
int main(void) {
  i2c_master_if i2c[1];               //interface to orientation

  //char infname[] = "test.pgm";      //put your input image path here
  //char outfname[] = "testout.pgm";  //put your output image path here
  chan c_inIO, c_outIO, c_control;    //extend your channel definitions here

  par {
    on tile[0]: i2c_master(i2c, 1, p_scl, p_sda, 10);     //server thread providing orientation data
    on tile[0]: orientation(i2c[0], c_control);            //client thread reading orientation data
    on tile[0]: DataInStream(FILENAME_IN, c_inIO);         //thread to read in a PGM image
    on tile[0]: DataOutStream(FILENAME_OUT, c_outIO);    //thread to write out a PGM image
    on tile[1]: distributor(c_inIO, c_outIO, c_control);  //thread to coordinate work on image
  }

  return 0;
}
