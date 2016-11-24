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
#include "io.h"

on tile[0]: port p_scl        = XS1_PORT_1E; //interface ports to orientation
on tile[0]: port p_sda        = XS1_PORT_1F;
//  both of these must be on port 0
on tile[0]: in   port p_buttons = XS1_PORT_4E; //port to access xCore-200 buttons
on tile[0]: out  port p_leds    = XS1_PORT_4F; //port to access xCore-200 LEDs

// Read Image from PGM file from path infname[] to channel c_out
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

// Start your implementation by changing this function to implement the game of life
// by farming out parts of the image to worker threads who implement it...
// Currently the function just inverts the image
void distributor(io_i client c, chanend c_in, chanend c_out, chanend c_timing) {
  uint8_t D1 = 0;
  uint8_t val;
  world_t world = test16x16_w();// = blank_w(new_ix(IMHT, IMWD));

  // Starting up and wait for tilting of the xCore-200 Explorer
  printf("ProcessImage: Start, size = %dx%d\n", IMHT, IMWD);
  printf("Waiting for Board Tilt...\n");
  while (c.getButtons() != SW1) {

  }
  c.setLEDs(D2);

  printf("Processing...\n");
  for (int y = 0; y < IMHT; y++) {  // go through all lines
    for (int x = 0; x < IMWD; x++) {  // go through each pixel per line
      c_in :> val;  // read the pixel value
      world = set_w(world, new_ix(y, x), val);
    }
  }

  printworld_w(flip_w(world));

  c.setLEDs(D1_g);
  world = flip_w(world);
  while (1) {
    for (int y = 0; y < IMHT; y++) {
      for (int x = 0; x < IMWD; x++) {
        ix_t ix = new_ix(y, x);
        world = set_w(world, ix, step_w(world, ix));
      }
    }
    world = flip_w(world);

    if (D1) {
      c.setLEDs(D0);
    } else {
      c.setLEDs(D1_g);
    }
    D1 != D1;

    if (c.getButtons() == SW2) {
      c.setLEDs(D1_b);
      printworld_w(world);
      // for (int y = 0; y < IMHT; y++) {
      //   for (int x = 0; x < IMWD; x++) {
      //     if (isalive_w(world, new_ix(y, x))) {
      //       val = ~0;
      //     } else {
      //       val = 0;
      //     }
      //     c_out <: val;
      //   }
      // }
    } else if (abs(c.getAccelerationX()) > 30 || abs(c.getAccelerationY()) > 30) {
      c.setLEDs(D1_r);
      printworld_w(world);
      while (abs(c.getAccelerationX()) > 30 || abs(c.getAccelerationY()) > 30) {

      }
    }

  }
}


// Write pixel stream from channel c_in to PGM image file
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


// Initialise and  read orientation, send first tilt event to channel
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
    // do {
    //   status_data =
    //       i2c.read_reg(FXOS8700EQ_I2C_ADDR, FXOS8700EQ_DR_STATUS, result);
    // } while (!status_data & 0x08);

    // get new x-axis tilt value
    int x = read_acceleration(i2c, FXOS8700EQ_OUT_X_MSB);

    int y = read_acceleration(i2c, FXOS8700EQ_OUT_Y_MSB);

    int z = read_acceleration(i2c, FXOS8700EQ_OUT_Z_MSB);


    // send signal to distributor after first tilt
    printf("x: %03d, y: %03d, z: %03d\n", x, y, z);
    // if (!tilted) {
    //   if (x > 30) {
    //     tilted = 1 - tilted;
    //     toDist <: 1;
    //   }
    // }
  }
}

// Orchestrate concurrent system and start up all threads
int main(void) {
  i2c_master_if i2c[1];               //interface to orientation
  io_i c;
  chan c_inIO, c_outIO, c_control, c_timing;    //extend your channel definitions here

  par {
    on tile[0]: i2c_master(i2c, 1, p_scl, p_sda, 10);     //server thread providing orientation data
    // on tile[0]: orientation(i2c[0], c_control);            //client thread reading orientation data
    on tile[0]: DataInStream(FILENAME_IN, c_inIO);         //thread to read in a PGM image
    on tile[0]: DataOutStream(FILENAME_OUT, c_outIO);    //thread to write out a PGM image
    on tile[0]: io(i2c[0], p_buttons, p_leds, c);
    on tile[1]: distributor(c, c_inIO, c_outIO, c_timing);  //thread to coordinate work on image
  }

  return 0;
}
